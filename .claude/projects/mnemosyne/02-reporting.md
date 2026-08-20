# Reporting: HTTP Client & Reporter API

Two files: `001_HTTP_Client.lua` (transport — a serial POST queue) and `002_Reporter_API.lua` (one thin function per endpoint + run state). The tracker takes **no auth header**; every request is a POST whose JSON body carries a `token` field, stamped on automatically by the client.

## Configuration

`M._cfg()` returns (and lazily creates) `ataxia.settings.reporting`:

| Key | Default | Purpose |
|-----|---------|---------|
| `enabled` | false | Master auto-report toggle (`mnem on/off`) |
| `contemplate` | true | Stored boon-enrichment toggle (`BOON CONTEMPLATE`). **No longer gates `/boons_offered`** — offers post immediately now (see Notable behaviours); the enrichment chain (`_contemplateNext`) is retained but off the offer path |
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

### Health check (`mnem test`)

`M.testHealth()` does a plain `getHTTP(baseUrl.."/health", {})`. Separate `sysGetHttpDone`/`sysGetHttpError` handlers (`_onGetDone`/`_onGetError`) match on the `/health` URL and echo the result. GET is used here, not the POST queue.

## Reporter API (`002_Reporter_API.lua`)

Each function guards on `M._hasToken()` and enqueues. Payload shapes:

| Function | Endpoint | Payload (plus auto `token`) | Response used |
|----------|----------|------------------------------|---------------|
| `startRun()` | `POST /run_start` | `{}` | `public_id` → `run.publicId` |
| `runExists()` | `POST /run_exists` | `{}` | `exists`, `ripple` → sync run state |
| `endRun()` | `POST /run_end` | `{}` | — (echo only) |
| `setRipple(n)` | `POST /ripple_level` | `{ ripple = n }` | — (sets `run.ripple` on OK) |
| `reportMonsters(str)` | `POST /monsters` | `{ monsters = str }` | — |
| `reportBoss(name)` | `POST /boss` | `{ boss = name }` | — |
| `reportEffects(list)` | `POST /effects` | `{ effects = [{name, description}, …] }` | — |
| `reportBoonsOffered(list)` | `POST /boons_offered` | `{ offered = [{name, description, quote?, rarity?, num_echoes_possible?}, …], class?, race? }` | `class`/`race` from `M._charInfo()` (v4.7.220) |
| `reportBoonsSelected(names)` | `POST /boons_selected` | `{ selected = [name, …] }` | — |
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

  Both branches of `_reportBoonsOfferedEnriched` (the immediate post and the
  contemplate-enriched one) route through `reportBoonsOffered`, so the tagging lands on the
  real path either way. Source path: `gmcp.Char.Status.class` / `gmcp.Char.Status.race` —
  `Char.Status` is pushed on login and on change, NOT every prompt like `Char.Vitals`.
  Note that a dragon reports race `Dragon` with class `<colour> Dragon`, so dragons appear as
  several classes sharing one race; `Undead` is a race, not a modifier.

- **`setRipple(n)` guard.** Skips locally if `n <= run.ripple` (the API errors on a lower ripple and no-ops on equal). `run.ripple` is only advanced inside the success callback.
- **`startRun()` optimism.** Sets `run.active = true` and calls `_resetRun()` *synchronously* before the async POST, so the first wave isn't lost while waiting for the response.
- **Pause / resume (no new `public_id`).** A "beseech that it grow still" pause sets `run.paused` (`onRunPause`, `004_Parsers.lua`) **without** ending the run server-side. The next wade's `onRunStart` then resumes via **`runExists()`** (`/run_exists`) instead of `startRun()`, so no fresh `/run_start` fires and **no new `public_id` is minted** — the resumed run keeps its server-side identity, and `/run_exists` re-syncs `run.active` + `run.ripple`. `run.paused` is cleared unconditionally in `_resetRun()` (hence on any genuine `startRun`/`endRun`) and in `onRunEnd`, so a telemetry-off end can't hijack the next fresh wade into a resume.
- **`endRun()`** flushes any final-wave monsters (`_flushMonsters()`) before enqueuing `/run_end`, then resets locally immediately (the run is over regardless of the response).
- **`reportBoonsOffered` is posted immediately.** `_reportBoonsOfferedEnriched(list)` (`004_Parsers.lua`) records local history and calls `reportBoonsOffered(list)` **right away**, with the `name`+`description` scraped straight off the offer screen — it is **not** gated behind the per-boon `BOON CONTEMPLATE` enrichment chain. (The old design contemplated each boon (~0.5s apiece) to fill `rarity`/`quote`/`num_echoes_possible` *before* posting; that chain competed with the next ripple's captures for the single `_capturing` slot and, on a lost race, stalled and silently dropped the whole `/boons_offered`, and even on success could post after the player had already waded onto the next ripple.) Name+description is all the tracker needs; the optional enrichment fields are learned locally instead (BOONS list via trigger 013 + `mnem boonfill`), which is why the `/boons_offered` payload lists them as optional (`?`).
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

## Not reported, deliberately

`Remaining lives` and `Wave progress` (v4.7.278) are parsed from the WADE STATUS block but have no
endpoint. They are local state (`M.run.lives` / `M.run.waveProgress`) for `mnem status` and for
future risk gating, not telemetry.
