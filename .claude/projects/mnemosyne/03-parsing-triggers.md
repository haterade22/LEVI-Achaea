# Parsing & Triggers

`triggers/.../mnemosyne/` holds fifty triggers. The nine that drive the run lifecycle (`001`–`009`) match Mnemosyne game text and call thin handlers in `004_Parsers.lua`; the later ones are mostly BOONS-list flag rows and per-line feeds for the explorer (`008_Explorer.lua`) and swarm (`009_Swarm_Tactics.lua`) modules, and are inventoried in the same table. `010`–`015` — class-basher boon rows, the ice-slip feed (see [07-explorer.md](07-explorer.md)), the BOONS-list pretty-printer — belong to the systems they drive and are not repeated here. The handlers are pure Lua string logic; the two multi-line blocks (effects, boons) and the per-wave monster line are collected with temporary catch-all line triggers rather than read back after the fact. This doc is the parse layer only — the run lifecycle is [01-architecture.md](01-architecture.md), the HTTP queue and payloads are [02-reporting.md](02-reporting.md).

## Trigger → Handler

Patterns are Mudlet regex (`type: 1`), quoted verbatim from each trigger file.

| # | Trigger | Pattern | Handler call | Gate |
|---|---------|---------|--------------|------|
| 001 | Run Start | `^You begin to wade out into the depths of the Mnemosyne` | `onRunStart()` → `startRun()` | `_auto` |
| 002 | Ripple Level | `^You wade (\d+) ripples? deep into the tides of memory` | `onRipple(tonumber(matches[2]))` | map always; then `_auto` |
| 003 | Effects | `^Ongoing effects:` | `onEffectsHeader()` | `_inRun` |
| 004 | Boons Offered | `flickers of power that may aide you` | `onBoonsOffered()` | `_inRun` |
| 005 | Countdown | `^0$` | `onCountdownZero()` | `_inRun` |
| 006 | Go | `^GO!$` | `onGo()` | `_auto` OR `ataxiaBasher.inMnemosyne` |
| 007 | Death | `^You have been slain by (.+?)\.?$` | `reportDeath(matches[2])` | inline `_inRun` check in trigger body |
| 008 | Objective | `^Objective:\s+(.+)$` | `onObjective(matches[2])` | `_inRun` |
| 009 | Run End | `^The Mnemosyne releases its hold` | `onRunEnd()` → `endRun()` | `_inRun` |
| 016 | Run Pause | `^You whisper to the Mnemosyne and beseech that it grow still for a time\.$` | `onRunPause()` | none (flag set unconditionally) |
| 017 | Splinterbark | `^Splinterbark:\s+Your tree tattoo is tainted with fell magic` | `onSplinterbarkSeen()` | none (handler self-gates on `ataxiaBasher.inMnemosyne`) |
| 018 | Hammer and Anvil | `^Hammer and Anvil\s+\d+\s+\w+` (BOONS-list row) | sets `mnemHammerAnvil = true`, clears `ataxiaBasher.shielded` | none (flag set unconditionally; reset on run start/end) |
| 019 | Bladed Reflexes | `^Bladed Reflexes\s+\d+\s+\w+` (BOONS-list row) | sets `bmBladedReflexes = true` (BM basher keeps `SHIN AUGMENT 1` up) | none (flag set unconditionally; reset on run start/end) |
| 020 | Sleuth | `^Sleuth\s+\d+\s+\w+` (BOONS-list row) | sets `mnemSleuth = true` (swarm recon: fullsense on GO) | none (flag set unconditionally; reset on run start/end) |
| 021 | Roll Hide | `^Roll Hide\s+\d+\s+\w+` (BOONS-list row) | sets `mnemRollHide = true` (stage-2 panic tumble) | none (flag set unconditionally; reset on run start/end) |
| 022 | Flight Lines | `^The ring of shining metal carries you up into the skies\.` / `^You land easily, back on the ground again\.` | `swarm.onFlightUp()` / `swarm.onFlightDown()` (confirmed airborne state for the recovery hover's fly re-send) | none (pure state flag) |
| 023 | Reaper Tithe | `^You reap a tithe of power from your fallen foe\.` | `onReaperTithe()` — increments `ataxiaTemp.reaperKills`, sets `mnemReaper` (the line is its own proof of the boon), echoes the running `+N% damage total` | none (line only prints with the boon up) |
| 024 | Reaper | `^Reaper\s+\d+\s+\w+` (BOONS-list row) | sets `mnemReaper = true` (tally itself is driven by trigger 023) | none (flag set unconditionally; reset on run start/end) |
| 025 | Wall Blocked | `A wall blocks your way.` / `A wall bars your path.` (exact) | `onWallBlocked()` — leaps the in-flight explorer move over the wall (never condemns; shares the ice-slip budget) | self-gated on `explore.on and explore.moving` |
| 026 | Wall Melted | `^You send a lash of fire to strike the icewall to the \w+, and it quickly melts\.` | `swarm.onWallMelted()` — confirmation-clears `wallRaised` for the room + the melt hold | none (a melt landing here is authoritative) |
| 027 | Bloodscent | `^Bloodscent\s+\d+\s+\w+` (BOONS-list row) | sets `mnemBloodscent = true` (per-ripple auto-recon; rows parsed by 028) | none (flag set unconditionally; reset on run start/end) |
| 028 | Sense Lines | `^You sense out the location of your prey` / `^You sense (.+) \(#(\d+)\) at (.+)\.$` | `swarm.onSenseStart()` / `swarm.onSenseRow(name, id, room)` — batches rows, commits parsed recon (per-room counts, crowded-room callout) | self-gated on `ataxiaBasher.inMnemosyne` |
| 029 | Haemophiliac | `^Haemophiliac:\s+Defeating a denizen causes you to bleed` (status-screen effect row) | `onHaemophiliacSeen()` — arms wade-slower pacing (post-clear explorer moves hold until bleeding < 50 AND HP >= 90%, `M._haemoHold`; SSC `curing clotat` does the clotting) | inline `inMnemosyne` gate + transition guard (mirrors Splinterbark) |
| 030 | Kai Unleashed | `^Kai Unleashed\s+\d+\s+\w+` (BOONS-list row) | sets `mnemKaiUnleashed = true` (Shikudo basher: Rain-form `KAI CHOKE` AoE prepended to the combo at 2+ denizens — eq-based, kai-free vs denizens — 30s burst cooldown; `ataxiaBasher_kaiUnleashedChoke`) | none (flag set unconditionally; reset on run start/end) |
| 031 | Kai Burst | `^Your surroundings ripple like a lake's surface struck as a transparent wave of kai energy surges` | `ataxiaBasher_kaiUnleashedBurst()` — burst CONFIRMED: starts the 30s cooldown, clears the retry guard, (re)sets the flag (self-proving line) | none |
| 032 | Seasone Phials | `reaches into her robes and withdraws a handful of fragile glass phials` (substring) | `onSeasonePhials()` — RELEASES the reserved tree (`curing tree on`), then **BANKS** it (v4.7.213) and **DISENGAGES on burst two** (v4.7.215). See *Seasone: bank the tree, then leave* below | gated on `inMnemosyne`; Splinterbark gates only the TATTOO half |
| 033 | Senseless Flurry | `^Senseless Flurry\s+\d+\s+\w+` (BOONS-list row) | sets `mnemSenselessFlurry = true` (Shikudo basher keeps NUMB up in Rain form — eq rider; defence-gated `ataxia.defences.numbness`, 5s attempt-hold; Kai Choke outranks it — `ataxiaBasher_senselessFlurryNumb`) | none (flag set unconditionally; reset on run start/end) |
| 034 | Panoply | `^Panoply\s+\d+\s+\w+` (BOONS-list row) | sets `psionPanoply = true` (Psion basher swaps `weave deathblow` → `weave flurry`; cleave keeps shield-break — `ataxiaBasher_psionBashing`) | none (flag set unconditionally; reset on run start/end) |
| 035 | Might Of Sycaerunax | `^Might of Sycaerunax\s+\d+\s+\w+` (BOONS-list row) | sets `dragonMightSycaerunax = true` (dragon basher drops the `;summon <ele>` from the blast weave AND the shielded reblast — breath persists through BLAST, +25% blast damage; breath-down still summons once — `ataxiaBasher_dragonBashing`) | none (flag set unconditionally; reset on run start/end) |
| 036 | Draconic Rampage | `^Draconic Rampage\s+\d+\s+\w+` (BOONS-list row) | sets `dragonRampage = true` (dragon basher spends the balance swing on `trample` at 2+ denizens when the 40s proc is ready — send stamp + in-flight hold; shield rounds skip it — `ataxiaBasher_dragonRampagePick`) | none (flag set unconditionally; reset on run start/end) |
| 037 | Deluge | `^Deluge:\s+All rooms are underwater\.` (status effect row) | `onDelugeSeen()` — sets `mnemDeluge` (FLY is impossible underwater: the swarm escape ladder + fly-kite take their grounded branches via `S._canFly()`) | `inMnemosyne` gate + transition guard (Haemophiliac shape; telemetry-independent) |
| 038 | Flashforward | `^Flashforward\s+\d+\s+\w+` (BOONS-list row) | sets `dwFlashforward = true` (Depthswalker basher keeps CHRONO BLUR up -- eq rider paid in AGE, age-capped, rides shielded rounds too -- `ataxiaBasher_dwFlashforward`) | none (flag set unconditionally; reset on run start/end) |
| 039 | Army Of The Dead | `^Army of the Dead\s+\d+\s+\w+` (BOONS-list row) | sets `infArmyOfDead = true` (Infernal basher casts `summon hands of the grave` at 2+ denizens -- room nuke; 20s provisional stamp, shield rounds skip it -- `ataxiaBasher_infGravehands`) | none (flag set unconditionally; reset on run start/end) |
| 040 | Daemon Jaws | `^Daemon Jaws\s+\d+\s+\w+` (BOONS-list row) | sets `infDaemonJaws = true` (hyena maul cd -66%; the game's ready-line already comes sooner, so this only shrinks the missed-line SAFETY timer 30s -> ~10.2s -- `ataxiaBasher_hyenaMaulCooldown`, basher/005) | none (flag set unconditionally; reset on run start/end) |
| 041 | Indiscriminate | `^Indiscriminate\s+\d+\s+\w+` (BOONS-list row) | sets `infIndiscriminate = true` (ARC becomes denizen-effective; the Infernal basher swings the untargeted room-wide arc INSTEAD of its single-target attack at 2+ denizens -- `ataxiaBasher_infArc`) | none (flag set unconditionally; reset on run start/end) |
| 042 | Necrotic Aura | `^Necrotic Aura\s+\d+\s+\w+` (BOONS-list row) | sets `infNecroticAura = true` (Infernal basher keeps the DEATHAURA defence up -- attacks then inhibit denizen healing; the proc line is captured by `denizen_attacks_misc_lines/024`, which records `inhibit` on the denizen) | none (flag set unconditionally; reset on run start/end) |
| 043 | Fury Of Ages | `^Fury of Ages\s+\d+\s+\w+` (BOONS-list row) | sets `infFuryOfAges = true` (basher holds `fury on` while EP >= 60%, drops it under 25% -- the boon QUADRUPLES endurance cost; 30s toggle floor because each activation may cost 500 wp -- `ataxiaBasher_infFury`) | none (flag set unconditionally; reset on run start, and run-end also sends `fury off`) |
| 044 | Winter's Heart | `^Winter's Heart\s+\d+\s+\w+` (BOONS-list row) | sets `mnemWintersHeart = true` (DEEPFREEZE works on denizens and hits the whole room with cold -- cast at 2+ denizens; an EQ cast, so it rides free on balance-attack classes and takes the eq slot for Magi -- `ataxiaBasher_winterDeepfreeze`) | none (flag set unconditionally; reset on run start/end) |
| 045 | Resourceful | `^Resourceful\s+\d+\s+\w+` (BOONS-list row) | sets `mnemResourceful = true` (-10% endurance/willpower costs; each denizen kill restores 10% of the class resource. For Infernal that is LIFE ESSENCE, so held with Army of the Dead it drops Tyranny's crowd gate to 1 denizen and its essence floor 20% -> 10% -- `ataxiaBasher_infGravehands`) | none (flag set unconditionally; reset on run start/end) |
| 046 | Falconer's Tactics | `^Falconer's Tactics\s+\d+\s+\w+` (BOONS-list row) | sets `mnemFalconersTactics = true` (falcon rake cd -66%; the Runewarden twin of Daemon Jaws -- shrinks the missed-line safety timer 30s -> ~10.2s, `ataxiaBasher_falconRakeCooldown`) | none (flag set unconditionally; reset on run start/end) |
| 047 | Homebound | `^Homebound\s+\d+\s+\w+` (BOONS-list row) | sets `mnemHomebound = true` (explorer sketches `raido` on the ground in the HOLDING room right before the descent -- the raido must be somewhere we are not standing; once per ripple, `M._exploreMove`) | none (flag set unconditionally; reset on run start/end) |
| 048 | Hammer and Nail | `^Hammer and Nail\s+\d+\s+\w+` (BOONS-list row) | sets `mnemHammerAndNail = true` (with a sowulu rune down, attacks splash to a second denizen: the Runewarden basher sketches sowulu at 2+ denizens, once per room, free queue -- `ataxiaBasher_rwSowulu`). **Distinct from `mnemHammerAnvil`** (Hammer and ANVIL = bypass denizen shields) | none (flag set unconditionally; reset on run start/end) |
| 049 | Ablaze Burn | `^The roaring inferno engulfs you as you fight to find a way out\.$` | `onAblazeBurn()` — stamps `M.ablazeAt`; `M.roomAblaze()` reads it back with a lazy `ABLAZE_STALE` (12s) expiry and gates the swarm recovery hover (`S._canHover()`). Latched on the BURN LINE, not the `The area is ablaze!` room text — the description arrives mid-line, and only the burn line proves the fire is still hurting *us*, so leaving the room self-expires the flag with no "fire goes out" line (never captured) | handler self-gates on `ataxiaBasher.inMnemosyne` |
| 050 | Dragged From Sky | `^A tentacle shoots up from the ground, wraps itself around you, and drags you back to earth\.$` | `swarm.onDraggedDown()` — a DENIZEN pulled us out of the air: latches `S.grounded` (per-ripple; `S.onRipple` clears it), clears `S.flying`/`S.flightConfirmed`, and converts an in-progress recovery hover into the grounded retreat. `S._canFly()` honours it alongside `mnemDeluge` | handler self-gates on `ataxiaBasher.inMnemosyne` |

The gate is enforced *inside* each handler (see the gating model in [01-architecture.md](01-architecture.md)); only trigger 007 does its `_inRun()` check in the trigger body before calling the API directly. `onRipple` is the exception to the auto-gate: it first drives the mini-map (`map.onRipple(n)`, unconditional) and only then gates telemetry on `_auto()`.

Trigger 006 (`GO!`) also calls `ataxia.mnemosyne.exploreOnGo()` after `onGo()` — the auto-explorer's resume hook (a no-op unless it was paused at a boon screen); see the [monster-capture](#deterministic-monster-capture) and [07-explorer.md](07-explorer.md) notes.

## Pause / resume — `onRunPause` + `onRunStart` (triggers 016, 001)

`WADE STILL` — "You whisper to the Mnemosyne and beseech that it grow still for a time." — suspends the current run **without ending it server-side**: the next wade re-enters the *same* wade, not a fresh one. `onRunPause` (trigger 016) sets `M.run.paused = true` unconditionally (mirroring the boon flags — the `_auto` gate is applied later, when the flag is consumed).

`onRunStart` (trigger 001, gated on `_auto`) then branches on that flag: if `M.run.paused`, it clears the flag and calls `runExists()` (`/run_exists`, re-syncs `active` + ripple, and safely no-ops to inactive if the server no longer holds the run) instead of `startRun()` (`/run_start`) — so a resumed wade doesn't orphan the paused run's progress under a brand-new `public_id`. `onRunEnd` clears `M.run.paused` **unconditionally** (not only via the `_inRun`-gated `endRun`), because with telemetry off — the shipped default — that gated path never runs, and a leftover `paused=true` would misfire the *next* fresh wade into a resume that never `/run_start`s it.

**Ordering constraint in trigger 001's body**: `reaperOnWade()` must run **before** `onRunStart()` — it reads `run.paused` to decide whether the wade is a resume (Reaper kill tally survives; it's the same server-side run and the count is unrecoverable) or a fresh run (tally reset), and `onRunStart` consumes that flag on the resume path.

`BOON CLAIM <name>` is not a trigger but an alias intercept (`002_Boon_Claim`, regex `^(?i)boon claim (.+)$`) that passes the real command through and then calls `onBoonClaim(name)` — detail in [05-commands.md](05-commands.md).

## Multi-line block capture — `_captureLines`

Effects and boons print as wrapped, dashed-divider blocks whose arrival is spread across several game lines, so a start-trigger *arms* a temporary catch-all trigger to collect the following lines until an end condition flushes them. `M._captureLines(opts)` is the generic engine:

```
opts.onLine(line) -> "stop" | "skip" | nil     -- nil = keep this line
opts.timeout      -> seconds of silence before an automatic flush (backstop)
opts.onDone(lines)                              -- pcall-guarded

M._captureLines(opts)
  ├─ if M._capturing and M._captureForceFinish: pcall(M._captureForceFinish)  (force-finish a wedged prior capture)
  ├─ M._capturing = true
  ├─ M._captureForceFinish = finish   (exposed so the NEXT capture can flush a stuck one)
  ├─ tid = tempRegexTrigger([[^.*$]], per-line body)   -- catch-all
  │     res = opts.onLine(line)
  │     res=="stop" -> finish();  res~="skip" -> table.insert(lines, line);  bump()
  ├─ bump(): kill + re-arm tempTimer(opts.timeout, finish)   -- resets each line
  └─ finish(): guard done → M._capturing=false, M._captureForceFinish=nil, killTrigger, killTimer, onDone(lines)
```

`bump()` restarts the silence timer on every captured line, so a block that stops emitting (no explicit terminator) still flushes after `timeout` seconds. `finish()` is idempotent (`done` guard) and always clears `M._capturing`, so a parse error in `onDone` can't wedge the guard shut and block the next capture.

**Force-finish a wedged capture (v4.7.93).** The old single-slot lock silently *ignored* a new capture while one was active — so if a prior capture ever wedged (e.g. a steady stream of lines kept resetting its silence `timeout` so `finish` never fired), every later boon/effects capture was dropped and its report never posted. Now, before taking the slot, `_captureLines` flushes any stale in-flight capture via `M._captureForceFinish` (the previous capture's own `finish`, published on `M` while it holds the slot). `finish` nils `M._captureForceFinish` on completion, so a cleanly-finished capture leaves nothing to force. The new block then always runs.

### Continuation-line joining — `_parseNamedBlock`

Both blocks use a `Name:  <padded>  description` layout, and long descriptions word-wrap onto un-prefixed continuation lines. `_parseNamedBlock(lines)` rebuilds each entry:

- A new entry matches `^(%S.-):%s%s+(%S.*)$` (name, then **two+ spaces**, then description) and is accepted only when `#name <= MAX_NAME_LEN` (40) — a longer "Name:" match is treated as prose, not a new entry.
- A line with no `Name:` prefix (matched by `^%s*(%S.-)%s*$`) is a wrapped continuation and is appended to the **previous** entry's `description` with a single joining space.
- Blank lines (`^%s*$`) and dashed dividers (`isDivider` = `^%-%-%-+`, matching the game's ~80-dash rules) are skipped.

Result is `{ {name, description}, … }`, with trailing whitespace trimmed off both fields.

### `onEffectsHeader` (trigger 003)

Fires on `Ongoing effects:`. It captures with `timeout = 1.5`, skips the one divider immediately under the header (a `skippedDash` latch), and **stops** on the first blank line or the closing divider. The collected lines go through `_parseNamedBlock`; a non-empty list is sent via `reportEffects`.

### `onSplinterbarkSeen` / `restoreTreeCuring` (trigger 017) — self-harm safety

The `Splinterbark` ongoing effect taints the tree tattoo: every touch by the game's curing bleeds you and inflicts a random malady. Trigger 017 matches the effect's status-screen line and calls `onSplinterbarkSeen()`, which sends `curing tree off` — **transition-guarded** by `M._treeCuringOff` so it fires only once per OFF flip, not on every status re-read, and **gated on `ataxiaBasher.inMnemosyne`** so a `mnem affixes`/library read outside a run can't toggle curing. `onRunEnd` calls `restoreTreeCuring()` (`curing tree on`, no-op unless we'd turned it off). Deliberately a plain status-screen trigger, **not** hung off the `_inRun`-gated `onEffectsHeader` affix parse, so the safety works even with telemetry off. Reload-safe: `M._treeCuringOff` resets to nil, and the next Splinterbark line re-asserts `curing tree off` idempotently.

### `onObjective` (trigger 008)

A single status line, not a block. `Objective:  defeat <X>` is trimmed and matched against `^defeat (.+)$`; a normal ripple's `defeat N waves of enemies` (matched by `^%d+ waves? of enemies`) is ignored, and only a genuine boss name is sent via `reportBoss`. It arrives after the ripple line in the same `WADE STATUS` output, so `/ripple_level` still precedes `/boss`.

## Boons — offer, enrich, claim

### `onBoonsOffered` (trigger 004)

Fires on `flickers of power that may aide you`. Capture runs with `timeout = 3`; lines before the first divider are skipped, the opening divider is skipped, and capture **stops** at the second divider or the `BOON CLAIM` footer (whichever comes first). The parsed list's names are recorded into `M.run.lastOffered` (so a later `BOON CLAIM` can resolve the game's exact spelling), then handed to `_reportBoonsOfferedEnriched`. The trigger *also* calls `onBoonScreen()` unconditionally (outside the `_inRun` telemetry gate): this line is the de-facto **ripple-complete** marker, and it's the signal the auto-explorer keys on to stop sweeping — see [07-explorer.md](07-explorer.md).

### `_reportBoonsOfferedEnriched` — posts immediately (v4.7.91)

`_reportBoonsOfferedEnriched(list)` records the offer to local history and `reportBoonsOffered(list)`s it **straight away**, with the name+description taken directly off the offer screen:

```
_reportBoonsOfferedEnriched(list)
  ├─ _recordOffers(list)          (local history #6)
  └─ reportBoonsOffered(list)     (name+description as-is → immediate POST)
```

The old design gated this POST behind a slow (~2.5s/boon) per-boon `BOON CONTEMPLATE` enrichment chain, which **raced the next ripple's captures for the single `_capturing` slot** — on a lost race the chain stalled and the entire `/boons_offered` was silently dropped (the reported bug: monsters posted, boons never did) — and even when it completed it could post *after* the player had waded, landing the boons on the wrong ripple. Name+description is what the tracker shows; rarity/echoes are optional and are still learned locally from the BOONS list (trigger 013) + `mnem boonfill`.

### The `BOON CONTEMPLATE` enrichment state machine (now backfill-only)

The sequential contemplate walk **is no longer on the offer path** — `_reportBoonsOfferedEnriched` posts immediately (above). The machinery is retained and now drives only `boonFill` (the `mnem boonfill` backfill of already-owned boons whose description was never captured). It is still strictly sequential — one contemplate block in flight at a time, matching the `_captureLines` guard — `_contemplateNext` walking `send("boon contemplate <name>")` → `_captureContemplate(cb)` → `_applyContemplate` → `tempTimer(0.5, next)`.

- **`_captureContemplate(cb)`** captures with `timeout = 2`. It **never** captures a `BOON CLAIM` line (returns `"skip"`), skips the `<name>:` header and opening divider, and **stops** at the closing divider. `onDone` is one-shot (`called` latch) and passes `_parseContemplate(lines)` to `cb`.
- **`_parseContemplate(lines)`** returns `{ rarity, num_echoes_possible, description, quote }`. It reads `Rarity: <r>`, the authoritative **`Maximum echoes: N`** line (printed only for echo-capable boons → `num_echoes_possible = N`), and `Can echo: <Yes/No>` (`No` → `0`, `Yes` → a floor of `1` that a `Maximum echoes` line refines to `N`) — so an echo-capable boon reports its real cap, not a flat `1`, and the `Maximum echoes` line is consumed as meta rather than leaking into the description. It then advances through sections `meta → desc → quote`: non-blank lines after the meta rows build the description paragraph, a blank line switches to the quote section, and the trailing double-quoted line becomes `quote` (surrounding `"` stripped).
- **`_applyContemplate(boon, info)`** merges **only `rarity`, `quote`, and `num_echoes_possible`** onto the offered entry. It deliberately does **not** take contemplate's `description`: the offered-block description is authoritative and already wrap-joined, and the first boon's contemplate is armed right beside the `BOON CLAIM` offered footer, which was corrupting the first boon's description.

### `onBoonClaim(name)`

Called from the alias. `name` is resolved against `M.run.lastOffered` by `_resolveClaim(name, offered)` — a **slot number** (`boon claim 2` → `offered[2]`), an exact case-insensitive name, or a **unique case-insensitive prefix**. On a hit the claim is recorded to local history (`_recordClaim`, see [06-history.md](06-history.md)) and `reportBoonsSelected` is sent with the **canonical** offered spelling. A typo, an ambiguous prefix, or a stale claim reports nothing and only `decho`s — see [05-commands.md](05-commands.md).

## Deterministic monster capture

The final wave prints three consecutive lines — the countdown `0`, the mob spawn line, then `GO!`:

```
0                    ← trigger 005  (onCountdownZero)
<mob spawn line>     ← e.g. "A host of malagmae joins the fray!"
GO!                  ← trigger 006  (onGo)
```

Reading the spawn line back with `getLines()` at `GO!` was unreliable — word-wrap and prompt timing made "the line above" ambiguous. Instead the middle line is captured **positionally**, as the next physical line the game emits after the `0`:

1. **`onCountdownZero()`** (gate `_inRun`) clears `M._mobCandidate`, kills any stale `M._mobTrig`, and arms a one-shot `tempRegexTrigger([[^.*$]], …)`. That trigger trims the line, ignores blanks (staying armed), and on the first non-blank line kills itself. If that line is `GO!` or all-digits, no mob spawned this wave; otherwise it stores the line in `M._mobCandidate`.
2. **`onGo()`** (gate `_auto` OR `ataxiaBasher.inMnemosyne`) kills the candidate trigger and, when `_inRun()` and a candidate exists, commits it via `onMonsters(cand)` — the **full spawn line, verbatim** (the community-tracker convention is the whole line, not a trimmed phrase). It then always `send("wade status", false)` to pull the status block that drives ripple / objective / effects reporting.

Because `onGo` also runs for the mini-map (`inMnemosyne`) even with reporting off, `WADE STATUS` is still issued; monster *reporting* inside it stays gated on `_inRun()`. `onMonsters` trims, drops empties, and appends to `M.run.pendingMonsters` de-duped — buffered, not sent, so it can be flushed after `/ripple_level` (see [01-architecture.md](01-architecture.md)).

### `_extractMob` — spawn-phrase trimming

`_extractMob(str)` trims a spawn sentence down to the mob's noun phrase, or returns `nil`. **It is retained as a utility but is no longer wired into reporting** — `onGo` sends the full spawn line (above). When it was the reporting path it worked as follows: the subject is a noun phrase built around **"of"** and closed by a **mob verb**:

| Spawn line | Extracted phrase |
|------------|------------------|
| "a host of malagmae **joins**…" | `a host of malagmae` |
| "the trolls of Riagath **wade**…" | `the trolls of Riagath` |
| "a ghastly horde of the restless dead **descends**…" | `a ghastly horde of the restless dead` |

Algorithm (word-indexed over `str`):

1. **Pivot on `of`.** For each word whose bare form is `of`, walk **left** up to 6 words to the outermost article (`a` / `an` / `the`) → `leftStart`, breaking early at an `as` clause or a comma-terminated word so flavour clauses don't leak in.
2. **Collect the object** after `of`, up to 5 words, stripping punctuation and stopping at trailing punctuation.
3. **Require a mob verb.** The object is accepted only if the very next word is in `MOB_VERBS` (a large set of movement/appearance verbs and their `-s` forms — join/step/emerge/swarm/wade/surge/…), confirming the phrase is the sentence subject rather than incidental "of" text.
4. **Join** `leftStart..of` + object (punctuation stripped) into the returned phrase.

Both walks are word-capped (6 left, 5 right) so a runaway sentence can't blow up the scan. A spawn line whose verb isn't in `MOB_VERBS` yields `nil`, and the whole trimmed line is reported instead — lossy-but-safe, since wording varies per mob.

### Notable behaviours

- **One capture at a time.** `_captureLines`, `_captureContemplate`, and the monster one-shot each own the single in-flight temp trigger; the `M._capturing` guard and the sequential `_contemplateNext` walk keep effects/boons/contemplate blocks from interleaving.
- **Silence backstop.** Every block has a `timeout` (1.5s effects, 3s boons, 2s contemplate) so a block that never emits an explicit terminator still flushes and never leaves a catch-all trigger armed.
- **Description authority.** `_applyContemplate` never overwrites the offered-block description; contemplate only adds `rarity` / `quote` / `num_echoes_possible`.

## Seasone: bank the tree, then leave (v4.7.213 + v4.7.215)

Seasone throws a phial burst that lands a DENIZEN-dealt truelock (kalmia/gecko/slike ->
AST/SLI/ANO/IMP; any one of them blocks a cure CHANNEL, which is what makes it lethal). While
her boss ripple is up the tree tattoo is RESERVED (`curing tree off`, so SSC cannot burn it on
incidental afflictions) by `reserveTreeForBoss` from the `Objective: defeat Seasone...` line --
telemetry-independent, armed before the `_inRun` gate in `onObjective`, released on ripple
change and run end.

**The burst ARMS a watcher, it does not spend the tattoo (v4.7.213).** From a death log: the
old handler touched tree the instant the first burst landed. That burst was survivable (51% HP,
SSC curing through it), so the charge was spent on a lock we were winning; eight seconds later
the second burst landed at 27% with the tattoo on cooldown, and repeated
`Your tree of life tattoo glows faintly for a moment then fades` until death.
`M._phialTreeTick` now spends it only when the lock is still up AND either HP has fallen to
`treeHp` (50%) or `treeGrace` (5s) has passed -- gated on `ataxiaTemp.usedTree`, the real
cooldown flag, so we no longer fire blind into a cooldown. If SSC breaks the lock itself, the
charge stays banked.

**Burst two DISENGAGES (v4.7.215).** Rationing one charge only ever buys ONE extra burst, and
she throws more than two -- each burst is a fresh truelock and there is one tattoo, so the
fight is not winnable by out-curing her. On burst two (`ataxia.mnemosyne.phialDisengage`,
default 2; `0` disables, `3+` stands longer) we unbank the tattoo -- there is no burst three to
save it for -- and call `S.disengage` (see [07-explorer](07-explorer.md)).

Two traps worth keeping written down:

- **Do NOT tick `_phialTreeTick()` from the burst line.** The afflictions arrive by GMCP a beat
  after it, so an immediate tick sees no lock, takes the `_phialTreeStop()` branch and tears
  down the whole watcher. That asynchrony is exactly why the existing code arms at t+1, never
  t+0. Set `ataxiaTemp.phialSpendTree` and let the already-armed watcher act.
- **Splinterbark gates only the tattoo half.** Its early `return` used to sit above every line
  of `onSeasonePhials`, so a Splinterbark Seasone got no tattoo AND no disengage -- the case
  with the fewest options left had the fewest behaviours. With the tree tainted there is no
  charge to ration, so the disengage moves to the **first** burst.

Burst count lives on `ataxiaTemp.phialBursts`, PER RIPPLE (cleared in `onRipple` and
`onRunEnd`): a new ripple is a new fight and must not start pre-armed by the last boss.

