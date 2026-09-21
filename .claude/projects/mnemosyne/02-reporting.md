# Reporting: HTTP Client & Reporter API

Two files: `001_HTTP_Client.lua` (transport — a serial POST queue) and `002_Reporter_API.lua` (one thin function per endpoint + run state). The tracker takes **no auth header**; every request is a POST whose JSON body carries a `token` field, stamped on automatically by the client.

## Configuration

`M._cfg()` returns (and lazily creates) `ataxia.settings.reporting`:

| Key | Default | Purpose |
|-----|---------|---------|
| `enabled` | false | Master auto-report toggle (`mnem on/off`) |
| `contemplate` | true | **Legacy; controls nothing on the reporting path.** It once gated `/boons_offered` behind a per-boon `BOON CONTEMPLATE` chain (`_contemplateNext`, dead since v4.7.279 and removed in v4.7.322). Since v4.7.279 offers post without it, and since v4.7.298 the optional `BoonInfo` fields are filled from the local catalogue by `M._enrichOffer` — a mechanism with no relationship to this toggle. Reading it as "does boon detail get sent" gives the wrong answer |
| `url` | `M.DEFAULT_URL` | Tracker base URL |
| `token` | nil | API token (`mnem token <t>`) |
| `debug` | nil | Verbose `M.decho` echoes |
| `mapEnabled` | true | Ripple mini-map toggle (see [04](04-ripple-map.md)) |

- `M.DEFAULT_URL = "http://104.128.56.238:8000"`
- `M._baseUrl()` falls back to the default if `url` is empty and trims trailing slashes.
- `M._hasToken()` — token is a non-empty string.

## Serial POST Queue (`001_HTTP_Client.lua`)

Requests are sent **one at a time** — the next only fires after `sysPostHttpDone`/`sysPostHttpError` for the previous — so endpoint ordering is guaranteed (`/ripple_level` before its monsters/boss/effects; `/boons_offered` before `/boons_selected`).

```
M._enqueue(endpoint, payload, onOk, onError)
  ├─ stamp payload.token
  ├─ table.insert(M._queue, {endpoint, payload, onOk, onError, tries=0})
  └─ M._pump()

M._pump()                    (no-op if M._busy or queue empty)
  ├─ yajl.to_string(payload)  (drop request on encode failure)
  ├─ M._busy = true
  ├─ arm watchdog: tempTimer(REQUEST_TIMEOUT=20s, → M._onTimeout)
  └─ postHTTP(json, baseUrl..endpoint, {Content-Type: application/json})

sysPostHttpDone  → M._onDone(_, url, body)
  ├─ ignore unless M._busy AND _matchesHead(url)
  ├─ parse JSON body (yajl.to_value, pcall-guarded)
  ├─ req.onOk(parsed, body)   (pcall-guarded)
  └─ M._finish()  → drop head, M._busy=false, _pump() next

sysPostHttpError → M._onError(_, err, url)
  ├─ ignore unless M._busy AND _matchesHead(url)
  ├─ retry ONCE if req.tries<1 and endpoint in M._IDEMPOTENT
  └─ else echo failure, M._fireError(req, err), M._finish()

M._onTimeout()               (watchdog fired: dropped response / POST→GET)
  └─ M._fireError(req, "timeout"), M._finish()   (same recovery as an error)
```

**Error recovery.** `M._fireError(req, err)` invokes the request's `onError(err)` callback (pcall-guarded), reached from BOTH the error event and the watchdog — so a failed request can undo optimistic local state. `startRun()` uses this: it sets `run.active = true` optimistically before `/run_start`, and its `onError` resets `run.active = false`, so a `/run_start` that 500s **or** times out doesn't leave the client firing `ripple`/`monsters`/`boss`/`effects`/`boons` at a run the server never created (recovery would otherwise wait for the next `/run_end` or reload's `runExists`).

### Safety features

| Feature | Function | Why |
|---------|----------|-----|
| Endpoint matching | `M._matchesHead(url)` | A done/error event is accepted only if its URL equals the exact endpoint of the queue head — stray/duplicate events or ad-hoc `postHTTP` to the same host can't be misattributed |
| Watchdog | `M._watchdog` timer, `REQUEST_TIMEOUT = 20` | Force-advances a stuck request (e.g. a POST silently redirected to GET, or a dropped response) so the queue never stalls permanently |
| Idempotent-only retry | `M._IDEMPOTENT = { ["/ripple_level"]=true, ["/run_exists"]=true }` | Only endpoints safe to repeat are auto-retried; everything else is left alone to avoid double-posting a run/death/etc. |
| Handler survival | `registerAnonymousEventHandler` for all 4 http events | Handlers survive `uninstallPackage` (same reasoning as `ataxia.updater`); prior handlers are `killAnonymousEventHandler`'d on reload |

### Reading the response (v4.7.298)

Every endpoint answers `OkResponse { ok, message? }` and `_onDone` used to read neither — an HTTP
200 carrying `ok: false` (the server saying the operation did **not** happen) was logged as a
success and never shown. It is now surfaced with the server's own `message`, which is the only
place a refusal reason can come from.

**It surfaces; it does not re-route.** `ok: false` still runs the request's `onOk` rather than
firing the error path, for the same reason the claim-confirmation line warns instead of un-latching
(v4.7.278): we have never observed this server answer `ok: false`, so we do not know which
conditions produce it — and `startRun`'s `onError` undoes the optimistic `run.active`, which would
silently stop all reporting for the rest of the dive on a guess. Promote it to the error path once a
real `ok: false` has been seen and its meaning is known.

### Health check (`mnem test`)

`M.testHealth()` does a plain `getHTTP(baseUrl.."/health", {})`. Separate `sysGetHttpDone`/`sysGetHttpError` handlers (`_onGetDone`/`_onGetError`) match on the `/health` URL and echo the result. GET is used here, not the POST queue.

## Reporter API (`002_Reporter_API.lua`)

Each function guards on `M._hasToken()` and enqueues. Payload shapes:

| Function | Endpoint | Payload (plus auto `token`) | Response used |
|----------|----------|------------------------------|---------------|
| `startRun()` | `POST /run_start` | `{}` | `public_id` → `run.publicId` |
| `runExists()` | `POST /run_exists` | `{}` | `exists`, `ripple` → sync run state |
| `endRun()` | `POST /run_end` | `{}` | — (echo only) |
| `reportRunPause()` | `POST /run_pause` | `{}` | — (v4.7.298) |
| `setRipple(n)` | `POST /ripple_level` | `{ ripple = n }` | — (sets `run.ripple` on OK) |
| `reportMonsters(str)` | `POST /monsters` | `{ monsters = str }` | — |
| `reportBoss(name)` | `POST /boss` | `{ boss = name }` | — |
| `reportEffects(list)` | `POST /effects` | `{ effects = [{name, description}, …] }` | — |
| `reportBoonsOffered(list)` | `POST /boons_offered` | `{ offered = [{name, description?, quote?, rarity?, category?, unlocked_by?, conflicts_with?, num_echoes_possible?, combo_boon?}, …], class?, race?, reroll_count }` | `class`/`race` from `M._charInfo()` (v4.7.220); the seven optional `BoonInfo` fields filled from the local catalogue (six since v4.7.298, `combo_boon` since v4.7.322) and `reroll_count` inferred (v4.7.298) |
| `reportBoonsSelected(names)` | `POST /boons_selected` | `{ selected = [name, …] }` | — |
| `reportBoonReceived(name)` | `POST /boon_received` | `{ boon = {name, description?, …, unlocked_by?, combo_boon?}, class?, race? }` | v4.7.330, the author's own endpoint for a boon we were GIVEN ("use this instead of boons_offered endpoint to send the combo boons that are granted"). **SINGULAR** `/boon_received` and ONE `BoonInfo` — verified against the live `/openapi.json`, 2026-09-21. Sent from the combo-grant path (trigger 095) through `_enrichOffer`, so it carries the recipe (`unlocked_by`) and `combo_boon`. A granted reward is no longer posted to `/boons_selected`: we never selected it |
| `reportDeath(killer)` | `POST /death` | `{ killer = <name or "unknown"> }` | — |

### Notable behaviours

- **The boon DATABASE (v4.7.239/240).** `M.history.boonLibrary` has always learned name +
  description + rarity + maxEchoes from the offer screen. It now also writes its **own file**,
  `<profile>/mnemosyne_boons.lua`: a boon's description is shown **exactly once** (the BOONS
  list is `Boon | Echoes | Rarity` with no description), so the catalogue is irreplaceable, and
  it was sharing a file with run counters and claims that are rewritten constantly. Bundling
  something irreplaceable with something disposable means one bad write loses both.
  Loading **merges** -- same semantics as `_learnBoon`, so an import can only ever ADD and
  re-importing is idempotent. `mnem boondb [filter|export|import]`; the filter matches name AND
  effect text. **294 boons ship as a seed** (`M.BOON_SEED`) (`mnemosyne/010_Boon_Seed.lua`, sourced from
  <https://mediaresachaea.github.io/mnemosyne-boons/> and credited there), merged the same way
  so observed data always wins.
  **The audit method matters more than the data:** five consecutive releases each fixed a
  boon-parsing gap found when an offer screen happened to show an unanticipated shape. Running
  the real parser over all 294 descriptions at once found everything remaining in ONE pass --
  one under-read grant (`Careless Whisperer`, a comma list running on into prose) and three
  missing cost afflictions (timeflux, fulmination, hamstrung). *When a corpus exists, audit
  against it instead of waiting for the next live example.*

- **`/boons_offered` carries `class` and `race` (v4.7.220).** Both are **top-level optional
  strings on `BoonsOfferedRequest`** — not members of `BoonInfo`, which is where the field
  names suggest they would live. Verified against the live schema at
  `http://104.128.56.238:8000/openapi.json`; that endpoint is the way to settle any question
  about this API's shape rather than inferring it from prose. They exist so the offer data can
  be sliced ("does Bard see Songstep more often" is not a question you can ask of a pile of
  undifferentiated offers).

  `M._charInfo()` makes two deliberate choices:
  * **Class is normalised, race is not.** "Earth Lord" and "Earth Lady" are one class wearing a
    gender suffix, and leaving them distinct halves every per-class count. The basher's
    existing `:title():gsub(" Lady", ""):gsub(" Lord", "")` is reused, so the values also match
    what the rest of the system calls a class. Race is passed through as GMCP reports it —
    there is no known distortion to correct, and normalising against an unverified vocabulary
    corrupts data more quietly than leaving it raw.
  * **Omitted, never guessed.** A missing or empty GMCP read sends no key at all. A literal
    `"unknown"` would appear in the queries as its own cohort — worse than a smaller honest
    sample.

  `_reportBoonsOfferedEnriched` posts through `reportBoonsOffered`, so the tagging lands on the
  real path. (It once had a second, contemplate-enriched branch; that chain was removed in
  v4.7.322.) Source path: `gmcp.Char.Status.class` / `gmcp.Char.Status.race` —
  `Char.Status` is pushed on login and on change, NOT every prompt like `Char.Vitals`.
  Note that a dragon reports race `Dragon` with class `<colour> Dragon`, so dragons appear as
  several classes sharing one race; `Undead` is a race, not a modifier.

- **`setRipple(n)` guard.** Skips locally if `n <= run.ripple` (the API errors on a lower ripple and no-ops on equal). `run.ripple` is only advanced inside the success callback.
- **`startRun()` optimism.** Sets `run.active = true` and calls `_resetRun()` *synchronously* before the async POST, so the first wave isn't lost while waiting for the response.
- **Pause / resume (no new `public_id`).** A "beseech that it grow still" pause sets `run.paused` (`onRunPause`, `004_Parsers.lua`) **without** ending the run server-side. The next wade's `onRunStart` then resumes via **`runExists()`** (`/run_exists`) instead of `startRun()`, so no fresh `/run_start` fires and **no new `public_id` is minted** — the resumed run keeps its server-side identity, and `/run_exists` re-syncs `run.active` + `run.ripple`. `run.paused` is cleared unconditionally in `_resetRun()` (hence on any genuine `startRun`/`endRun`) and in `onRunEnd`, so a telemetry-off end can't hijack the next fresh wade into a resume.
- **`endRun()`** flushes any final-wave monsters (`_flushMonsters()`) before enqueuing `/run_end`, then resets locally immediately (the run is over regardless of the response).
- **`reportBoonsOffered` is posted immediately.** `_reportBoonsOfferedEnriched(list)` (`004_Parsers.lua`) records local history and calls `reportBoonsOffered(list)` **right away**, with the `name`+`description` scraped straight off the offer screen — it is **not** gated behind the per-boon `BOON CONTEMPLATE` enrichment chain. (The old design contemplated each boon (~0.5s apiece) to fill `rarity`/`quote`/`num_echoes_possible` *before* posting; that chain competed with the next ripple's captures for the single `_capturing` slot and, on a lost race, stalled and silently dropped the whole `/boons_offered`, and even on success could post after the player had already waded onto the next ripple.)

- **…but the optional fields still go, read from the CATALOGUE (v4.7.298).** `BoonInfo` has eight
  fields and we were sending two. The six missing ones were never missing *data* — the local
  catalogue (`M.history.boonLibrary`) already holds them, learned from the BOONS list, `mnem
  boonfill` and the per-screen trickle — they were simply never joined up. `M._enrichOffer(list)`
  does the join at post time.

  **This is not a revival of the contemplate chain, and the distinction is the whole design.**
  Every hazard that got the chain removed in v4.7.279 belongs to the **fetch** — a command per
  boon, the shared `_capturing` slot, a stall that dropped the entire report — not to the fields.
  A local table read cannot stall, race or drop the post, so the enrichment rides the post that
  was already going out and v4.7.279's reasoning stands untouched.

  Rules it follows:
  * **Fill, never overwrite.** The offer screen is authoritative for `description` (it is the
    wrap-joined text the player actually read); the catalogue supplies only what the screen did not.
  * **Returns a COPY.** The caller's list is also what goes to local history and seeds
    `run.lastOffered` — a reporting concern must not mutate either.
  * **Names are mapped at the boundary.** The catalogue keeps Lua-side camelCase (matching its
    existing `maxEchoes`); the API takes snake_case (`unlockedBy` → `unlocked_by`,
    `conflictsWith` → `conflicts_with`, `maxEchoes` → `num_echoes_possible`).
  * **`conflicts_with` is omitted when empty**, never sent as `{}`: an empty Lua table has no
    array/object distinction for yajl, and omitting the key already says "no known conflicts".
  * **`conflicts_with` is parsed since v4.7.325** from CONTEMPLATE's `Conflicts With:` line (a real
    sample finally showed the format: " and "-joined, and a blank line before the description), so
    the transport and storage built in v4.7.298 now carry data. v4.7.298 had held it back because a
    wrapped list would truncate and leak into the description; the tail rule that answers that is
    in [03-parsing-triggers.md](03-parsing-triggers.md).
  * **`combo_boon` is the ninth field (v4.7.322)** -- a BOOLEAN the tracker added (default false).
    The catalogue's `comboBoon` comes from two places: the seed (`M.BOON_COMBO`, the ten boons the
    tracker's export shows as combo) and a `Combo Boon?: Yes/No` line on any CONTEMPLATE that
    `mnem boonfill` runs -- which now also contemplates DESCRIBED boons, because a mature catalogue
    has no description gaps and would otherwise never learn it -- and, since v4.7.324, on the
    contemplate of every boon an offer screen shows (after that offer has posted, so it feeds the
    boon's NEXT post). Sent
    when the catalogue knows **either** answer; **omitted** when it knows neither, because an
    unknown posted as `false` is a guess that looks like data. Unlike the string fields, `false` is
    information: every store and merge on the way tests the TYPE, never truthiness. **Open
    question for the tracker's author:** the server defaults the field to false, so an omission
    may be stored as false -- and if it keeps the latest value, every client that omits it could
    overwrite another's true.

- **`reroll_count` is INFERRED from the screen, never from a command (v4.7.298).** Rerolls are real
  — `Negotiator`'s own text grants "5 additional rerolls" — but the command that spends one has
  never been captured, and inventing a command name is how `bash dwaeonic off` came to be
  documented for a command that never existed. So `M._rerollBump(list)` counts the **evidence**: a
  second offer screen, with no claim and no `GO!` in between, *is* a reroll.

  **The name set is the guard**, and it is what makes the inference safe — a reroll produces a
  different set of boons, while a mere re-print (scrollback, re-issued command, duplicated capture)
  produces the identical set. An identical re-print therefore neither counts nor resets: it is not
  evidence either way. Comparison happens **before** `run.lastOffered` is overwritten, which is the
  one line that would destroy it.

  The chain is ended by a claim (`onBoonClaim`) and by `GO!` (`onGo`), and **never by the ripple
  number** — at the boon screen `_offerAfterRipple` sends its own `wade status`, so `run.ripple`
  can advance *between two screens of one chain*, and keying on it would miss exactly the reroll it
  exists to count. `_resetRun()` clears **both** the count and the chain flag: clearing only the
  count is worse than clearing neither, because a chain left open makes the next run's first screen
  differ from the (now empty) previous names and post `reroll_count = 1` for a screen nobody
  rerolled. Prospero's Fortune (Negotiator's second pick after every fifth claim) is correctly
  *not* counted, because a claim intervened.

  Four things the deep review changed:

  * **The state lives on `ataxiaTemp`, not `M.run`** (`ataxiaTemp.mnemRerolls` /
    `.mnemOfferChain`, owned by `M._rerollCount()` / `_rerollReset()` / `_rerollBump()`).
    `ataxia_saveSettings` does `table.save(file, sanitizeForSave(ataxia))` — a **wholesale**
    serialization that strips only functions, metatabled objects and GUI snapshots — and
    `deepMerge` ends in an unconditional `dst[k] = v`, so a scalar kept under `ataxia.mnemosyne`
    comes back from disk on the next load. That is the v4.7.192–194 rule, and it is why
    `_relatchBoons` already keeps its guard on `ataxiaTemp`. **`002_Reporter_API.lua`'s header
    claim that run state is "in-memory only" was false** — `run.active`, `ripple`, `publicId` and
    `lastOffered` all persisted. Fixed separately in v4.7.299 (below).
  * **The count is snapshotted with the screen** (`M._pendingRerolls`), never re-read at send
    time. The POST is deferred to the ripple line or the 3s timeout, and `onBoonClaim`/`onGo` both
    close the chain the instant they fire — so a player claiming inside that window made the *last*
    screen of a chain, the most informative row there is, report `reroll_count = 0`.
  * **A replaced pending offer is FLUSHED, not dropped.** `_offerAfterRipple` used to overwrite
    `_pendingOffer` unconditionally. That was right when it was written (v4.7.279): a second screen
    arriving before the first had posted meant a duplicate capture. **The reroll feature makes two
    distinct, meaningful screens a normal event**, and nobody reconciled the two — so the
    rerolled-away screen was never posted and never recorded locally, which is precisely the data
    `reroll_count` exists to make sense of. Flushing is ripple-safe (a reroll is the same boon
    screen, hence the same ripple), and the original intent — no cross-contamination between the
    two lists — is preserved exactly.
  * **A run boundary DROPS it instead** (`M._dropPendingOffer`, called from `_resetRun`). Nothing
    cleared that slot before, which was survivable only while a replacement discarded it silently;
    once a replacement flushes, a stale pending offer would be posted under the *next* run. This is
    the one case where losing it beats sending it.

- **`/run_pause` is actually called (v4.7.298).** It had been on the API for as long as we have been
  posting to it and was never invoked. `onRunPause` sets the local `run.paused` flag (which is what
  drives the resume) and now also posts, gated on `_inRun()` — with nothing on the wire, a
  deliberate pause was indistinguishable to the tracker from a player who simply stopped mid-dive.
  Fire-and-forget: the flag is set by the caller before the POST, so a failed request costs the
  tracker a marker and costs us nothing — hence no `onError` undo, unlike `startRun`.

  **Gated on `_auto()`, not `_inRun()`** (changed by the deep review). `_inRun()` also requires
  `run.active`, which is our *belief* about the server and is false in exactly the window that
  matters: after a reload or SYSUPDATE mid-run, until the load handler's 6-second-delayed
  `/run_exists` answers — and that request has no `onError`, so an unreachable tracker leaves it
  false indefinitely. A pause landing there would be silently unreported, with no retry,
  reproducing the very problem this call was added to fix. Trigger 016's pattern is exact and
  Mnemosyne-only, so it cannot fire outside a dive: if the game says we paused a run, the run
  exists and the server is the authority. A stale POST answers `ok:false`, which is now surfaced.
  `mnem pause` is the manual override (see [05-commands.md](05-commands.md)).
- **`reportBoonsSelected`** accepts a string or array; a bare string is wrapped to `{ str }`.
- **`reportDeath`** defaults `killer` to `"unknown"` when empty.

### Monster buffering

`M.run.pendingMonsters` accumulates spawn lines (de-duped) captured at `GO!`. `M._flushMonsters()` joins them with `"; "` into a single `reportMonsters()` call and clears the buffer. It runs in `onRipple()` (after `setRipple`) and again in `endRun()`.


---

## The offer's ripple is decided by TIMING, not by a field (v4.7.279)

Reported by the tracker's author: *"you're sending boons a ripple late so you're not sending the
boons that are initially offered ... you're also sending boon information that you have cached."*

**`BoonsOfferedRequest` is `token` / `offered` / `class` / `race` and nothing else** -- verified
against the live `openapi.json`. There is **no ripple field**, so the server files an offer under
whatever ripple our last `/ripple_level` reported. That makes timing the whole of the attribution,
and ours was wrong at both ends:

* `wade status` was sent on **`GO!` and nowhere else**, so `/ripple_level` only ever updated at the
  START of a wave -- an offer posted at the boon screen landed under the ripple just FINISHED.
* At the **first** offer of a run, `/ripple_level` had never been sent at all. Nowhere to file it,
  which is exactly "not sending the boons that are initially offered".

The "cached" complaint is the same fault seen from the other side: an offer filed under the previous
ripple looks like data the tracker already holds. **Our list was never cached** -- `_parseNamedBlock`
reads the live screen every time.

`M._offerAfterRipple` now stashes the parsed list, sends `wade status`, and posts when `onRipple`
has reported. The flush sits **after** `M.setRipple(n)`, never before: the HTTP queue is serial, so
enqueueing `/boons_offered` behind `/ripple_level` is the entire fix.

**Bounded at `M.OFFER_RIPPLE_WAIT` (3s)**, because deferring this is what broke it once already --
v4.7.91 removed a deferral (the per-boon CONTEMPLATE chain) that could stall and silently drop the
whole report. Whichever comes first posts it; never dropped, at worst filed where it was before.

## `class` and `race` (v4.7.220, re-verified 2026-08-20)

Top-level optional strings on `BoonsOfferedRequest` -- **not** members of `BoonInfo`, where the
names suggest. Class is normalised (`:title()` minus the ` Lord`/` Lady` gender suffix, which would
otherwise halve every per-class count); race is passed through raw, since normalising against an
unverified vocabulary corrupts data more quietly than leaving it alone. **A missing
`gmcp.Char.Status` read OMITS the key** rather than sending `"unknown"`, which would become its own
cohort in the queries -- and because that omission is silent, `mnem status` now prints what would be
sent (`unread` in red when the read fails). A field that is correct and invisible is
indistinguishable from one that is broken.

## Read-only: `GET /boons/export` (seen 2026-09-18, not consumed)

The tracker's whole catalogue: per boon, description, quote, rarity, category, unlocked-by,
conflicts, echo counts, and `classes_seen` / `races_seen` / `min_ripple` / `max_ripple` / `echoes`.
Nothing reads it. It could fill the quotes and categories our catalogue lacks (which `mnem boonfill`
now gathers itself through its combo-status pass, v4.7.322), but it would need **filtering before any
import**: on 2026-09-18 it held ten descriptions beginning `Combo Boon?:        Yes` and one beginning
`Category:           Unset` -- screen meta lines some client glued onto the text. It has no
`combo_boon` field of its own. That corruption is also the only sample we have of the
`Combo Boon?` wording. Echoing its values back to the tracker would add nothing.

## Not reported, deliberately

`Remaining lives` and `Wave progress` (v4.7.278) are parsed from the WADE STATUS block but have no
endpoint. They are local state (`M.run.lives` / `M.run.waveProgress`) for `mnem status` and for
future risk gating, not telemetry.

## Run state does not survive a reload (v4.7.299)

The module was always *designed* around "the server is the source of truth" — on load, re-sync via
`/run_exists` rather than trust a stored copy. The header said so. It was not true.

`M.run` is a plain table hanging off `ataxia.mnemosyne`, and `ataxia_saveSettings` does
`table.save(file, sanitizeForSave(ataxia))` — **wholesale**. `sanitizeForSave` strips only
functions, metatabled objects and GUI snapshots, so a table of ordinary scalars goes straight to
disk; and `deepMerge` ends in an unconditional `dst[k] = v` for non-tables, so the **stored value
wins** over the freshly-initialised one. `active`, `ripple`, `publicId`, `lastOffered`, `lives` and
`waveProgress` all came back.

**This was never only a telemetry problem, which is what made it worth fixing.** The only thing
that clears run state is `_resetRun`, reached through `startRun`/`endRun` — both *below* the
`_auto()` gate. So with reporting off (the shipped default) nothing ever cleared it, while several
consumers that are **not** gated on reporting read it:

| Reader | Field | Effect of a stale value |
|---|---|---|
| `ataxiaBasher_bardDance` (`basher/002`) | `run.boss` | picks **wavedance** (the boss dance) on an ordinary ripple |
| `ataxiaBasher_bardDance` | `run.ripple` | **hawkstep** at ripple >= 25 applied at ripple 1 |
| `ataxiaBasher_mnemLdeck…` (`basher/010`) | `run.boss` | **withholds Xylthus** — a card cannot bind a boss |
| `_nextPatrolStep` (`008_Explorer`) | `run.boss` | patrols a cleared grid for a boss that is not there |
| swarm depth-scaling (`009_Swarm_Tactics`) | `run.ripple` | deep-ripple thresholds at shallow depth |

`M._clearStaleRun()` wipes `active`, `boss` and everything `_resetRun` owns, and is called from
**`ataxia_loadSettings`** rather than from a second `sysLoadEvent` handler — ordering is the subtle
half, and a separate handler's order relative to the loader is undefined, so it could run *before*
the merge and be undone by it. Inside the loader it is ordered by construction. It sits after the
whole main-load `pcall`, so it covers the `_ataxia_backup` restore branch as well.

`active` and `boss` are cleared here but deliberately **not** in `_resetRun`: `startRun` sets
`active` true and *then* calls `_resetRun`, so clearing it there would undo the caller; and `boss`
is re-learned from every ripple's `Objective:` line, so per-ripple clearing is already correct —
it is only at load, before any ripple line, that a stale one is live.

The seam is tested in `test_settings.lua`, not just the function in `test_mnemosyne.lua`: a tested
function with a caller that bypasses it is still dead code (v4.7.297). That test also pins the
**ordering**, by asserting the reset observes the *stored* values at the moment it runs.
