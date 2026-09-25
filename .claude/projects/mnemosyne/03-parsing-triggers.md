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
| 022 | Flight Lines | `^The ring of shining metal carries you up into the skies\.` / `^You land easily, back on the ground again\.` | `swarm.onFlightUp()` / `swarm.onFlightDown()` (confirmed airborne state for the recovery hover's fly re-send; since v4.7.321 `onFlightUp` also stamps `S.flightUpAt`, the ring's takeoff evidence for the hover's premise checks) | none (pure state flag) |
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
| 050 | Dragged From Sky | `^A tentacle shoots up from the ground, wraps itself around you, and drags you back to earth\.$` | `swarm.onDraggedDown()` — a DENIZEN pulled us out of the air: latches `S.grounded` (per-ripple; `S.onRipple` clears it), clears `S.flying`/`S.flightConfirmed`, and converts an in-progress recovery hover into the grounded retreat, releasing BOTH holds (the recovery hold and escape mode, v4.7.321). `S._canFly()` honours it alongside `mnemDeluge` and `S._bound()` | handler self-gates on `ataxiaBasher.inMnemosyne` |
| 084 | Deadly Flourish | `^Deadly Flourish\s+\d+\s+\w+` (BOONS-list row) | sets `mnemDeadlyFlourish = true` (Bard basher swaps the balance swing to `blade flourish <target>` once every 15s -- AoE cutting damage; never from the `side` dance position while readable, bounded -- `ataxiaBasher_bardFlourish`, basher/002). Rows 051-083 are catalogued in the Mnemosyne block of `CLAUDE.md` rather than here | none (flag set unconditionally; reset on run start/end) |
| 085 | Death Stare | `^Death Stare\s+\d+\s+\w+` (BOONS-list row) | sets `mnemDeathStare = true` (class-agnostic eq rider `consider <target>` prepended to the round at 2+ denizens, or on a lone target after `ataxiaBasher.deathStareAfter`; once per ripple -- `ataxiaBasher_deathStare`, basher/001) | none (flag set unconditionally; reset on run start/end) |
| 086 | Death Stare Kill | `freezes for a moment before dying. Instantly.` (substring) | `ataxiaBasher_deathStareConfirm()` -- the ripple's charge is SPENT from the kill line, the in-flight replay released, the flag re-latched (self-proving line) | none |
| 087 | Searing Light | `^Searing Light\s+\d+\s+\w+` (BOONS-list row) | sets `mnemSearingLight = true` (Serpent basher conjures a lightwall FIRST in the round at 2+ denizens, once per room, first free planar exit -- `ataxiaBasher_searingLightwall`, basher/002) | none (flag set unconditionally; reset on run start/end) |
| 088 | Searing Light Proc | `^You form a ball of light in your palm and hurl it \w+\.$` / `searing the location with solar force` (substring) | `ataxiaBasher_searingLightConfirm(proc)` -- the conjure releases the replay and restamps the room from the landed moment; the detonation (boon-only, self-proving) also re-latches the flag | none |
| 089 | Contemplate Unknown | `^You consider for a time, but no information comes to you on such a boon\.$` | `onContemplateUnknown()` -- the name in flight is recorded in `M.history.boonUnknown`, dropped from `boonGaps()`, announced; the capture is force-finished so a batch moves on | none |
| 089 | Contemplate Unknown | `^You consider for a time, but no information comes to you on such a boon\.$` | `onContemplateUnknown()` -- **v4.7.328: only blacklists a name we never saw OFFERED.** The game printed the offered names itself, so a refusal for one of those means the screen closed (a claim, a reroll): it calls `offerScreenGone`, which also stops the chain asking for that screen's other boons. Any name the game prints clears an old mark | none |
| 095 | Boon Combo Granted | `^With every required boon now in hand, the mist of the Mnemosyne parts and bestows upon you another: (.+)\.$` (live 2026-09-19) | `onComboBoonGranted(matches[2])` (v4.7.328) -- a COMBO reward is granted, never offered or claimed, so nothing else recorded it: echoes `COMBO COMPLETE` with the recipe, records the claim, and queues its contemplate (which carries the next recipe) | none |
| 094 | Boon Rerolls Left | `^BOON REROLL to discard these options and see new ones \((\d+) remaining\)` (the offer footer; live 2026-09-19) | `onRerollsRemaining(matches[2])` (v4.7.327) -- sets `M._rerollsLeft` for the advisor's reroll hint; `onBoonsOffered` clears it for each new screen | none |
| 093 | Boon Callouts | `^Combo Boon\?:\s+(\w+)` / `^Can echo:\s+(\w+)` / `^Maximum echoes:\s+(\d+)` (BOON CONTEMPLATE meta lines; Flameheart sample 2026-09-19), plus the block boundaries `^Rarity:\s+` and `^-{3,}` | `onCalloutLine(line)` (v4.7.326) -- highlights a Yes / the echo count in place and adds it to the block's ONE summary line (`_calloutAdd`/`_calloutFlush`, with 092's conflicts); a boundary line prints what was gathered (the aggregator is module-global and chained contemplates arrive 0.5s apart), and does nothing when nothing was | none (a highlight) |
| 096 | Rimewrought | `^Rimewrought:\s+Perpetual ice coats your body` (Ongoing effects row) | `onRimewroughtSeen()` (v4.7.333/334) -- tattoos cannot be used, so the tattoo defences are taken off keep-up (they would only spam) and restored when the affix is gone | none |
| 097 | Famine | `^Famine:\s+Taking damage has a chance to make you more hungry` (Ongoing effects row) | `onFamineSeen()` (v4.7.333) -- eat to full every room (the Horn of Plenty path opens without its boons; corpse top-ups with Obligate Carnivore) | none |
| 098 | Graveborn | `^Graveborn\s+\d+\s+\w+` (BOONS-list row) | sets `mnemGraveborn` -- **only while `ataxiaBasher.inMnemosyne`** (v4.7.351) -- gravehands in every room | none |
| 099 | Bloodletter's Fury | `^Bloodletter's Fury\s+\d+\s+\w+` | sets `psionBloodletter` (in the tower only) -- keep `rupturesight` up | none |
| 100 | Razor Clarity | `^Razor Clarity\s+\d+\s+\w+` | sets `psionRazorClarity` (in the tower only) -- keep `clarity` up | none |
| 101 | Mindbreak | `^Mindbreak\s+\d+\s+\w+` | sets `psionMindbreak` (in the tower only) -- no rotation change; multiplies the one free shatter per full transcendence | none |
| 102 | Psiwave | `^Psiwave\s+\d+\s+\w+` | sets `psionPsiwave` (in the tower only) -- `psi radiate` replaces `psi shatter` as the full-transcendence action (v4.7.355; full-transcendence-only since v4.7.356) | none |
| 103 | Earthquake | `^Earthquake\s+\d+\s+\w+` | sets `psionEarthquake` (in the tower only) -- `enact upheaval` rides the Psion round on idle equilibrium in a crowd, above half health (v4.7.357) |
| 104 | Rubble Clamber | `You begin to slowly clamber over` (start of line) | `M.onClamber()` -- a move of ours in flight gets `CLAMBER_GRACE` (10s) instead of the 5s move timeout, once per move (v4.7.357) |
| 105 | Prophet of Creation | `^Prophet of Creation\s+\d+\s+\w+` | sets `psionProphet` (in the tower only) -- no consumer yet, by the user's choice (v4.7.358) |
| 092 | Boon Conflicts | `^Conflicts [Ww]ith:\s+(.+)$` (BOON CONTEMPLATE's conflicts line; real sample 2026-09-19) | `onConflictsLine(value)` (v4.7.325) -- highlights each conflicting boon in the line (red if held this run, gold otherwise -- the summary's colours); the list joins the block's summary line (v4.7.326); works for a contemplate typed by hand too | none (a highlight; "held" needs an active run) |
| 091 | Flight Truth | `flies up to your level from below.` / `swoops down from the skies to land beside you.` / `You are not flying, my friend.` (**substrings**, `type: 0` -- on the TAIL of each line, so any denizen name fits; live 2026-09-18) | `swarm.onFlightTruth(line)` (v4.7.321) -- the two FLYER lines latch `S.grounded` (a flyer lives on this ripple), end a recovery hover via `_hoverCompromisedTick`, and end a KITE properly via `S.reset` (which lands). "Not flying" is the reply to OUR `land`: it clears `S.flightConfirmed` and nothing else, because it can be stale (the death's reply arrived after a NEW hover had begun) and `S.flying` is the kite's mode flag. **Accelerators, not the guard**: the recovery tick checks the premise itself, denizen-agnostically (see 07-explorer) | handler self-gates on `ataxiaBasher.inMnemosyne` |

The gate is enforced *inside* each handler (see the gating model in [01-architecture.md](01-architecture.md)); only trigger 007 does its `_inRun()` check in the trigger body before calling the API directly. `onRipple` is the exception to the auto-gate: it first drives the mini-map (`map.onRipple(n)`, unconditional) and only then gates telemetry on `_auto()`.

Trigger 006 (`GO!`) also calls `ataxia.mnemosyne.exploreOnGo()` after `onGo()` — the auto-explorer's resume hook (a no-op unless it was paused at a boon screen); see the [monster-capture](#deterministic-monster-capture) and [07-explorer.md](07-explorer.md) notes.

## Pause / resume — `onRunPause` + `onRunStart` (triggers 016, 001)

`WADE STILL` — "You whisper to the Mnemosyne and beseech that it grow still for a time." — suspends the current run **without ending it server-side**: the next wade re-enters the *same* wade, not a fresh one. `onRunPause` (trigger 016) sets `M.run.paused = true` unconditionally (mirroring the boon flags — the flag itself is never gated) **and, since v4.7.298, posts `/run_pause`** so the server learns about it too.

That POST is gated on **`_auto()`, not `_inRun()`**. `_inRun()` additionally requires `run.active`, which is our *belief* about the server's state and is false in precisely the window that matters — after a reload or SYSUPDATE mid-run, until the load handler's delayed `/run_exists` answers, a request with no `onError` callback, so an unreachable tracker leaves it false indefinitely. A pause landing there would be silently unreported with no retry. Trigger 016's pattern is exact and Mnemosyne-only, so it cannot fire outside a dive: if the game says we paused a run, the run exists and the server is the authority on it. A stale POST comes back `ok:false`, which is now surfaced.

`onRunStart` (trigger 001, gated on `_auto`) then branches on that flag: if `M.run.paused`, it clears the flag and calls `runExists()` (`/run_exists`, re-syncs `active` + ripple, and safely no-ops to inactive if the server no longer holds the run) instead of `startRun()` (`/run_start`) — so a resumed wade doesn't orphan the paused run's progress under a brand-new `public_id`. `onRunEnd` clears `M.run.paused` **unconditionally** (not only via the `_inRun`-gated `endRun`), because with telemetry off — the shipped default — that gated path never runs, and a leftover `paused=true` would misfire the *next* fresh wade into a resume that never `/run_start`s it.

**Triggers 023 and 024 are DELETED** (v4.7.288). They were the Reaper tithe counter and its BOONS-row latch; the boon was removed from the game on 2026-09-01, so both matched a line that can never print again. The ordering constraint that used to live here — `reaperOnWade()` before `onRunStart()`, so a pause-resume wade kept the kill tally — went with them. **Trigger 078 (`Audit records:`) is the current highest number.**

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

The sequential contemplate walk **is no longer on the offer path** — `_reportBoonsOfferedEnriched` posts immediately (above). The offer-path chain (`_contemplateNext` / `_applyContemplate`) was dead from v4.7.279 and **removed in v4.7.322**. Contemplate now runs from `mnem boonfill` and -- since v4.7.324 -- after every posted offer (`_boonScreenContemplate`, every offered boon plus one gap): strictly sequential — one contemplate block in flight at a time, matching the `_captureLines` guard — `_boonFillNext` walking `send("boon contemplate <name>")` → `_captureContemplate(cb)` → `_learnBoon` → `tempTimer(0.5, next)`. Since v4.7.322 it contemplates DESCRIBED boons too, and ignores a captured block with neither `Rarity:` nor `Can echo:`; since v4.7.324 it is a cycle over the whole catalogue (stalest first), it UPDATES the text from a whole block (`info.complete`: the capture ended on its closing divider) and echoes what changed, it waits for another capture rather than force-finishing it, and it stops at GO!.

> **"Immediately" means "not behind the contemplate chain", not "synchronously".** Text below
> describing `_reportBoonsOfferedEnriched` as posting *right away* predates v4.7.279's ripple
> ordering fix and is only half the story: the offer is parked in `M._pendingOffer` and posted
> from `_flushPendingOffer`, driven either by the ripple line or by a 3-second
> `OFFER_RIPPLE_WAIT` fallback, so it lands *behind* `/ripple_level` and is filed under the right
> ripple. It is never deferred behind another command, and never dropped. See
> [02-reporting.md](02-reporting.md) for the deferred-post machinery and what it means for
> rerolls.

- **`_captureContemplate(cb)`** captures with `timeout = 2`. It **never** captures a `BOON CLAIM` line (returns `"skip"`), skips the `<name>:` header and opening divider, and **stops** at the closing divider. `onDone` is one-shot (`called` latch) and passes `_parseContemplate(lines)` to `cb`.
- **`_parseContemplate(lines)`** returns `{ rarity, num_echoes_possible, description, quote }`. It reads `Rarity: <r>`, the authoritative **`Maximum echoes: N`** line (printed only for echo-capable boons → `num_echoes_possible = N`), and `Can echo: <Yes/No>` (`No` → `0`, `Yes` → a floor of `1` that a `Maximum echoes` line refines to `N`) — so an echo-capable boon reports its real cap, not a flat `1`, and the `Maximum echoes` line is consumed as meta rather than leaking into the description. It then advances through sections `meta → desc → quote`: non-blank lines after the meta rows build the description paragraph, a blank line switches to the quote section, and the trailing double-quoted line becomes `quote` (surrounding `"` stripped).
- **Description authority.** For a boon the catalogue already describes, `_boonFillNext` passes `_learnBoon` NO description: the offer screen's text is authoritative and already wrap-joined. (This was `_applyContemplate`'s rule on the old offer-path chain, removed in v4.7.322.)

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

- **One capture at a time.** `_captureLines`, `_captureContemplate`, and the monster one-shot each own the single in-flight temp trigger; the `M._capturing` guard and the sequential `_boonFillNext` walk keep effects/boons/contemplate blocks from interleaving.
- **Silence backstop.** Every block has a `timeout` (1.5s effects, 3s boons, 2s contemplate) so a block that never emits an explicit terminator still flushes and never leaves a catch-all trigger armed.
- **Description authority.** Contemplate never overwrites a description the catalogue already holds (`_boonFillNext` passes none for a described boon), and `_learnBoon` never stores a description with a screen label glued on (v4.7.322).

## Generic boon latch (v4.7.241)

Sixty-odd boons own a hand-written trigger each. Reasonable when each needed bespoke parsing;
not reasonable for the next ten, which only need a flag. `M.BOON_FLAGS` maps boon NAME to a
global flag, latched from the BOON CLAIM, the combo grant (trigger 095) and -- since v4.7.350 -- every
row of the BOONS list (the generic row trigger 013), which is what the once-per-run `boon claimed`
re-latch after a reload relies on; that row latch runs **only while `ataxiaBasher.inMnemosyne`**
(v4.7.351). Cleared by `M.clearBoonFlags()` at BOTH ends of a run (run start since v4.7.351).
`(ECHO)` is stripped -- a second copy of a boon is the same boon, and a live export carries 37
of them.

**Every consumer stays gated on its flag** (user: *"we need those boons for those skills to
work"*). Without the boon the ability does not exist, and sending it is a refusal that costs a
round. Current consumers: `mnemFontOfLife` (phial disengage +1 burst), `mnemVitalisingTincture`
(the escape-ladder heal), `mnemShadowTempo` (Bard back-position priority). Flags latched with
consumers still to come: Revel in Slaughter, Morudai, Stormcleaver, Convocation, Mutated Jaws,
Wrath and Righteousness, Pyrrhic Victory, Razor Leaf.

Adding a boon consumer is now a table row, not a trigger.

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

**The FULL lock is a different event from the burst (v4.7.235).** Burst one is survivable and
SSC often wins it -- but once all four land and the game reports `(Locks: soft, hard)`, slickness
blocks salves and anorexia blocks eating, so no cure route remains that does not start with the
tattoo. `M._phialLockResponse()` fires once per lock and does three things **in this order**:
**stop swinging** (`ataxiaTemp.phialHold`, gating `ataxiaBasher_attack` -- every attack sends
`queue addclearfull`, which is exactly what threw away the escape), **`touch tree`**, then
**`touch shield`** (skipped while paralysed or already shielded: it needs a free action, and a
refusal costs the round).

**An affliction we CANNOT GET counts as present (v4.7.241).** `_phialFullLock` originally
required all four to be actively on us -- but `Coarse Flesh` grants immunity to *slickness* and
`Kevadrin's Patience` to *impatience*, so holding either made the check unreachable and the
response never fired against the fight it was written for. The lock is "every channel that can
be closed IS closed"; a channel that cannot be closed is the best version of that, not an
exception to it.

**`Font of Life` buys one more burst (v4.7.241).** The disengage exists because one tattoo
cannot answer a four-affliction lock twice; curing two halves what the lock costs to break, so
`phialDisengage` shifts from burst 2 to burst 3 while the boon is held.

Burst count lives on `ataxiaTemp.phialBursts`, PER RIPPLE (cleared in `onRipple` and
`onRunEnd`): a new ripple is a new fight and must not start pre-armed by the last boss.



## Room-shape triggers (v4.7.260 - v4.7.263)

| Trigger | Pattern | Handler | Notes |
|---|---|---|---|
| `mnemosyne/063_Room_Exits_Line` | `^You see (?:a single exit\|exits) leading .+\.$` | `MAP.onExitsLine(line)` | **Both wordings** since v4.7.260 — the singular is what a one-exit room prints, and the plural-only pattern is why a sweep stopped dead in a room whose description plainly listed an exit |
| `mnemosyne/071_Glance_Header` | `^Glancing (?:to the )?(\w+), you see:$` | `MAP.onGlance(matches[2])` | Arms a **one-shot token** the next exits line spends. A glance prints the NEIGHBOUR's block, and 063 has no notion of whose room a line describes — this is the missing half of v4.7.260's ungating |
| `mnemosyne/072_No_Obvious_Exits` | `^There are no obvious exits\.$` | `MAP.onNoExits()` | Zero is an **answer**, not silence. Records `room.exitsTextZero` and touches nothing else; spends the same glance token |
| `mnemosyne/064_Lava` | the splash + the struggle line | `M.onLava(line)` | Passes `line` since v4.7.262 so entry and tick are distinguishable — a buffered tick can be processed *after* the escape's `gmcp.Room` has already moved us. Since v4.7.318 consumes `ataxiaTemp.mnemLavaPlan` (the door a GLANCE chose) on a matching splash |
| `mnemosyne/090_Lava_Seen` | `Molten lava bubbles and churns.` (substring; one sample, 2026-09-18) | `M.onLavaSeen()` | The lava room's DESCRIPTION, seen through a GLANCE before we step. Counts only while the glance header token (071) is armed for the pending direction — the same line prints for our own room on arrival/LOOK/ql and would otherwise mark the neighbour. Decides nothing alone; `_glanceResolve` plans the pass-through door from the exits line that follows |

The first four use `triggerType: 0` with per-pattern `type: 1` (anchored perl regex); `090` is
`type: 0` (substring) because a room description wraps at the player's width and the phrase opens
the line. **Never `type: 3`** — exact-whole-line has silently killed triggers in this tree before.

Gating lives in the **module**, not the trigger: `There are no obvious exits.` occurs all over
Achaea, so `MAP.onNoExits` opens with `MAP.inMnem()` exactly as `MAP.onExitsLine` does. One gate,
in the place that is unit-testable, and the trigger stays a one-line adapter. Deliberately **not**
gated on the explorer running — the swarm moves us too, and a room's exits are worth recording
whoever walked us in.


---

## Three captures adopted from a community tracker (v4.7.278)

Reviewing MediaRes' open-source `mnemosyne_standalone.lua` turned up three lines it reads out of
blocks **we were already parsing and then discarding**.

| Trigger | Line | Handler |
|---|---|---|
| `mnemosyne/075` | `Wave progress:  <n>` | `M.onWaveProgress` |
| `mnemosyne/076` | `Remaining lives:  <n>` | `M.onLivesLeft` |
| `mnemosyne/077` | `A fulgent eddy falls still.` | `M.onBoonClaimConfirmed` |

**075 and 076 are anchorless on purpose.** Both fields sit inside an indented status block, so `^`
would depend on how the game pads them, and CLAUDE.md's own trigger guidance is to avoid `^`/`$`
unless they earn their place. Both phrases are distinctive enough that a false positive is not
credible.

**076 is the important one.** `Remaining lives` is the only run-scoped STAKE this package has ever
had: every risk decision is priced in HP, which says how close *this fight* is to going wrong, while
lives say what dying COSTS. Per-RUN, so it is cleared in `M._resetRun()` and **not** in `onRipple`
beside the affixes -- an affix is re-read from every ripple's status block, a life spent is spent
for the dive. Captured and surfaced only; wiring it to a threshold means choosing numbers, and a
wrong guess kills us in a no-flee instance.

**077 closes a real hole.** Boon flags latch at SEND time -- the claim alias passes the command
through and immediately calls `onBoonClaim`, which records history, latches the flag and posts
telemetry -- so a claim the game REFUSES still armed that boon's automation for the whole run. It
**warns rather than un-latching**, the same call made for the Arc proof-of-life: the wording is
second-hand, and if claims can also succeed silently then auto-reverting would strip real boons.
Second guard: it stays silent until that line has fired at least once, because until then "the claim
failed" and "the game does not print this to us" are the same observation, and a warning after every
claim is one the user learns to ignore. Verified from `onRipple` (a ripple boundary is well past the
4s window) rather than a timer, since a `tempTimer` id must never be serialized.

## The 2026-09-01 affix and boon rebalance (v4.7.288)

Recorded here rather than coded, because **an affix name plus a ripple threshold is real
information and an affix EFFECT is not something we were told.** Our affix layer learns from the
WADE STATUS block at runtime (`_recordAffixes` -> `M.history.library`), so every one of these will
be captured with its own sentence the first time it appears — the value of the list below is
knowing what is *coming*, and at what depth, before it does.

### New affixes, with the ripple they first appear at

| Ripple | Affix | Ripple | Affix |
|---|---|---|---|
| 20+ | Suffering of Abbadon | 70+ | Thunderous |
| 25+ | Khentimen's Enmity | 80+ | Starforged |
| 30+ | Sanctioned Wade | 85+ | Fulminous |
| 50+ | Deathmarked | 90+ | Lone Hunter |
| 65+ | Deathbound | 95+ | Starborn |
| 100+ | Sorcerous | 105+ | Pack Hunter |
| 115+ | Reckoning | | |

**Removed:** `Dreamwracked`, `Dream of Tavarius`. Nothing referenced either by name, so there is
no code to delete — but a local `history.library` keeps them, which is correct: that table is a
record of what this character has *seen*, not a list of what currently exists.

### Two mutual-exclusion facts, which bound the worst case

- `Meldscorned`, `Mindworm` and `Khentimen's Enmity` are mutually exclusive with one another.
- **All affixes that spawn new enemies on killing a denizen are mutually exclusive with one
  another.** This one matters to the sweep: `_roomHasDenizens` is trusted to mean "this room is
  finished", and `Necromantic` ("denizens may revive as mindless thralls") is the affix that makes
  that untrue. The guarantee is that we can face at most ONE such affix per ripple, so the
  repopulation rate has a ceiling.

### Changes that quietly *removed* hazards

- `Heretical` no longer reduces fire resistance; `Iconoclast` no longer increases all damage taken.
- **A manifested nightmare's attack speed has been reduced.** It is the one seeded entry in
  `ataxiaBasher.controlMobs` (v4.7.198), whose whole justification was that rage spent on its
  balance beat rage spent on our damage. That case is now weaker. Left in place — it is a
  user-owned list and the entry is still defensible — but the reasoning behind the default is no
  longer as strong as the comment there claims.
- `Apathetic` and `Torrential` are no longer dropped from the pool in late ripples.

### `BOON CONTEMPLATE` now prints a boon's category, and what unlocked it

Handled in `_parseContemplate` — see the meta-block note in `004_Parsers.lua`. We have not seen
the wording, so the parser matches the SHAPE (a short `Label: value` line while still in the meta
block) and stores anything unrecognised in `info.meta` rather than dropping it.

**Two of those labels have graduated (v4.7.298, `M._promoteMeta`).** v4.7.288 said that storing an
unknown label "under whatever the game calls it is how we find out what to call it" — and the
tracker's `BoonInfo` names three: `category`, `unlocked_by`, `conflicts_with`. **Two are promoted;
the third is deliberately not.**

- **`info.meta` is left whole.** Promotion *reads* it, never consumes it — meta is the mechanism
  that learns the *next* label, and emptying it as labels graduate removes that mechanism exactly
  when a new one appears.
- **Safe-fail.** A label we never see promotes nothing; the value stays in `meta`.
- **Sorted iteration.** Two labels map to `unlockedBy` (`Unlocked by` / `Unlocks from`) under a
  first-wins guard, so `pairs()` order would make the winner arbitrary. The keys are sorted, for
  the same reason `boonGaps` sorts.

**A label may end in `?` (v4.7.322).** The screen prints `Combo Boon?:        Yes`, and the label
pattern had no `?`, so that line started the description and was glued onto it -- the exact
corruption visible in the tracker's own catalogue (`GET /boons/export`), which is the only sample
of the wording we have. `META_KEY` (`^(%u[%w'%- ]-%??):%s+`) now serves both the label test and the
value capture. The `?` must sit directly before the colon, so prose that merely contains one is
still refused. **Yes/No labels promote to booleans** through a separate map (`META_FLAG`:
`Combo Boon?` -> `comboBoon`, and ONLY that label -- a guessed `Combo Boon` alias sorted first and
would have overridden the real one); anything but a clean yes/no stays in `meta`. **`Unset`** joins
the placeholders (Restoration's category is "Unset" in the tracker's export, and Curse of Time's
description opens with the glued line `Category:           Unset`). The same export also leaves it
**unproven which screen prints the line** (since PROVEN: CONTEMPLATE prints it -- Flameheart's block,
v4.7.326), so the guard is on both: `M._cleanOfferList` stops a meta row on the OFFER screen becoming
a fake boon (or being glued to a real one's text). The offer-screen guard stays: it costs nothing.

**Glued lines, and the capture that caught the wrong block (v4.7.322).** `M._splitGluedMeta` peels
`Label:   value` pairs off the front of a description -- the tell is two or more spaces after the
colon, which prose never has -- and `_learnBoon` refuses to store one; `M._boonDbRepair` fixes any
already stored at load. The one it found on the user's install, Deadly Finesse ("Denizen levels
increased by:  70 Denizen speed increased by:   2"), was a CONTEMPLATE capture that caught a WADE
STATUS block instead, so `_boonFillNext` now ignores a captured block with neither `Rarity:` nor
`Can echo:` -- every real contemplate opens with them.

### `Conflicts With` IS promoted now (v4.7.325) -- the v4.7.298 reasoning, and what answered it

**Superseded in v4.7.325.** A real block (the user's Careless Whisperer, 2026-09-19) showed the label
is `Conflicts With`, the list is joined with " and ", and the meta block ends in a **blank line**
before the description. So `_parseContemplate` takes a following line as the list's wrapped tail only
before that blank line and only while the whole list still splits into KNOWN boon names (a
description line never does), and `_splitBoonList` re-joins fragments into known names so
"Hammer and Anvil" is not cut in two. The same block settles the "Combo Boon?" question: its values
sit at column 21, exactly like the glued lines in the tracker's data. The v4.7.298 reasoning follows,
unchanged, because the hazard it names is real and is what the tail rule guards against.

#### Why `Conflicts with` was NOT promoted (deep review, v4.7.298)

It was, in the first cut of this change, on the strength of the schema having the field. That was
wrong, and the reasoning generalises to any future long-valued label.

**`_parseContemplate` reads RAW PHYSICAL LINES with no continuation-joining**, unlike its sibling
`_parseNamedBlock`, which exists precisely because this game wraps. Achaea wraps server-side at the
player's width (the v4.7.286/297 rule). Every label the screen has printed until now has a *short*
value — `rare`, `No`, `3` — so this never mattered. A conflicts value is **a list of boon names**,
i.e. the one shape that will wrap.

A wrapped meta value fails twice at once:

1. The stored value is silently **truncated** at the wrap, so the last name in the list is a
   fragment (`Midnight Snow's` instead of `Midnight Snow's Icy Heart`).
2. The continuation line has **no colon**, so it is not a label — the state machine flips to `desc`
   and that fragment becomes **the opening words of the description**. That description is written
   to the catalogue, and `boonGaps` only ever re-contemplates a boon whose description is
   *missing*, so a corrupted-but-present one is never revisited. The bonuses panel reads it.

And it is not detectable: the real captured block in `test_mnemosyne.lua`'s own fixture wraps its
description mid-sentence with a **flush-left** continuation line, so there is no indentation to
tell a wrapped meta tail from the description's first line.

Promoting a label we have never read, whose value is the shape most likely to wrap, **buys nothing
today** — no line means no value — and risks the catalogue's most irreplaceable field. `info.meta`
records it verbatim if it ever appears, which is exactly what v4.7.288 built `meta` for. The
storage and transport for `conflictsWith` remain (an imported catalogue can carry one), so only the
unverified *parse* is gone.

The two that stay are promoted because their values **provably cannot wrap** — a category is one
word, an unlocking boon is one name (longest in the seed ~30 chars, against the ~115-column wrap
seen in the fixture) — and `META_VALUE_MAX` (60) **enforces** that rather than assuming it: a value
long enough to have wrapped is refused and left in `meta`. `META_PLACEHOLDER` separately refuses
`None`/`N/A`/`-`/`nothing`, so a game rendering "no value" as a word cannot become a boon named
`None` that fill-never-blank then locks in ahead of the real answer.

## Boon churn and the registry (audited 2026-09-02; BOTH halves wired as of v4.7.351)

Boons are added and removed every season, and the cost of that lands here. `M.BOON_FLAGS`
(`004_Parsers`) exists to absorb it -- a NAME -> FLAG table so a new boon needs a row rather than a
trigger:

| Half | State |
|---|---|
| `M.latchBoonFlag(name)` | the claim path, the combo grant, and the BOONS row (trigger 013, v4.7.350) -- the row latch **in the tower only** (v4.7.351) |
| `M.clearBoonFlags()` | run END (inside `M.onRunEnd()`) and run START (trigger 001, v4.7.351) |

**Adding a boon to `BOON_FLAGS` no longer needs its own row trigger** (v4.7.350): before, the row
trigger recorded ownership and never latched, so a boon came back after a reimport only if it ALSO had
a hand-written trigger -- 15 of the 20 did not, Dead Breath and Deathtempest among them. A test feeds
a row for every name in the table and requires every flag back. Run START used to clear only a
hand-written list missing 13 of the 20. Status below is the 2026-09-02 audit, kept for history.

So 13 boons use the registry, ~29 remain hand-wired across four files each, and three flags are
asymmetric as a result: `dwTimequake` / `dwHeraldInfirmity` (run-end reset, no run-start) and
`mnemIcyHeart` (run-start, no run-end). Run-start matters more -- trigger `001` fires on the wade
line ungated, while `onRunEnd` waits on its confirmation.

Four boons we automate have no catalogue entry: `Kai Unleashed`, `Daemon Jaws`, `Necrotic Aura`,
`Icy Heart`.

**Nothing detects a removal.** A deleted boon's trigger stays live, matching a line the game can no
longer print, and its documentation stays true-looking. Reaper is the worked example (v4.7.288).

## Reviewed and NOT adopted

* **`M.MOBTYPES`** -- their 80+ wave announcement lines mapped to a monster roster and boss. The one
  significant thing still missing, because it names the ROSTER, which our generic spawn-sentence
  parse (`MOB_VERBS`) cannot derive: it would let the SLC denizen parry patterns, `controlMobs` and
  the swarm thresholds pre-arm on arrival instead of learning on the first hit. Not taken because it
  is a data import we do not have the data for, and a name table is the shape our own rule
  (v4.7.264) says goes stale on the entry after the last one someone added.
* **Contemplating every offered slot BEFORE posting.** We moved off that in v4.7.91; the enrichment
  chain raced the next ripple for the single `_capturing` slot and dropped whole reports.
  `M._contemplateNext` was dead code from then and was removed in v4.7.322. **Adopted differently in
  v4.7.324:** every offered slot IS contemplated now, but only AFTER the offer has posted, never
  taking the slot from another capture, and stopping at GO!. `mnem status` still advertises
  "Contemplate: ON", which describes nothing on the offer path.
