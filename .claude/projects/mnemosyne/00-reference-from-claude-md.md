# Mnemosyne run tracker: the reference that was in CLAUDE.md

> Moved verbatim from `CLAUDE.md` on 2026-11-13 (`docs/adrs/002-knowledge-delivery-tiers.md`). Until then every session loaded this text. It is not yet reconciled with the other documents of this subject: where they disagree, check the code or the game source, then correct the wrong one.

### Mnemosyne Run Tracker (`ataxia.mnemosyne`)

Reports Mnemosyne (tides-of-memory) run progress to an external REST tracker as you play. HTTP POST with the token in the JSON body (no auth header). This is the *telemetry* system — distinct from the in-game Mnemosyne bashing area no-flee rules.

**Full documentation**: See the `.claude/projects/mnemosyne/` doc set (architecture, reporting/endpoints, parsing & triggers, ripple map, commands, local history, auto-explorer) and `memory/mnemosyne.md` (concise index).

**Namespace:** `ataxia.mnemosyne`. **Aliases:** `mnem` (+ `mnemosyne`), plus an intercept of `BOON CLAIM <name>`.

**Key files:** `scripts/.../mnemosyne/001_HTTP_Client.lua` (serial POST queue + error recovery), `002_Reporter_API.lua` (per-endpoint fns + run state), `003_Commands.lua` (`mnem` dispatch), `004_Parsers.lua` (effects/boons parsers, monster buffering), `005_Ripple_Map.lua` + `006_Ripple_Map_Window.lua` (per-ripple room mini-map), `007_History.lua` (local run history + reports), `008_Explorer.lua` (auto-sweep the 4×4), `009_Swarm_Tactics.lua` (multi-mob pull & funnel — see below). Triggers `triggers/.../mnemosyne/001-021` (incl. `006_Go` → `exploreOnGo` + `swarm.onGo`, `013_Boons_List_Row`, boon-flag triggers `014_Aspect_Of_Kkractle`/`015_Hot_Springs`/`018_Hammer_And_Anvil`/`019_Bladed_Reflexes`/`020_Sleuth`/`021_Roll_Hide`, `016_Run_Pause`, `017_Splinterbark`). Aliases `aliases/.../mnemosyne/001-002`.

**Flow:** `GO!` → capture the mob spawn line (the line directly above `GO!`, positional — spawn wording varies per mob) → auto `WADE STATUS` → `/ripple_level`, `/boss` (from the `Objective: defeat <boss>` line), `/effects`; buffered monsters flush after `/ripple_level`. Serial queue enforces ordering (ripple_level first; boons_offered before boons_selected). `_auto()` gates run-start/GO/ripple; `_inRun()` gates monsters/effects/boons/boss/death so generic phrases can't report outside a tracked run. **`/boons_offered` posts once the RIPPLE IS CURRENT** (v4.7.279; it posted IMMEDIATELY from v4.7.91 until then) with the offer-screen name+description — it is no longer gated behind the slow per-boon `BOON CONTEMPLATE` enrichment chain, which raced the next ripple's captures for the single `_capturing` slot and, on a lost race, stalled and silently dropped the entire boon report (rarity/echoes are still learned locally). The line-capture (`_captureLines`) **force-finishes** a wedged prior capture rather than dropping the new one (v4.7.93). **`/boons_offered` also carries `class` and `race`** (v4.7.220, tracker-side request) -- top-level optional strings on `BoonsOfferedRequest`, NOT members of `BoonInfo` where the names suggest; verified against the live schema at `http://104.128.56.238:8000/openapi.json`, which is how to settle any question about this API's shape rather than inferring from prose. `M._charInfo()` reads `gmcp.Char.Status.class`/`.race` and makes two deliberate calls: **class is normalised** (the basher's `:title():gsub(" Lady",""):gsub(" Lord","")` -- Lord/Lady is a gender suffix on one class and leaving them distinct halves every per-class count) while **race is passed through raw** (no known distortion, and normalising against an unverified vocabulary corrupts data more quietly than leaving it alone); and a missing/empty read **omits the key** rather than sending `"unknown"`, which would become its own cohort in the queries. Both branches of `_reportBoonsOfferedEnriched` route through `reportBoonsOffered`, so the tagging lands on the real path. **Pause/resume (v4.7.88):** `WHISPER … beseech that it grow still` pauses the run without ending it server-side; the next wade **resumes via `/run_exists`** (no new `/run_start`), and `M.run.paused` is cleared unconditionally on a confirmed run-end.

**Commands:** `mnem status|token <t>|on|off|contemplate|debug|quiet [on|off]|test|queue [clear]|start|end|check|ripple <n>|boss <name>|monsters <text>|death [killer]|map [on|off|status]|boons|bonuses [on|off]|boonfill [gaps|all|<n>]|affixes|library|explore [on|off|status]|cards [on|off|maran <hp%>|seasone <hp%>|matic <n>]`. Also `ataxia setup reporting`.

**Persistence:** `ataxia.settings.reporting` (`enabled`, `contemplate`, `token`, `url`, `mapEnabled`, `quiet`) — saved inside the main `ataxia` file / `_ataxia_backup.ataxia`. Run state is in-memory (re-synced via `/run_exists` on load) — **true only since v4.7.299**; see the persistence section below. The **HTTP queue is persisted too, and is RESUMED on load** (v4.7.336): `M._resumeQueue` clears a restored `_busy` and replays whatever was unsent, in order, at-least-once -- a saved `_busy = true` had silently wedged every report for about nine runs. `mnem status` shows the queue; `mnem queue [clear]` lists or drops it. The **local history** (`ataxia.mnemosyne.history`) is the one thing on its own disk file, `<profile>/mnemosyne_history.lua`.

**DEAD BREATH -> BELCH AS A ROOM ATTACK (v4.7.337, user-directed, `basher/014_Dead_Breath.lua`).** The boon ("Your belch will now cause significant damage to all denizens in the location, but drains 10% of your mana in the process") turns BELCH (ABADMIN 136: Room, 4.00s of EQUILIBRIUM, 200 mana) into an AoE — a live log shows one belch killing three denizens (2121 / 15372 / 18000 asphyxiation). It is an EQ rider, so `ataxiaBasher_deadBreathBelch(sp)` joins the chain beside Death Stare rather than replacing the round (the combo still spends balance). Gates: the boon flag; **2+ denizens** (user's rule — a room attack earns its mana in a crowd); shield first; the ability's own cooldown; and a mana test that reads the REAL cost, 200 flat **plus the boon's 10% of maximum**, refusing to drop below `ataxiaBasher.deadBreathManaFloor` (default 50) because mana is the curing pool too. **The refusal is a ROOM STATE, not a cooldown**: "...cough and sputter as you inhale the noxious air that surrounds you" is the gas we just laid, so it is held per ROOM (trigger 779) and cleared by moving. The boon is self-proving — "Your rotten breath befouls the air" cannot print without it, so trigger 778 latches `mnemDeadBreath` as well as stamping the send.

**DEATHTEMPEST -> SOULSTORM ONCE PER DENIZEN (v4.7.338, user: "We should use this once" / "If we have the boon deathtempest").** SOULSTORM (ABADMIN 142, eq rider, cost "greatly reduced" against a denizen) PROFANES the soul: +10% from necromancy, evileye and Infernal weaponmastery. That is a DEBUFF, so a second cast buys nothing — tracked by TARGET ID (unique per creature, never reused) and marked by the game's line ("...engulfing <mob> in a profane soulstorm"), which is stamped against the target we SENT for, not the one in front of us when it arrives. **It does NOT stand down for the belch** (corrected v4.7.343, user: "belch doesnt matter ... They are two seperate attacks") -- v4.7.338 gated it on the belch from my own inference about one equilibrium, while the ability text says the storm's eq and essence costs are "greatly reduced" against a denizen; a round carries `belch;soulstorm <t>;<swing>`. Unconfirmed storms retry after 6s; the profaned set is dropped with the room. The line prints with or without the boon, so it does NOT latch `mnemDeathtempest` — the claim does.

**Run end:** `/run_end` fires on `"The Mnemosyne releases its hold, weaving N shimmering threads into your possession."` — but only after a **confirmation** (`onRunEndMaybe` waits ~2s for `"You just received message #N from Achaea."`), because that reward line also prints on a mid-run message re-read. The Mnemosyne boon flags (`bardWarmarch` / `bmShatteredStar` / `magiKkractle` / `magiHotSprings` / `mnemHammerAnvil` / `bmBladedReflexes` / `mnemSleuth` / `mnemRollHide` / `mnemBloodscent` / `mnemKaiUnleashed` / `mnemSenselessFlurry` / `mnemSpiritRend` / `mnemSharpMind` / `mnemObligateCarnivore` / `mnemHealingMetabolism` / `mnemBerserkersEdge` / `mnemDeadlyFlourish` / `mnemDeathStare` / `mnemSearingLight` / `psionPanoply` / `dragonMightSycaerunax` / `dragonRampage` / `dragonSweep` / `dragonOrganPiercer` / `dragonSparkExtant` / `dragonKrenindalan` / `mnemTerrorSkies` / `dwFlashforward` / `infArmyOfDead` / `infDaemonJaws` / `infIndiscriminate` / `infNecroticAura` / `infFuryOfAges` / `mnemWintersHeart` / `mnemResourceful` / `mnemFalconersTactics` / `mnemHomebound` / `mnemHammerAndNail` — Hammer and Anvil is class-agnostic: attacks bypass denizen shields, so `336_Mob_Shielded` skips the raze path AND the shield-swap while it's up; Bladed Reflexes makes the BM basher keep `SHIN AUGMENT <n>` up (spend `ataxiaBasher.bmAugmentAmount`, default **20**, a provisional middle rather than a computed optimum — the duration SCALES with the shin spent, ~10s to ~1.5min, and is explicitly **NOT** one shin per second, so **the curve is unknown** and `bash shinprobe` (basher/012) measures it from live play. v4.7.269 recorded 1:1 and built an uptime table on it; **that is retracted**. What holds without the curve: **4s to activate in all cases**, and **cooldown equal to the duration it was up for** — so uptime can never exceed 50% however much is spent, and a short augment pays proportionally more of the fixed 4s tax. The cooldown is honoured because a 7s attempt-hold against a 90s cooldown re-sent a refused command repeatedly — observed **five times in 0.45s**, since `shin augment` costs no balance and therefore EXECUTES on every re-queue of the round. **All five lines of the cycle are captured** (`highlighting/050-054`): channel accepted, already-channelling REFUSAL, cover-starts, cover-ENDS and **cooldown-OVER** — so v4.7.271 stopped predicting the cooldown and waits for the game to announce it, keeping the derived wait only as a backstop for a missed line (a flag cleared solely by a confirmation livelocks the moment the confirmation cannot arrive). **A BACKSTOP MUST NOT OVERRULE THE THING IT BACKS UP (v4.7.280)** -- the general form of the rule, after the same fault appeared with the sign flipped. Live: `(BR): augment ended after 1.2s on 20 shin` printed immediately after the cover-STARTS line, because 052 opens the cycle at once and the next assembled round polls `bodyaugment`, GMCP has not caught up, and the poll closes a cycle one second old -- junk sample, junk cooldown. The poll must now PROVE it can observe the defence (`ataxiaTemp.bmAugmentSeenUp`, set only when it actually reads it up) before it may act on not observing it; if GMCP never reports this defence for the Shindo augment the poll can never close a cycle, which is correct because line 053 is captured. (`bodyaugment` is a real key, but the place we have watched it work is Depthswalker's `intone mainaas` -- after this change that no longer matters.) THREE EXISTING TESTS WERE ASSERTING THE BUG, driving the poll to close a cycle it had never seen open. Anyone who bashed on v4.7.270-279 should `bash shinprobe clear`: every augment in that window recorded a junk short sample. Where a LINE and a POLL cover the same edge the poll can UNDO the line: GMCP still reported `bodyaugment` for a prompt after the dissipate line and the poll read it as a fresh cover, recording a near-zero sample over the real cooldown — hence a 2s grace, sized so it cannot hide a real cycle. First end-to-end timing: **cooldown 3.0s**, **activation 3.66s** against the stated 4s. The activation is settled and nothing else is — an older log has a 3-shin augment lasting ~2.0s with a ~6s recovery, which fits neither a ~10s floor nor cooldown-equals-duration, so the ABLATIVE hypothesis in the class doc is now testable by the probe's bracketed durations. **The change does not depend on resolving it**, which is the point of listening rather than computing) — 20% DR while the `bodyaugment` defence holds, and **deliberately exempt from the shin floor** (user rule) since 20% DR held continuously beats banking a panic button; Sleuth arms the swarm module's fullsense-on-GO recon; Roll Hide arms the swarm panic tumble; Kai Unleashed makes the Shikudo basher PREPEND `KAI CHOKE <target>` to the round's combo in RAIN form when 2+ denizens share the room (the boon bursts magic damage on ALL of them — live captures 8472 → **25560 + 17931** magical (it SCALES, and the leading hypothesis was the Reaper stack -- **Reaper was DELETED from the game on 2026-09-01**, so what remains is the coalescence empowerment; one burst killed the primary outright); per AB Kaichoke the ability spends 4s of EQUILIBRIUM — idle during balance combos, so both land — and against a DENIZEN consumes NO kai, only 50 mana, hence a 250-mana floor instead of a kai gate; the 30s cooldown starts from the CONFIRMED burst line "Your surroundings ripple like a lake's surface struck..." via trigger 031 → `ataxiaBasher_kaiUnleashedBurst` into `ataxiaTemp.kaiUnleashedAt`, with a 6s retry guard (`kaiChokePendingAt`) so an eaten choke re-fires instead of locking the burst out; shield-break rounds skip it — `ataxiaBasher_kaiUnleashedChoke`, basher/002); Senseless Flurry (balance 30% faster while the numbness defence is up) makes the Shikudo basher keep `NUMB` up in Rain form (AB Numbness 894: self-only, 3s eq, defers damage −40% into one later blow; defence-gated on GMCP `ataxia.defences.numbness` + 5s attempt-hold, fires even on shielded rounds; ONE eq spender per round — the choke outranks the numb refresh; **CROWD-GATED** (review HIGH): numb pins HP while damage defers, blinding the rate watchdog/danger levels/escape ladder until the lump lands as one −40% blow — so never numb at >= the swarm threshold or while a swarm tactic runs — `ataxiaBasher_senselessFlurryNumb`); Sharp Mind ("critical strikes restore 5% of your mana", 15% echoed -- and the Monk round strikes three times a balance) turns the Monk TRANSMUTE gap-filler into a plain top-up in the tower: fire at HP <= `sharpmindat` (90) with or without sip balance, still to `transmuteto` and never past the `manause` floor (v4.7.320, registry flag, tower-gated because the registry does not clear at run start; AB Transmute 893: MANA into health, requires balance but does not consume it, so it rides the round once per swing); Panoply makes the Psion basher swap `weave deathblow` → `weave flurry` (AB Flurry 2704: 2.6s balance; the boon scales its damage 60–200% per strike landed — straight verb swap, cleave keeps shield-break, psi shatter keeps the transcendence slot — `ataxiaBasher_psionBashing`); Might of Sycaerunax (dragon: BLAST +25% damage AND the breath weapon PERSISTS through use — AB Blast: 4s eq, strips shield/lyre, "Requires summoned breath") makes `ataxiaBasher_dragonBashing` drop the `;summon <ele>` from both the blast weave and the shielded reblast while it's up (trigger 035 + claim intercept; breath-down still summons once); Draconic Rampage (dragon: TRAMPLE — AB 1564, room, 2.75s balance — deals a large cutting nuke to ALL denizens on a 40s proc) makes the dragon basher spend the balance swing on `trample` at 2+ denizens (Mnemosyne `_denizenCount`, the Kai Choke gate) whenever the proc is ready — send-side 40s stamp + the v4.7.129 in-flight hold, shield-break rounds skip it, the eq blast weave still rides beside it (`ataxiaBasher_dragonRampagePick`, trigger 036 + claim intercept); Flashforward (Depthswalker: +20% damage while the `chrono blur` defence is up) makes the DW basher keep CHRONO BLUR up as an EQUILIBRIUM rider paid in AGE (not the word balance, so it never competes with nakail/the Terminus buffs) -- defence-gated on GMCP `blur`, 8s attempt-hold, capped by `ataxiaBasher.dwAgeCap` (400) so bashing cannot price out the chrono kit, and it rides shielded rounds too (`ataxiaBasher_dwFlashforward`, trigger 038 + claim intercept); Army of the Dead (Infernal: `summon hands of the grave` also damages every denizen in the room) makes the Infernal basher cast it at 2+ denizens ahead of the swing, on a provisional 20s stamp since the real cooldown is uncaptured (`ataxiaBasher_infGravehands`, trigger 039); Daemon Jaws (hyena maul cooldown -66%) shrinks the maul SAFETY timer 30s -> ~10.2s -- the game already sends its ready-line sooner, but basher/005 previously had NO backstop at all, so a missed line stranded the maul forever (trigger 040); Indiscriminate (ARC becomes denizen-effective) makes **every KNIGHT** basher swing the UNTARGETED room-wide `arc` INSTEAD of its single-target attack at **3+** denizens (`ataxiaBasher_knightArc`, `ataxiaBasher.arcAt`, trigger 041). Arc is **Weaponmastery**, so Infernal, Paladin, Runewarden and Unnamable all have it across all four specs — it shipped Infernal-only in v4.7.145 only because that was the class in the tower when the boon was captured, leaving three knights holding a dead boon (corrected v4.7.244, user-directed). The threshold is 3 rather than 2 because arc spends 4.75s of balance against a ~2s dsl — 2.375 normal swings — so at TWO denizens it lands 2 hits where focused swinging lands ~2.4; three is where it starts paying, and the margin widens per extra mob. The legacy `infArcAt` key is still read as a fallback (neither key is ever written, so the default change needs no migration). Its fire lines are captured (v4.7.245, `highlighting/046`, chartreuse bold): `You swing your weapon in a wide arc to hit everyone within your reach.` and `Your weapon carves through the air with deadly accuracy, slicing open all it touches as its keen edge passes by.` -- **only the FIRST is used as confirmation**, because "its keen edge" is edged-weapon wording a blunt spec will not print, and treating the effect line as proof would warn every blunt knight that arc is broken (rule: when a line names a weapon PROPERTY, assume the other specs word it differently until seen). It feeds a PROOF OF LIFE: arc has no cooldown and no in-flight replay, so nothing knew whether it had ever fired -- three attempts with no fire line warns once, counting ATTEMPTS not calls (a 4s gate collapses each round's 0.3s rebuilds into one, the phantom-stamp trap), and it WARNS rather than disabling. **For Runewarden a Thunderclap BISECT outranks it** — both are crowd-gated BALANCE swaps so only one can land, and bisect buys the same room-wide reach for the price of an ordinary swing. The boon FLAG keeps its legacy `infIndiscriminate` name deliberately: it is reset in three places and a missed rename would leave arc armed outside the tower; Necrotic Aura (attacks inhibit denizen healing while the DEATHAURA defence is up) makes the Infernal basher keep that defence raised — defence-gated, 10s attempt-hold, prefixed to every round incl. shielded (`ataxiaBasher_infDeathaura`, trigger 042), and its proc line records `inhibit` on the denizen (trigger `denizen_attacks_misc_lines/024`, the same state Monk Ripplestrike applies); Fury of Ages (FURY becomes near-permanent: +8 strength and 20% faster balance for 45 of every 60 minutes, but QUADRUPLED endurance) makes the basher hold `fury on` while EP >= 60% and drop it under 25%, with a 30s floor between toggles since each activation may cost 500 willpower, and a run-end `fury off` so it never drains EP after the boon expires (`ataxiaBasher_infFury`, trigger 043). **NOT INFERNAL-ONLY since v4.7.285** -- fury is a RUNEWARDEN ability too (the SnB combos in `snb/003`/`snb/004` have sent `fury on` beside `falcon slay` forever, and a falcon is a Runewarden's bird), but the helper was reachable only from `ataxiaBasher_infernalBashing`: the same one-class-at-a-time gap as Arc (v4.7.244) and the falcon/hyena redeploy (v4.7.284). Now prefixed to EVERY Runewarden branch including the shielded one, as the Infernal prefixes its `aura` -- fury costs willpower, not balance or equilibrium. **The OFF switch is the point as much as the on**: turning it on for a class with nothing to turn it off would strand a Runewarden on quadrupled endurance. **`M._furyCheck()` asserts it at EVERY wade entry** (explorer 008, beside `_wearArmour`/`_bardPerformanceCheck`, both per-ripple entry points) because the boon screen is a gap in which fury lapses -- and it deliberately does NOT gate on `ataxiaTemp.infFuryOn`, since our flag is the thing being verified and gating on it would make the check believe itself. **The state is no longer a guess**: `Your eyes rage with fury.` and `You're already raged with fury!` (`highlighting/055-056`) both resolve to the same fact, so one handler takes both -- the refusal is a free state probe, which is what makes the unconditional send at every descent cheap. Only the ON edge is confirmed; no fury-OFF line has been seen. Every `inf*` name is KEPT deliberately (the `infIndiscriminate` call again): the flag is reset in three places and a missed rename would leave fury armed outside the tower; Winter's Heart (DEEPFREEZE works on denizens and deals cold to ALL of them in the room) casts it at 2+ denizens — class-agnostic on purpose, since the Bracers of Frost grant deepfreeze outside Elementalism, and it is an EQUILIBRIUM cast so it rides FREE beside a balance swing while taking the eq slot for Magi (`ataxiaBasher_winterDeepfreeze`, `deepfreezeAt`, trigger 044); Resourceful (-10% endurance/willpower costs; each denizen kill restores 10% of the CLASS RESOURCE — life essence for Infernal) held together with Army of the Dead makes Tyranny effectively free, so its crowd gate drops to 1 denizen (gravehands in every occupied room) and its essence floor 20% → 10% (trigger 045); Falconer's Tactics (falcon rake cd -66%, the Runewarden twin of Daemon Jaws) shrinks the missed-line safety timer 30s → ~10.2s (trigger 046); Homebound (returning to your raido cures + full-heals, but not in the same location) makes the explorer `sketch raido on ground` in the HOLDING room right before the descent, once per ripple (trigger 047); Hammer and NAIL — **not** Anvil — (attacks splash to a second denizen while a sowulu rune is present) makes the Runewarden basher `sketch sowulu on ground` at 2+ denizens, once per room, on the free queue so it costs no balance (`ataxiaBasher_rwSowulu`, `sowuluAt`, trigger 048). **URUZ** is its non-boon sibling (v4.7.248, user-directed): `sketch uruz on ground` at **3+** denizens (`ataxiaBasher.uruzAt`), once per room, laid FIRST in the round -- ahead of sowulu, the battlerage and the swing. The rune is HP REGEN, corroborated in-tree by the rune identification tables (triggers 738/740, totem/001, "like a lightning bolt"). Three deliberate divergences from sowulu: not boon-gated (base Runelore), **rides a SHIELDED round** (sowulu skips one because splash is pointless while razing -- uruz heals US, so the target's shield is irrelevant, and a crowded room opening on a raze is exactly when we want it down), and its threshold is a DEFAULT not a clamped rule (unlike bisect's floor of 2, there is no count at which regeneration is *wrong*, only counts where it is not worth the prefix); Bloodscent auto-recons every ripple entry ("You sense <mob> (#id) at <room>." per denizen — trigger 028 parses the rows into `swarm.recon` with per-room counts and a crowded-room callout, the parsed format Sleuth's raw capture waited for); **Reaper, Reaped and Reaver were DELETED FROM THE GAME on 2026-09-01 (v4.7.288)** -- Reaper had a whole subsystem here (triggers 023/024, `M.onReaperTithe`, `M.reaperOnWade`, `ataxiaTemp.reaperKills`, the `mnemReaper` flag) counting the per-kill tithe line into a running +N%, and all of it is gone rather than left inert: a trigger whose line can no longer be printed stays live, costs a match on every line of output, and reads as working code to the next person) and `mnemRageFuelled` — **Rage-Fuelled** (v4.7.179: "When slaying a denizen, your next battlerage attack will cost no resource") banks ONE free battlerage per kill. It is a STATE, not a timer: `ataxiaTemp.brFreeCharge` is armed by the kill trigger (`340_Slain`, already denizen-gated on a numeric target so it cannot arm off a player kill) and sits until a battlerage actually goes out. The entire payoff routes through **`ataxiaBasher_rageAfford`** — the single gate all **37** rotation affordability checks already use — so one bypass lands the boon on EVERY class at once, and it short-circuits the **rage floor** too (a free ability has no surplus to preserve). **Culling reap needs it explicitly** (`rage >= 36 or ataxiaBasher_brFree()`, 7 sites) because it deliberately bypasses `rageAfford` to stay floor-exempt, and a free AoE execute is the best possible use of a charge. The charge is spent by **`ataxiaBasher_brSent()`**, which consolidated the six scattered `ataxiaTemp.brGlobalReadyAt = ... + 1` assignments — arming the ~1s global cooldown and spending the charge MUST stay in lockstep, and a seventh call site remembering one but forgetting the other would leak a free battlerage silently. Spent on SEND rather than a confirmed fire line because several battlerage abilities have no fire line at all; the error directions are asymmetric (believing it spent costs one missed cast and self-corrects next kill, believing it banked costs a rejected command)) and `mnemStormcleaver` -- **Stormcleaver** (v4.7.246: "Your bisect attack now executes denizens with less than 20% of their maximum health") which switches on a clause bisect ALREADY HAD: AB 3107's "if your target is an ADVENTURER and at 20% of their health or lower ... slain outright" was always present and always worthless in PvE, so `ataxiaBasher_rwBisect` carried a note saying there was no low-hp branch. **The two bisect boons pull OPPOSITE ways and are independent** -- Thunderclap wants 2+ denizens (splash), Stormcleaver wants ONE under the threshold (a kill has nothing to splash) -- so the old `if not mnemThunderclap` head-gate had to go or Stormcleaver would have been silently inert when held alone. The execute is checked BEFORE the crowd gate, is not crowd-gated itself, and outranks Arc (both spend balance; a guaranteed kill beats spread damage, and it denies self-healing denizens the chance to climb back out). `bisectTargetHp()` prefers `gmcp.IRE.Target.Info.hpperc` and falls back to denizen state; **a missing reading means NO execute** -- the opposite default from the legend deck's `targetNearlyDead`, because there a wrong guess withholds a card while here it spends 4s of balance on a finisher that cannot finish. `<=` on `ataxiaBasher.bisectExecuteAt` (20): the boon says "less than 20%" and the AB "at 20% or lower", and since `hpperc` is LAST-PROMPT data on a mob we are hitting, the real figure when the cutting damage lands is already lower -- so the boundary errs safely. Trigger `mnemosyne/062` -- and `mnemThunderclap` -- **Thunderclap** (v4.7.181: "Your bisect ability now strikes a third time, dealing bonus electric damage to all denizens in your location") turns BISECT from a single-target finisher into a ROOM hit, so `ataxiaBasher_rwBisect` (basher/002, `ataxiaBasher.bisectAt` default 2) swings it INSTEAD of the normal attack at 2+ denizens. Crowd-gated because of the AoE, with the balance cost only setting where the crossover falls: over a 4s window combination lands 2 swings on ONE mob while bisect lands 1 empowered strike on the target PLUS electric on EVERY denizen -- twice the balance for room-wide coverage. At 1 denizen there is nothing to splash to (the only case the gate excludes); from 2 upward bisect reaches what combination cannot, widening with each extra mob, and in the tower the objective is CLEARING THE ROOM rather than killing one thing fastest. `ataxiaBasher.bisectAt` tunes it upward only: **2 is a clamped floor, not a default** (user rule) -- at one denizen the third strike has nothing to splash to, so no configuration makes it correct. (The Infernal Arc trade exactly.) It REPLACES the swing (both spend balance) but the free falcon rake still rides. Two AB facts deliberately absent from the logic: the "slain outright at <=20% health" execute is **adventurers only** (no PvE value), and bisect bypasses rebounding/reflections while leaving them intact, so it needs and gives no raze handling -- a denizen shield must still be broken first. **Unmanaged prerequisite (user decision):** bisect needs an edged runeblade with the HUGALAZ rune on the blade; nothing in the package knows hugalaz and the blade-sketch syntax was never captured, so keeping it on the weapon is the user's setup. Fire line captured live: "Lightning follows the path of <weapon> as you sweep it at <target>, a clap of thunder heralding your strike." (highlighting/035, chartreuse bold -- the attack-landing colour)) are cleared only on the confirmed end (and reset on run start). **Boss tactics** live beside the affix safeties in 004_Parsers: `reserveTreeForBoss` (`TREE_RESERVE_BOSSES`, extensible) holds `curing tree off` from a reserve-boss's `Objective:` line; Seasone's phial burst (trigger 032) **BANKS** the tattoo rather than spending it (v4.7.213: burst one is survivable and SSC often wins it, so spending there left nothing for burst two, which killed us) and releases the reserve when armed. Three later corrections, all from death logs: **burst two DISENGAGES** (v4.7.215 — rationing one charge only ever buys one extra burst; `ataxia.mnemosyne.phialDisengage`, default 2, +1 while `mnemFontOfLife` is held since a tattoo that cures two halves what the lock costs); the **FULL lock is a different event** and fires `M._phialLockResponse()` (v4.7.235 — stop swinging via `ataxiaTemp.phialHold`, `touch tree`, `touch shield`, in that order because every attack sends `queue addclearfull` and would throw the rest away; shield skipped while paralysed or already up); and **an affliction we are IMMUNE to counts as present** (v4.7.241 — `Coarse Flesh` grants slickness immunity and `Kevadrin's Patience` impatience, so requiring all four actively-on-us made the response unreachable against the exact fight it was written for) — telemetry-independent like Splinterbark, whose taint always wins (never touch a tainted tree); released on ripple change/run end. `startRun` also self-recovers: its `onError` resets `run.active` if `/run_start` 500s or times out. All events auto-report; manual `mnem` overrides remain.

**THE OFFER'S RIPPLE IS DECIDED BY TIMING, NOT BY A FIELD (v4.7.279).** `BoonsOfferedRequest` is `token`/`offered`/`class`/`race` and nothing else, so the server files an offer under whatever our last `/ripple_level` said. We sent `wade status` **on `GO!` and nowhere else**, i.e. only at the START of a wave -- so an offer posted at the boon screen landed under the ripple just FINISHED, and the FIRST offer of a run landed with no `/ripple_level` ever sent at all (reported by the tracker's author as "a ripple late" and "not sending the boons that are initially offered"; the "cached" complaint is the same bug seen from the other side -- an offer filed under the previous ripple looks like data the tracker already holds). `M._offerAfterRipple` now stashes the list, sends `wade status`, and posts when `onRipple` has reported -- the flush sits AFTER `M.setRipple(n)` because the queue is serial and order on the wire is the whole fix. **Bounded at `OFFER_RIPPLE_WAIT` (3s)**: v4.7.91 removed a deferral that could stall and silently drop the entire report, so this one posts regardless. Break-back note worth keeping: reverting it passed all five new tests, because every one called `_offerAfterRipple` directly and none crossed the seam the bug lived in -- **a seam the suite never crosses is a seam it cannot defend** (v4.7.260 again). Also found: `M._contemplateNext` is DEAD CODE (removed in v4.7.322) and `mnem status` still advertises "Contemplate: ON" for offers it no longer affects.

**THE WADE STATUS BLOCK CARRIES TWO NUMBERS WE DISCARDED (v4.7.278, triggers `mnemosyne/075`+`076`).** `Wave progress: <n>` and **`Remaining lives: <n>`** -- both sit in the block we already parse for affixes. **Lives is the only run-scoped STAKE this package has ever had**: every risk decision is priced in HP (escape ladder 35%, panic tumble, boss-chase guard, forced disengage), and HP says how close THIS FIGHT is to going wrong while lives say what dying COSTS -- at three a death is a setback, at one it ends the run and every boon in it. Captured on `M.run.lives`, shown by `mnem status`, echoed only when it CHANGES, and **deliberately not wired into any threshold**: that means choosing numbers, and a wrong guess kills us in a no-flee instance. Cleared in `M._resetRun()` and NOT in `onRipple` -- an affix is re-read every ripple, a life spent is spent for the dive.

**A BOON CLAIM IS NOT CONFIRMED BY SENDING IT (v4.7.278, trigger `mnemosyne/077`).** `A fulgent eddy falls still.` is the game's acceptance. Our flags latch at SEND time -- the claim alias passes the command through then calls `onBoonClaim`, which records history, latches the flag and posts telemetry -- so a REFUSED claim armed that boon's automation for the whole run (a Bard on paean for a Warmarch it never got). It **WARNS rather than un-latching**, like the Arc proof-of-life: the wording is second-hand (adopted from a community tracker, never seen in our own logs), and if claims can succeed silently then auto-reverting would strip REAL boons. Second guard: **silent until that line has fired at least once**, since until then "the claim failed" and "the game does not print this to us" are indistinguishable, and a warning after every claim is one the user learns to ignore. Polled from `onRipple`, never timered.

**Class/race on `/boons_offered` were already correct** and are now VISIBLE: `mnem status` prints what would be sent (`unread` in red when `gmcp.Char.Status` cannot be read), because a missing read OMITS the key rather than sending `"unknown"` -- right for the data, previously invisible. Schema re-verified 2026-08-20.

**THE WHOLE SCHEMA, INCLUDING THE OPTIONAL HALF (v4.7.298, re-verified against
`http://104.128.56.238:8000/openapi.json` on 2026-09-08).** Four things the API had been accepting
the entire time. **(1) `/run_pause` existed and was NEVER CALLED** -- v4.7.88 taught the client half
of a pause (`M.run.paused`, so the next wade resumes via `/run_exists` instead of minting a fresh
`public_id`) and nothing ever went on the wire, so a deliberate pause looked to the tracker exactly
like a player who stopped mid-dive. `M.reportRunPause()`, gated on `_inRun()`, fire-and-forget
(the flag is set BEFORE the POST, so a failure costs a marker and nothing else -- hence no
`onError` undo, unlike `startRun`). **(2) `BoonInfo` HAS EIGHT FIELDS AND WE SENT TWO.** The other
six were never missing DATA -- the local catalogue already holds them -- they were never joined up.
`M._enrichOffer` does it at post time, and **this is not a revival of the contemplate chain**:
every hazard that got that chain removed in v4.7.279 (a command per boon, the shared `_capturing`
slot, a stall that dropped the ENTIRE report) belongs to the FETCH, not the fields, and a local
table read cannot stall, race or drop the post. Fill-never-overwrite (the offer screen owns
`description`), returns a COPY (the caller's list is also history and `lastOffered`), camelCase ->
snake_case mapped at the boundary, and `conflicts_with` OMITTED when empty rather than sent as `{}`
(an empty Lua table has no array/object distinction for yajl). **(3) `reroll_count` IS INFERRED
FROM THE SCREEN, NEVER FROM A COMMAND** -- rerolls are real (`Negotiator` grants "5 additional
rerolls") but the command that spends one has never been captured, and inventing one is how
`bash dwaeonic off` got documented for a command that never existed. `M._rerollBump` counts the
EVIDENCE: a second offer screen with no claim and no `GO!` between. **The NAME SET is the guard** --
a reroll yields DIFFERENT boons, a mere re-print yields the identical set, so an identical re-print
neither counts nor resets. The comparison must happen BEFORE `run.lastOffered` is overwritten, and
the chain is ended by a claim and by GO! and **never by the ripple number** (at the boon screen
`_offerAfterRipple` sends its own `wade status`, so `run.ripple` can advance BETWEEN two screens of
one chain -- keying on it would miss exactly the reroll it exists to count). Prospero's Fortune is
correctly not counted, because a claim intervened. `_resetRun` clears BOTH the count and
`offerChain`: **clearing only the count is worse than clearing neither**, since a chain left open
makes the next run's first screen differ from the now-empty previous names and post
`reroll_count = 1` for a screen nobody rerolled. **(4) `OkResponse { ok, message? }` WAS NEVER
READ** -- an HTTP 200 carrying `ok: false` (the server saying it did not happen) was logged as a
success. Now surfaced with the server's own message, but it SURFACES rather than re-routing:
`onOk` still runs, because we have never observed this server answer `ok: false` and `startRun`'s
`onError` would silently stop all reporting for the dive on a guess (the claim-confirmation rule,
v4.7.278). Also v4.7.298: three CONTEMPLATE meta labels graduate to typed fields
(`M._promoteMeta` -- `category`, `unlocked_by`, `conflicts_with`, with **`info.meta` left whole**
because it is the mechanism that learns the NEXT label, and **`Conflicts with` split on COMMAS
ONLY** since `Hammer and Anvil`/`Hammer and Nail` are real boons and a phantom name is worse than
an unsplit one), `_learnBoon` gains a fifth TABLE argument so the four existing positional call
sites stay correct, and `_boonDbMerge` becomes field-driven (`M.BOON_DB_FIELDS`) -- **a correctness
change, not tidying**: naming its three fields inline meant a saved catalogue would round-trip
through save/load LOSING the four new ones. Already correct and left alone: `/health` (wired to
`mnem test`), `public_id`, `RunExistsResponse`, and `DeathRequest.killer` (schema-required; OUR caller defaults it).

**`combo_boon`, THE NINTH `BoonInfo` FIELD (v4.7.322, schema re-verified 2026-09-18).** The tracker
added a boolean `combo_boon`; everything else still matched. The wording is known ONLY from the
tracker's `GET /boons/export`, where ten descriptions carry `Combo Boon?:        Yes` GLUED ON --
which screen prints it was then unproven -- **since PROVEN: CONTEMPLATE prints it** (Flameheart's and Elder Wisdom's blocks, v4.7.326, both "Yes"). "No" is still unseen -- Careless Whisperer's block has no combo line at all, so a non-combo boon may simply omit it.
**Sources:** `M.BOON_COMBO` seeds those ten (fill-only; nothing seeded as NOT combo), and `mnem
boonfill` now fills its batch after the description gaps with DESCRIBED boons (`M.boonMetaGaps`,
seeded combo boons first, `(ECHO)` rows excluded) -- because `boonGaps` only ever queued boons with NO
description, a mature catalogue (402 boons, 0 gaps) would never have learned anything. **Since
v4.7.324 that is a CYCLE, not a one-off** (user: "they constantly change these"): see below. `_enrichOffer` sends `combo_boon` when either answer is known and OMITS
it otherwise (TYPE tests, never truthiness, all the way down: `false` is an answer). **Glued screen
lines were already in OUR catalogue** (Deadly Finesse's "description" = two WADE STATUS lines a
contemplate capture swallowed), so they are now refused at every door: `M._splitGluedMeta` (the tell
is 2+ spaces after the colon -- column padding, never prose; matched exactly the corrupted strings
across ~1,100 descriptions), `_learnBoon` never stores one, `M._boonDbRepair` fixes stored ones at
load (reported by `mnem boondb`), `M._cleanOfferList` stops a meta row becoming a fake boon on the
offer screen, a captured "contemplate" with neither `Rarity:` nor `Can echo:` is ignored, and a
column-padded label printed AFTER the text is meta too (a single-space `Note: x` line stays prose).
`mnem boonfill recheck` restarts the contemplate cycle (answers kept). Also:
meta labels may end in ONE `?` (`META_KEY`), only the seen label promotes, `Unset` is a placeholder,
`_boonDbMerge` type-checks the non-string fields, `/ripple_level` takes whole numbers only, and the
dead `_contemplateNext`/`_applyContemplate` chain is gone.

**ONLY THE NEW BOONS ON A SCREEN (v4.7.391, user: "We should only need to contemplate new boons that
we dont have in the database").** This REVERSES the offer-screen half of v4.7.324 below: the screen
chain now contemplates an offered boon only when `M._boonDescribed(name)` is false -- no description
in the boon library or in the seed -- and the two one-per-screen extras (a description gap, a combo
component) obey the same test. A screen of known boons sends nothing and prints nothing; the offer
summary still prints. Re-reading KNOWN boons for changed text is now `mnem boonfill`'s job alone.

**CONTEMPLATE EVERY BOON, EVERY TIME (v4.7.324, user: "we should boon contemplate all boons no
matter what as they constantly change these"; offer-screen half REVERSED in v4.7.391, above).** A boon
used to be contemplated at most once. Then: every OFFERED boon was contemplated on every boon screen
(`M._boonScreenContemplate`, plus one catalogue gap) -- scheduled from `_flushPendingOffer`, i.e. AFTER the offer has posted, so it cannot recreate
v4.7.279's dropped reports; it never takes the capture slot from another capture (waits up to 5s, then
gives up) and stops at GO! (`M.onGo` bumps `M._fillGen`; a run from an older wave ends). `mnem
boonfill` cycles the whole catalogue, never-contemplated first then oldest `contemplatedAt` (legacy
`comboChecked` counts as long ago). A contemplate now UPDATES the text and echoes `<name> changed`,
which is only safe from a whole block: `_captureContemplate` sets `info.complete` from whether the
block ended on its CLOSING divider, and a partial one (timeout / force-finished) teaches nothing. The
per-screen run is silent unless it learned or changed something.

**BOON CONFLICTS (v4.7.325, user: "echo the conflicts and highlight them").** CONTEMPLATE prints
`Conflicts With:     Self-Preservation and Truther` (joined with " and "; the meta block ends in a
BLANK line). Parsed into `conflictsWith` (stored, and sent as `conflicts_with`): `M._splitBoonList`
splits on commas and " and " then re-joins fragments that form a KNOWN boon name, longest first
("Hammer and Anvil" survives); a following line counts as a wrapped tail only before the blank line
and only while the whole list still splits into known names. Trigger `mnemosyne/092` highlights each
name in the line (red if HELD this run -- `M._heldBoons()` = this run's claims, only while a run is
active; `ataxiaTemp.boonsOwned` is never cleared so it is not used; gold otherwise, as in the summary) and
adds the list to the block's summary line; the offer screen's `M._echoBoonCallouts` (v4.7.326; it
replaced `_echoConflicts`) warns per offered boon, reading the pair from either side. The real
block's values sit at column 21, like the glued "Combo Boon?" lines -- and Flameheart's block (v4.7.326)
then showed `Combo Boon?:        Yes` outright, so that line IS CONTEMPLATE's. **Call-outs (v4.7.326,
user: "should called out if the boon can combo and echo"):** trigger `mnemosyne/093` highlights a
`Combo Boon?: Yes` / `Can echo: Yes` / `Maximum echoes: N` in place, and each contemplate block gets
ONE summary line (`M._calloutAdd` gathers combo/echo/conflicts; `_calloutFlush` prints them in that
order). **The aggregator is module-global, so it flushes at a BLOCK BOUNDARY** -- 093 also matches the
closing divider (`^-{3,}`) and the next block's `^Rarity:` -- because a contemplate chain sends the next
block 0.5s after the last closed; the 0.4s quiet timer is only the backstop, a flush kills it, and a
reload resets it. The offer screen's `M._echoBoonCallouts` gives each offered boon the same call-outs
from the catalogue. **`echoFloor`**: "Can echo: Yes" with no "Maximum echoes" line parses as 1, a
floor -- flagged so the offer screen says "can echo", never "(max 1)", and never allowed to replace a
real count. **One contemplate chain at a time** (`M._fillBusy()`, stamped by every
`_boonFillNext` step, cleared on every exit, stale after 15s): `mnem boonfill` refuses and the
per-offer chain does not start while one runs.
**THE BOON ADVISOR (v4.7.327, `014_Boon_Advisor.lua`; user: "defensive boons are a priority" /
"it depends on the boons we have" / "each class will be different").** `M.offerSummary(list)` prints
every option (category, rarity, combo/echo, parsed effects, a `locks out:` line, red flags) and a RECOMMEND line; it runs
at the END of the offer's contemplate chain (`ctx.offered`, set by `_boonScreenContemplate`) -- quiet
chain or not -- or straight from `_flushPendingOffer` when no chain starts. **LOCK-OUTS (v4.7.468, user: "if I choose this I wont be able to choose X, Y, Z"):** `scoreBoon` sets `r.conflicts` from `M._conflictsFor` BEFORE its early returns, and `_conflictsFor` now reads the reverse side of a pair from the WHOLE catalogue, not only from held boons. Each option prints `locks out: <names>` (red held, yellow also offered, gold other); an empty list prints `nothing` only when `contemplatedAt` is set, else `unknown (not contemplated)`, because a boon with no conflicts prints no `Conflicts With:` line. RECOMMEND appends what the pick locks out. `M.scoreBoon` is a SUM OF
NAMED PARTS (each part is a printed reason) built on the existing parsers (`_resistFrom`,
`_immunitiesFrom`, `_statFrom`, `_dmgGenericFrom`, `_dmgBoostFrom`, `_procFrom` + Fae-Lapse's "chance you
give the denizen you are attacking X", `_boonDrawbacks`, `_conflictsFor`, `_spiritGate`), relative to
what we hold (`bonusTotals` resists/immunities, held categories). Stat-scaling damage boons (Brute Force / Mental Prowess / Deadly Finesse via `M.BOON_STAT_DAMAGE`, or "for each point of <stat>") get `statScalingDamage` +40 (v4.7.362, user: "These should be weighted high"). **Death's Demise and Gravedigger** get `topTier` +150 via `M.BOON_TOP_TIER` (v4.7.363, user: "should be highest in score"; **Star of Winter** -- an extra life every new ripple -- joined in v4.7.371) -- except while holding the other, since Death's Demise removes the death-cape life-steal Gravedigger builds on. A boon that says "gain no health" (Elixir Addict: no healing from moss or potash) is charged `herbHealingLost` 30, and `M.BOON_SYNERGY` pairs score `synergyHeld` +40 when the partner is held (v4.7.368; the one pair, Healing Metabolism <-> Obligate Carnivore, was removed in v4.7.454 because the satiation defence needs no food). Weights: `M.BOON_WEIGHTS` (defence
first), `M.BOON_CLASS_WEIGHTS[<gmcp class lower>]` merged over it (deep; empty until play says).
Reroll hint needs `M._rerollsLeft` > 0 (trigger 094; reset per screen). **A REFUSED CONTEMPLATE IS
NOT ALWAYS A BAD NAME (v4.7.328, user: "I picked it before the skill had time to look"):** claiming
closes the offer screen, so the chain's next contemplate is refused for a name the game itself
printed. `_wasOffered(name)` (against `run.lastOffered`) decides: printed by the game = right
spelling = the screen closed (`offerScreenGone`, which also stops the chain asking for that
screen's other boons; `onBoonClaim` sets it too, so the refusal usually never happens). Only a name
we never saw offered is blacklisted. Any name the game prints clears an old mark, and the list
built under the old rule is cleared once at load (`boonUnknownFix = 328`). **BOON COMBOS (v4.7.328,
`015_Boon_Combos.lua`, `mnem combos`; user: "tie which boons combo together to get to the end path
of the boon"):** the recipe prints on the REWARD's contemplate (`Unlocked By: Argent Scales,
Electric Mastery, and Energetic`; whether a COMPONENT's block also carries it is unproven -- none
has been read), read as a LIST into `unlocksFrom` -- NOT through `META_PROMOTE`,
whose 60-char cap drops a recipe over 60 characters -- the real 3-name one is 46 and fits, a 4-name one does not (the string is still promoted, and `_enrichOffer` falls back to the LIST so the tracker still gets it)
-- with the conflicts line's wrapped-tail handling. `comboChains` (reward -> parts, rebuilt per
call), `comboFeeds(name)`, `comboProgress(reward, held)` (this run's claims), `comboGaps()` (named
components never contemplated; the offer chain takes ONE per screen). The advisor scores
`comboStep` / `comboCompletes`. The reward is GRANTED, never offered or claimed, so trigger 095
(`bestows upon you another: X`) does what the claim path does -- `_recordClaim`, `latchBoonFlag`,
`bonuses.refresh`, and `reportBoonReceived` -> **`/boon_received`** (v4.7.330, the tracker's own
endpoint for this; singular, one whole `BoonInfo`; NOT `/boons_selected`, which would claim we chose
it) -- once (a held reward means the line is a replay), only
inside a run, and asks for its contemplate with a RETRY (`_contemplateGranted`), because the offer
chain usually still holds the capture slot; `comboGaps` also names a boon we HOLD but never
contemplated, so the reward cannot fall through. Recipes come only from the game's text -- never
guessed from names. **22 RECIPES ARE SEEDED** (v4.7.329, `M.BOON_COMBO_RECIPES` in 010_Boon_Seed,
from contemplate blocks the user and other players pasted): fill-only, uncontemplated, so the game
still corrects them -- without them a chain is invisible until its reward is already in hand.
Evidence they carry: a recipe takes 2 to 6 components; `Candour and Wrath and Righteousness` is TWO
names (`Wrath and Righteousness` is a boon), which is why `_splitBoonList` re-joins against known
names and why seeding those names matters; `It All Ogre Now`'s category is `Unset` (a placeholder).
**A NUMBER TRADED AWAY IS NOT A PRICE** (v4.7.332, user: "Ogre is a bit different... losing a stat
but gaining X is a lot better"): `M._costLosses` reads "lose N% <thing>" / "lose N <stat>" (never
"reduced by", which `_resistFrom` already charges) and subtracts it in the same currency as the gain
-- `lossPerPct`, or the stat's own weight, so losing constitution costs more than losing dexterity --
with NO haircut, and listed as an effect rather than a red flag. A cost with no number in it
("all mana costs now cost health") is still unpriced. **A COST IS WEIGHED AGAINST OUR IMMUNITIES** (v4.7.331, user: a boon costing an affliction we cannot
block "should be scored significantly lower as the cost isn't worth it for the benefit"): each
affliction `_boonDrawbacks` finds is checked against `ctx.immune`; an un-immune one takes
`drawbackKeep` (half the boon's own score) plus `drawbackAffFlat` (35) per affliction, charged AFTER
the rest of the scoring and never as a gain on a negative score; an immune one is `drawbackImmune`
(-2) and is listed as an effect, not a flag. The advisor scores a component's combo credit even with
no description of our own -- most components
have none, and returning early cost exactly the boons a seeded recipe names. **The advisor pays ONE chain's worth** (the best) however many a boon feeds, and
a boon that conflicts with a held one or is inert never takes the RECOMMEND line while a usable
option exists (`r.blocked`). **A WRAPPED list's tail is taken when the value ends in a dangling
comma or "and"** -- the all-known-names test alone lost a recipe's newest component AND turned the
orphaned line into the boon's description. It NEVER claims -- the
auto-picker is a later, opt-in step. `mnem advise` / `mnem boonweights`. `mnem boondb` shows,
counts and filters by category.
`GET /boons/export` is documented in
02-reporting and deliberately not consumed.

**THE DEEP REVIEW OF v4.7.298 (four parallel agents; every finding verified before acting, two
rejected).** Six of the nine fixes were defects in the change itself, and three rules come out of
it. **(1) `M.run` IS SERIALIZED -- the header comment saying otherwise is FALSE.**
`ataxia_saveSettings` does `table.save(file, sanitizeForSave(ataxia))`, wholesale, stripping only
functions/metatabled objects/GUI snapshots, and `deepMerge` ends in an unconditional `dst[k] = v`
-- so `run.active`, `ripple`, `publicId` and `lastOffered` ALL persist today, and the reroll chain
did too until it moved to `ataxiaTemp.mnemRerolls`/`.mnemOfferChain`. Before putting a transient
flag anywhere under `ataxia`, re-read the v4.7.192-194 rule; `_relatchBoons` already obeys it.
**(2) A DEFERRED SEND MUST CARRY ITS OWN DATA.** `/boons_offered` posts on the ripple line or a 3s
timeout, and `onBoonClaim`/`onGo` close the reroll chain the moment they fire -- so reading the
count at send time reported 0 for the LAST screen of a chain, the one row that mattered. It is
snapshotted with the screen now (`M._pendingRerolls`). The same deferral had a second face: a
replaced `_pendingOffer` was DISCARDED, correct in v4.7.279 when a second screen meant a duplicate
capture, wrong the moment rerolls made two distinct screens normal -- it is FLUSHED now, and
`_resetRun` drops it at a run boundary so a stale offer cannot post under the next run. *When a
feature makes a previously-impossible event routine, go and re-read what the old code assumed.*
**(3) A PARSER THAT READS RAW PHYSICAL LINES MUST NOT BE GIVEN A LONG VALUE.** `Conflicts with` is
no longer promoted from the CONTEMPLATE meta block. `_parseContemplate` does no
continuation-joining and Achaea wraps server-side (v4.7.286/297); every label the screen has ever
printed has a SHORT value (`rare`, `No`, `3`), but a conflicts value is a LIST OF BOON NAMES. A
wrap truncates the value AND -- the continuation line having no colon, so not a label -- flips the
state machine into `desc`, making that fragment the opening words of the DESCRIPTION, which is
written to the catalogue and never revisited (`boonGaps` only chases a MISSING description) and is
read by the bonuses panel. It is undetectable: the real captured block in our own fixture wraps
mid-sentence with a FLUSH-LEFT continuation. Promoting a label we have never read, whose value is
the shape most likely to wrap, buys nothing (no line means no value) and risks the catalogue's most
irreplaceable field; it stays in `info.meta`, which is what v4.7.288 built `meta` for. The two
labels that remain are promoted because their values PROVABLY cannot wrap, and `META_VALUE_MAX`
(60) ENFORCES that rather than assuming it, with `META_PLACEHOLDER` refusing `None`/`N/A` so a
game's word for "no value" cannot become a boon named None. Also fixed: an identical re-print
posted a DUPLICATE `/boons_offered` (the name-set guard protected the count, not the send);
`/run_pause` is gated on `_auto()` rather than `_inRun()`, because `run.active` is our BELIEF and
is false in exactly the window that matters -- after a reload mid-run, until the delayed
`/run_exists` answers, a request with no `onError` -- while trigger 016 is exact and
Mnemosyne-only, so if the game says we paused, the run exists; `mnem pause` now exists, since
`05-commands.md` opens by promising a manual override for EVERY reporter endpoint and the one
driven by a single exact trigger line had none; and `_boonDbMerge`'s field-driven loop now respects
its fields' TYPES -- `conflictsWith` is the only table in it, `cur[f] = rec[f]` ALIASED the source
(the hazard `_learnBoon` guards against two functions above), and since **a table is never `== ""`**
an empty `{}` merged as data and then permanently passed the already-filled test with nothing able
to refill it.

**Ripple mini-map (`ataxia.mnemosyne.map`, files 005/006):** draggable per-ripple grid widget (`Adjustable.Container`, position auto-persists). Builds a room graph from `gmcp.Room` arrivals in Mnemosyne. **DEAD RECKONING -- THE ROOM ID IS ALSO A LIE (v4.7.250).** User: "the gmcp room id will be changed every time we look because of dementia that we cannot cure". Keying the graph by `gmcp.Room.Info.num` is then broken at the root: every look mints a NEW room record, `MAP.current` changes without us moving (so the explorer's `MAP.current ~= explore.fromRoom` arrival test reads TRUE for a plain `ql` and never FALSE), and exit destination ids never match any key we hold so `relayout` links nothing. Creville's Legacy is INCURABLE, so it cannot be waited out. **Track what dementia cannot touch: our own movement.** Position is dead-reckoned from the directions WE sent (failure has its own lines -- `Room.WrongDir`, the wall line, the ice slip, the move timeout -- so a failed move is known), and the room KEY becomes that position (`dr:2,1`). Deliberately a KEY SWAP, not a parallel map: `MAP.rooms`/`room.edges`/`MAP.path`/`unexploredExits`/the whole sweep treat the key as opaque and keep working unchanged. `MAP.drActive()` (dementia + in tower, `MAP.drForce` for tests), `MAP.drArrive(exits)` (advance + record, the single owner -- it runs from 005's gmcp.Room handler which is registered BEFORE the explorer's, so it still sees `explore.moving`; advancing in both would double-step, advancing only in the explorer would miss the swarm's tumbles and pulls). Exit DIRECTIONS are kept and destination ids discarded (the direction set is the fingerprint, the id is noise); `relayout` parses coordinates back out of the key instead of BFS; `MAP.reset` restarts the reckoning per ripple; `up`/`down` carry no 2-D step so the holding room's descent does not move us on the grid.
**TRACK BY EXITS, AND ARM THE STEP (v4.7.251).** `MAP.drArm(dir)`/`drDisarm()` arm the reckoning
for EXACTLY ONE step when a move is sent, consumed by the first event after it: v4.7.250's "any
room event while moving is the arrival" was the same bug in a new hat, because several room
events land inside one move's window -- so the move ended early AND the reckoning advanced again
each time (live log: `room clear -> moving e` eight times in five seconds). A token that gets
SPENT distinguishes the first event from the rest; a predicate over current state cannot.
`MAP.parseExitsLine`/`onExitsLine` read `You see exits leading north and west.` -- the only
honest exit source under dementia, since gmcp pairs directions with invented DESTINATIONS while
this line carries directions alone. It REPLACES the exit set (a direction that stopped being
reported is one the room does not have; merging is what walks the sweep into a wall), trigger
`mnemosyne/063` is a one-line adapter so the parse stays testable.

**BOTH WORDINGS, AND THE EXITS LINE IS NOT DEMENTIA-ONLY (v4.7.260).** The game prints
`a single exit leading northeast` for one and `exits leading ...` for two or more, and the
plural-only pattern is why a sweep stopped dead in a room whose description plainly listed an
exit. `353_Real_Exits` had captured both since v4.7.75 into `ataxiaTemp.realExits` -- which
**nothing ever read**, and the CHANGELOG entry that added it listed wiring the explorer to it as
the next step. Dead output is indistinguishable from a missing feature. The "gmcp is richer"
reasoning survives as a REPLACE/BACKFILL split: under dead reckoning the ids are inventions so the
text replaces; outside it `relayout` needs the real destinations, so the text only backfills
directions gmcp did not give (stored `0` = exit exists, destination unknown).

**A ROOM NUMBER IS NOT A PLACE (v4.7.260).** The tower draws each ripple's 4x4 from a POOL OF REAL
ROOMS, so the same gmcp id returns on a later level with a different layout and different affixes.
`lavaRooms`, `lavaEdges`, `failed` and the boss-chase counter are all keyed by room number and
were cleared only on a package RELOAD -- so lava learned on one level condemned that id for the
rest of the session (live: `north -> 65420 REFUSED: leads into lava` on an exit never glanced at).
`M.onRippleReset()` now hangs off `MAP.reset()`, which already draws that line.

**A GLANCE PRINTS SOMEONE ELSE'S ROOM (v4.7.262).** `Glancing to the northwest, you see:` is
followed by the NEIGHBOUR's exits line, and 063 has no notion of whose room a line describes -- so
the neighbour's exits were grafted onto ours (observed: 67777 holding four exits where its own
description lists two). Not cosmetic: text exits store as destination `0`, which reads as an
unwalked door, so the sweep would step through a door that does not exist. Trigger
`mnemosyne/071` arms a **one-shot token** (not a time window -- the glanced block prints
immediately, and a token that gets SPENT distinguishes the first line from the rest, the same
reasoning as `MAP.drArm`); both `onExitsLine` and `onNoExits` spend it. This was the missing half
of v4.7.260's ungating: **widening what a parser accepts obliges you to say what it must still
refuse.**

**ZERO IS AN ANSWER (v4.7.263, trigger `mnemosyne/072`).** Nothing parsed
`There are no obvious exits.` -- so an empty `room.exits` meant both "none" and "not told", and
the explorer re-asked forever. `room.exitsTextZero` is deliberately **inert**: it never writes
`room.exits` and no consumer of the exit graph reads it, because **"no OBVIOUS exits" is not "no
exits"** -- the holding room prints that line and still has the `down` the sweep descends by.
Zeroing the table would run `usableUnexplored` -> nil -> `_exploreStop` ->
`raiseEvent("basher disabled")`, i.e. combat off in a no-flee instance while the user reads a
menu. Its only job is to stop the asking, and a told-zero room **holds** (bounded) rather than
stopping, since `_exploreStop` clears `explore.on` and `exploreOnGo` only un-pauses.

**THE EMPTY PUSH IS SILENCE, NOT A DENIAL (v4.7.263).** `MAP.onRoom` rebuilt `room.exits` from the
gmcp table on EVERY push, and 005's handler runs before the explorer's -- so in the tower, where
that table is empty, each push erased whatever the prose had just supplied, **including the push
our own `ql` caused**. That closed the boon-screen loop: ask -> wipe -> find nothing -> ask again,
~15 room descriptions in half a second. The wipe's purpose is retained (a non-empty push replaces
exactly as before, so a direction gmcp stops naming is still dropped and a demented push still
overrides); an empty or absent table now changes nothing. **Capping the asker would have been a
cap on a live engine.**

**`gmcp.Room` IS A PREFIX EVENT (v4.7.263).** `Room.Players`, `Room.AddPlayer`,
`Room.RemovePlayer` and `Room.WrongDir` all raise it, and 005 acted on all of them off a stale
`Room.Info`: another player entering rebuilt our exits, and **`Room.WrongDir` spent
`MAP._drArmed` and credited a dead-reckoning step for a move the server had just REFUSED**. 005
and 008 both register on `gmcp.Room.Info` now, in the same change (008 is where the arrival
decision is made, so 005 declining alone changes nothing); a two-liner stays on the prefix for
`MAP.autoShow()`. **The obvious guard is a trap:** `if not gmcp.Room.Info then return end` (as at
`update_stuff/002_ataxia_Room_Update.lua:39`) tests whether the TABLE EXISTS, not whether THIS
EVENT was an Info -- and the table persists after the first room push, so it is dead code from the
second room onward.

**THE WITNESS, NOT THE INTENT (v4.7.262).** `explore.fromRoom`/`fromDir` record the move we
**ARMED**; nothing on any arrival path corrects them, and `onLava`'s `from ~= cur` guard is not an
adjacency check (every other room on the grid satisfies it). So any unarmed room change -- panic
tumble, drag, forced move, the lava escape itself -- left them naming a room we are not next to,
and the next lava tick condemned an edge out of THAT room permanently. `MAP.onRoom` already
resolved the true traversed direction for every arrival however caused (it survives a tumble
because `MAP._lastMoveDir` comes from `sysDataSendRequest`, which sees `...;tumble ne` as readily
as `...;nw`) and proved adjacency by writing the edge -- it simply never published it. It now
publishes `MAP._lastArrival`, and `M._inbound()` is the single owner of "how did we get here":
prefer the witness, accept the armed pair only where the map corroborates it, and return the
REASON when it cannot.

**THE 4x4 IS EVIDENCE (v4.7.249).** DEMENTIA (Creville's Legacy) hallucinates the room wholesale -- a real Achaea room name, a real room NUMBER, an NPC that is not there and invented exits ("You see exits leading north and west"), all arriving through the SAME gmcp channel the map trusts. `MAP.onRoom` recorded whatever it was handed and `relayout` placed rooms wherever those exits implied, so one demented room stretched the layout across the map. The 4x4 is the one thing dementia cannot fake and it was known ONLY to the renderer (`006`'s `LEVEL = 4`). `MAP.GRID = 4` + `MAP.exitFitsGrid(num, dir)`: an exit whose destination would push the bounding box past 4 cells on either axis cannot be real. It rejects ONLY provable overflow -- unplaced room, unknown room, non-planar `up`/`down` (the holding room's descent) and a still-small box all pass, so it never rejects on ignorance and tightens as the ripple is explored. Consumed by `relayout`'s BFS (a placement that would burst the box is refused, so the room stays unplaced rather than corrupting its neighbours) and by `usableUnexplored` (never spend a move + MOVE_TIMEOUT + retry on an exit the geometry already rules out). `MAP.GRID` is a field, not a literal, so a non-4x4 ripple relaxes it with one assignment. **Coordinates come from `MAP.relayout()`** — on every arrival it rebuilds a bidirectional adjacency from all rooms' known exits (`dir → neighbour-num`, coerced with `tonumber`; gmcp reports them as strings and `0` for unknown dests) and BFS-assigns coordinates from the origin. Re-deriving from the full accumulated graph each step is what makes it robust: a room unplaceable on arrival is placed on a later pass once either side of a link is known (per-arrival placement couldn't bootstrap). Anchored on the origin, falling back to the current room so it's always shown. Walked edges (for click-to-walk `MAP.path` BFS → `queue add free`) are recorded separately. Render (006) draws a **fixed 4×4 grid** (every ripple is a 4×4): visited rooms coloured (current green, un-walked-exit gold `?`, else grey), unvisited positions as dim placeholders. Wipes each ripple and re-seeds the current room from `gmcp.Room.Info` (`onRipple → MAP.onRipple`). Toggle `mnem map on|off` (`ataxia.settings.reporting.mapEnabled`, default on); `mnem map status` prints diagnostics incl. per-exit state. GUI (006) needs Geyser/`main` so it's not unit-tested; the pure graph in 005 is (`test_mnemosyne.lua`).

**Local history (`ataxia.mnemosyne.history`, file 007):** a persisted local mirror of what each run parses — `offers`/`claims`/`affixes` per run plus an all-time `library` of affixes — recorded at the parser hooks (`_recordOffers`/`_recordClaim`/`_recordAffixes`) whenever a tracked run is on. `mnem boons` / `mnem affixes` / `mnem library` review this run's claims, its affixes, and the catalogue; `mnem quiet` silences the auto per-claim/affix echoes (still records). Bootstrapped runs (missed start line) get their own bucket via `onRipple` bumping the counter. Persistence (`table.save`/`load` to `mnemosyne_history.lua`) is guarded so a bare/test env never errors.

**Swarm tactics (`ataxia.mnemosyne.swarm`, file 009, v4.7.111-120):** deep ripples pack 3-4+ ROAMING denizens per room (they move between rooms; cleared rooms can repopulate). The explorer delegates every decidable tick to `swarm.onTick()` (consumed tick = no navigation). At `>= threshold` killable mobs (`mnem swarm assess <n>`, default 3; `mnem swarm deep <r> <n>` depth-scales) with a VALIDATED back-route (planar + adjacency vs the reported-exit graph — never "up" out of the first grid room), the pull fires: a one-shot decorator (`ataxiaTemp.swarmPullDir`, consumed in `ataxiaBasher_assembleAttack`) turns the next attack into `"<attack>;<backdir>"` — swing + step-out as ONE queued line (the manual ragepull shape). Consumption arms `ataxiaTemp.swarmHold` (gates BOTH `ataxiaBasher_attack` — several triggers call it directly — and `ataxiaBasher_tryAttack`; 8s self-clear matched to the pull's tactical timeout + load-time clear — it would otherwise survive SYSUPDATE and silently kill the basher), clears `found_target`, kills `mobshieldtimer`. Funnel: fight followers where we chose the ground; 2s window refreshed by combat (v4.7.157, 4 -> 3 -> 2: chasers arrive quickly, so a longer wait only idles on mobs that were never coming; combat refreshes the window, so a real fight still holds us there); empty window → re-enter and re-assess -- but **only if we are FIT to** (v4.7.242): `S._reenterReady()` requires `recoverAt`% AND affliction-free, the same gate the hover uses, because `_beginReenter` used to decide on one question ("did anything follow?") and **"nothing followed" is not the same fact as "we are ready"** -- a death log has it walking back onto Seasone two seconds after a successful disengage, at 28% HP and still soft-locked. Not ready → enter `recovering` (ground recovery) rather than inventing a second wait. Nothing else caught it because the low-HP ladder runs BEFORE the funnel branch and `_beginEscape` needs a back-route we were already standing in, so it returned false and fell through; `MAX_PULLS=3`/room then fight in place — but **progress REFUNDS the budget** (v4.7.117, Putoran-wildcat log: non-chasing mobs make every cycle a free swing): each pull snapshots count + focused-target hp (`entrySnap`, HUD mob-bar data chain), and a re-entry with fewer denizens or the same target chipped lower resets pulls to 0 — hit-and-run continues until the room is cleared or below threshold; only unproductive cycles (mobs regen while we funnel — "tending his wounds") spend budget. **Tactical moves NEVER write `explore.failed`** (`M._tacticalArm` + `explore.tacticalMove` guards all three condemn paths). Resets: boon screen, `_exploreStop`, `basher disabled`, sysLoad (flight landed on every reset). LIVE branches: indoors icewall+leap (first escape suffix `;point bracers417868 <LONG back>;leap <back>` one queue entry; the wall then STAYS — v4.7.119: re-entry is a single eq-gated `leap <fwd>`, follow-up escapes go leap-only via `S.wallRaised[room]` (a balance-round faster), and the wall is melted via `bracers151113` only when the room empties, on a consumed tick so the explorer's own queued move can't wipe the melt — an intact wall silently fails normal walks and would condemn the backtrack edge), outdoors fly-kite (`land;<attack>;fly` wrap while `swarm.flying`; lands below threshold; FLY-needs-balance degrades to grounded, never wedges), Roll Hide panic-tumble (`swarm.panic`, `panicAt`% default **35** (v4.7.218; the old 40 is migrated ONCE behind a persisted `panicAt35` marker, so `mnem swarm panic 40` stays typeable -- an unconditional rewrite would drag it back every tick) **OR** the absolute floor `panicHp` default 3000 -- whichever is crossed first, v4.7.202, `mnem swarm panichp`; tumbles back into the room we just CLEARED via the validated `S._backDir()` -- the one square known empty, and Roll Hide sheds every pursuer so we arrive alone -- unless that edge carries our own icewall, in which case it falls through to a non-swarm exit; **and only while "back" IS a cleared room (v4.7.444, from a death)**: `_backDir` reverses the LAST move, so a panic that fires just after a retreat landed reads "back" as the room we FLED -- the tumble went straight into the denizen that killed us. "Back" now needs `S._exitRank(back) == 1` and must not be `S.fwdShort`, else the ranked scan picks the door; 10s cooldown; lands first mid-kite, free-queued + hold-protected so the next attack's addclearfull can't wipe it — v4.7.112-113). **The tumble then HEALS WHERE IT LANDED (v4.7.218)** rather than dropping to `idle`: it used to hand straight back to the explorer and the 8s `swarmHold` self-cleared, so we navigated back into the room we had just fled at panic HP -- the boon's whole value spent on an immediate return. It now enters `recovering` with `S.recoverGround`, held until `recoverAt`% AND aff-free, then hands back for the next run-in (user: "the denizens wont follow so we can use this to our advantage to heal up and then do hit and run tactics"). A GROUND recovery is not a hover: a denizen arriving ENDS it (standing attack-gated at panic HP while something hits us is worse than fighting it) and it never sends `land`. `_maybePanic` also refuses while `state == "recovering"` -- Roll Hide already shed them, so a repeat tumble only walks us off the sweep. **THE FUNNEL WINDOW OWNS ITS OWN CLOCK (v4.7.282).** A live 2s window measured EIGHT seconds with **peak followers: 0** -- six wasted seconds on every unproductive hit-and-run cycle. Two faults: `_enterFunnel` stamped `funnelAt` and **scheduled nothing** (every recovery state here self-ticks on `RECOVER_TICK`, eight sites, since v4.7.116 learned an event-driven tick starves in a quiet room -- and with nothing following there is no combat, no arrival and no target change to fire one; the `ql` it sends usually produces an event, and "usually" is the bug); and **`M._scheduleTick` is LAST-CALL-WINS**, killing the pending timer, so the funnel's own `remain + 0.1` was pushed out by unrelated callers -- the explorer re-arms at 1.5s (no-exit ql) and 3s (told-zero hold), which chained turns 2s into 8. **A shared single-slot timer where every caller assumes it owns the schedule cannot hold a deadline.** Fixed with a DEDICATED `S._funnelT` (armed at birth, re-armed when combat refreshes the window, killed in `S.reset`) rather than changing tick semantics globally, which would let an early tick undercut every deliberate deferral in the explorer. Break-back worth keeping: reverting the `remain` branch to the shared tick PASSED, because the birth-armed timer was still pending -- **an assertion that something EXISTS cannot detect the wrong thing having created it**; it now compares against the birth-armed id.

**TWO BOONS MAKE LEAVING END THE FIGHT (v4.7.447).** Roll Hide sheds every pursuer on a TUMBLE;
Terror of the Skies (dragon: "non-boss denizens [cannot track] or chase you") sheds them on ANY move.
Every "does leaving end the fight?" check is `S._shedsPursuers()` and every escape command is
`S._shedCmd(dir)`: the panic at the panic floor, the recovery re-move, the pull step-out, and the
indoor icewall (skipped, as Roll Hide skips it). Terror's command is a plain step (faster, cannot be
cancelled like a tumble); ice still tumbles; a flying panic still lands first (the recovery is on
the ground). Terror does NOT shed the ripple's boss: `S._bossHere()` (a KNOWN `M.run.boss` name in
the room) switches it off; Roll Hide still works then. User: "As dragon we can leave without them
tracking which is like roll hide and maklak's promise". (Maklak's Promise has no flag in the code.)

**THE DRAGON BOON FLAGS ARE IN `M.BOON_FLAGS` (v4.7.447).** Might of Sycaerunax, Draconic Rampage,
Draconic Sweep, Organ Piercer, Spark Extant, Krenindalan Storm and Terror of the Skies. Their own
BOONS-row triggers (035, 036, 111-115) latched on ANY BOONS list, outside the tower too, where the
flags drove tailsweep, trample and breathstorm in ordinary bashing; those triggers are gone.

**THE SWARM THAT FOLLOWS (v4.7.370, from a death; user-directed).** A retreat or pull records the room it leaves (`S._noteRetreat`); `S._checkPursuit` (every prompt and tick) judges `PURSUIT_SETTLE` 1.5s after landing whether a swarm is in the new room within `PURSUIT_WINDOW` 4s, and if so stamps `S.pursuedAt` -- for `PURSUIT_MEMORY` 45s (or until the room empties) NO ground retreat and NO pull starts: we fight (the death spent 15 of 30s attack-held retreating from a swarm that followed every time; the ~7s spent fighting killed three). The hover and the Roll Hide tumble are untouched. **Going back into the room we just fled** (`S._fled`, `FLED_MEMORY` 30s) needs `returnAt` 85% AND aff-free (user: "if we are cured and roughly 85 percent health we should return"); the funnel re-entry uses the same bar and its ground recovery heals to 85 (`S.recoverTarget`); hover/tumble recovery still 95. **Ice:** any slip marks the room icy (`S.noteIce` from `M.onIceSlip`) and tactical moves out of it TUMBLE (user: "With ice, try tumbling instead"; `TUMBLE_ARM` 8s timeout, no jump ledger, icy swarm rooms take the plain pull not the wall). **Messages say what happens:** bound -> "leaving the moment we are free" with NO emergency-cooldown stamp; "DYING FAST ... leaving." only when an escape starts, else "NOT leaving: <why>" via `S._sayOnce` (5s per reason); `S._retreatBlock` is asked BEFORE the reset. **"You are too tangled up to do that."** (trigger `mnemosyne/107`) parks the tactical move and `S._resendWhenFree` re-sends it on the first unbound prompt (`BOUND_PENDING` 12s). **WRATH AND RIGHTEOUSNESS (v4.7.372, `mnemWrathRighteousness`; user: "When we have this and die, we should escape the room. and def up")** -- `S.onRighteousFire` re-raises the current defence profile (`systemDefup`) and disengages, clearing the fight's pursuit memory and disengage cooldown first. No proc line is captured yet, so `S._checkRighteousFire` (first thing in onVitals) detects it: boon held, off its 1h cooldown, denizens present, health jumping `RF_JUMP` 45+ points to `RF_FULL` 95%+ in one prompt (the "before" need not be low: the lethal hit and the restore can share a prompt).

**AFTER AN ESCAPE, AND WHEN THE LEGS GIVE OUT (v4.7.378, from a Monk death; user-directed).** A ground escape sets `S._escaping`; landing anywhere but its own room or funnel calls `S._recoverHere` (ground recovery to `returnAt` 85% and cured, unless already fit) instead of resetting and handing the room to the sweep, which had walked on twice at 71%, blind and chased. `S._panicDir` (last resort, Roll Hide, recovery tumble) ranks doors with `S._exitRank`: cleared (visited, not just fled) < just fled / fighting < unexplored, sorted order breaking ties; the escape line names the kind. `S._noteRetreat` never overwrites a landed, unjudged retreat. `S._legsOut()` (both legs broken/damaged/mangled) blocks every GROUND escape like `_bound()` -- "leaving the moment they are mended", no cooldown stamp -- and trigger 345 parks the refused move via `S.onMoveRefusedBound("both legs broken")` -- since v4.7.416 only when our afflictions say BOTH legs are out: with one hindered leg the same line is STAND's refusal and a WALK goes through (Mystor's logs). A LEAP does not (v4.7.448, a death: the line printed for the stand AND the leap), so with one leg out `S.moveVerb` TUMBLES (`S._oneLegOut()`, user: "tumble at that point"). **The low-HP DIAGNOSE (`confirmedUnknownAff`, 2+ hidden afflictions) is `queue add free`, never `addclear` (v4.7.448)**: `addclear` empties the free queue, where the escape waits, and a second `?` 0.4s after an escape deleted the leap. A last resort has no funnel room, and the pulling branch never takes the room it is pulling out of as the funnel (the false "holding this room" + 8s "escape under way"). onVitals passes the real reason and fresh health to the retreat line ("DYING FAST (80%)", not "LOW HP (100%)").

**A RECOVERY NEVER SITS SILENT (v4.7.389; user: "We should never be 30 seconds and not doing anything").** Live, a ground recovery said "NOT going back in at 92% and still afflicted" and then nothing until the explorer's 30s watchdog: HP was met, one affliction SSC was not curing held the gate, and the only exits were "cured" or `RECOVER_MAX` (60s). `S._recoverWatch` (009, every recovering tick, keyed to `recoverStarted`) now: releases the recovery when HP is at the bar and no holding affliction has cleared for `S.RECOVER_STALL` 8s ("afflictions not clearing (<names>) -- going back in"), where progress is a SET test or HP rising while still BELOW the bar (HP climbing above it is not progress, or 92->100 would hold it forever); prints `healing: N%/85%, waiting on <names>` every `S.RECOVER_ECHO` 6s; and on a GROUND recovery sends `ql` every `S.RECOVER_QL` 5s (never airborne, mid-tumble or in lava). `S._blockingAffs()` is the named list; `S._afflicted()` is it non-empty. The explorer (008) re-arms its watchdog whenever an ACTIVE swarm state consumes the tick, so "no progress for 30s" no longer fires over a working recovery.

**DIAGNOSE WHENEVER WE LEAVE (v4.7.390; user: "When we leave a room because of a swarm, etc. We can always use DIAGNOSE").** DIAGNOSE costs 1.00s of equilibrium and no balance (AB 1380, `kb/raw/ab/survival_diagnose_1380.txt`; ours 0.85s with the Aldar Diadem, `kb/raw/live/mnemosyne-tumble-loop_2026-11-09.txt`:16; this note said "free" until 2026-10-10) and makes the server send a full `Char.Afflictions.List`, which `afflictionList()` uses to REBUILD `ataxia.afflictions` -- the cure for a phantom that holds a recovery. `S._diagnose()` (never mid-tumble, never in lava) runs on entering the funnel, on `_recoverHere`, when `_beginReenter` refuses, at the start of any recovery, and every `S.RECOVER_DIAG` 8s while afflictions hold us. The stall release requires a diagnose sent after the last progress and at least `S.DIAG_SETTLE` 1.5s old, so we never go back in on unconfirmed affliction data.

**Forced disengage** (`S.disengage(reason)`, v4.7.215): leave on a TACTICAL judgement, not an HP reading. The ladder below is entirely reactive, which is useless against an enemy whose kill pattern is "apply an unsurvivable lock, then wait" -- by the time HP crosses `escapeAt` we are locked, and a locked character cannot be relied on to execute an escape at all. Drives the same proven ladder and the same recovery gate, so we do not return until the lock is gone. Returns FALSE rather than pretending (disabled / 10s cooldown / bound / no validated route / the one retreat already spent, v4.7.482), and a FAILED attempt does not stamp the cooldown -- the caller that read the fight as lethal retries the moment a route exists. Returns TRUE while a tumble is in the air (`S.moveLocked()`, v4.7.483): that tumble IS the disengage. First consumer: Seasone's second phial burst. **Low-HP escape ladder** (v4.7.114-115, `swarm.escape` on, `escapeAt` 35%, HP-gated ONLY — a 2-mob chip-down killed below the swarm threshold, and shield-in-place fails with broken arms): outdoors → fly + hover (state `recovering`, attacks hold-gated, 60s cap; **the hover checks its own premise every tick since v4.7.321** -- a death had dream horrors FLY UP after us, knock us out of the sky, and hold us on the ground attack-gated for 52s because nothing checked. It judges the air only once we are IN it: airborne evidence for THIS hover is gmcp's "Flying above" (stamped by the `gmcp.Room` handler at the rename and by the tick) or the ring's fly line after this hover's send, and the checks run `ARRIVE_SETTLE` after the first of those, never from the fly SEND (FLY needs balance, and until we leave, gmcp correctly lists the ground we are fleeing -- the first cut killed hovers before takeoff on exactly that). `S._hoverCompromised` ends it when a hover SEEN up no longer says "Flying above" (not under dementia, not when gmcp names no room), when a denizen is in our company while up, when there is no airborne evidence at all after `FLY_CONFIRM_MAX` 10s, or on trigger `mnemosyne/091`'s flyer lines; it releases BOTH holds (recovery hold AND escape mode), lands if there is any evidence we are up or else `cq all`s the still-queued fly, latches `S.grounded` only for causes that LIVE on the ripple (never for a fly that merely did not take; `M.onRippleReset` clears it), and re-runs the ladder only if its conditions still hold, else the basher fights. `S._bound()` (webbed/entangled/transfixation/impaled/paralysis/bound/daeggerimpale) makes `_canFly`, `_beginEscape` and `_escapeRouteReady` false -- bound, we neither fly nor leap, so the low-HP paths arm, announce and flush nothing. An escape just started OWNS the situation for `S.ESCAPE_OWN` 8s: onVitals and the tick no longer reset it and re-run the ladder from a clobbered anchor) landing only FULLY healed (`recoverAt` 95% AND aff-free; kept defences blindness/deafness/curseward/insomnia never hold it); indoors → plain retreat to the cleared room; no route → shield fallback; SLC bothArmsFlee is inert in the tower; **landing SETTLES, never decides** (v4.7.125 live catch: airborne gmcp Char.Items reflects the SKY so denizensHere is empty — the landing tick is consumed and the arrival settle window opened, else the explorer reads a mob-filled ground room as "clear" and walks out on touchdown). Ladder live-validated end-to-end 2026-07-27 (19% → fly → hover-heal to 99% → land → resume; Blazing affix smokes hovering flyers ~511 asphyx/5s but the hover out-heals it). **Live-validated** (2026-07-26): icewall chain drains across balance (point) + eq (leap), ~7s, inside the 8s hold; **denizens WALK THROUGH icewalls without Maklak's Promise** (wall = pacing, not barrier); kite fly line = the ring of flying. **Emergency hardening after the Pinnacle death** (v4.7.116 — 3 angelic razers + a roamed-in inquisitor, ~3k HP/s incoming, razer psychic applies STUPIDITY which EATS queued commands): (1) `S.onVitals` on `gmcp.Char.Vitals` runs the panic/escape gates EVERY prompt (fresh gmcp read, hp<=0 = blackout-unknown, 2s cooldown, acts even mid-pull via `M._disarmMove()` — the tick path is event-starved in a stationary fight and its one look landed on a potash bounce); (2) a lost pull move RESTORES the route anchor from `S.funnelRoom`/`S.fwdShort` and **RETRIES immediately** (v4.7.235, bounded by `S.PULL_RETRIES`, hold re-armed each time — going idle relied on the next tick, and the tick is EVENT-driven, so in a stationary slugfest the gap measured FOURTEEN seconds) (was: `_tacticalArm`'s fromRoom clobber → "no valid pull route" → permanent noTactics latch); (3) `S.flightConfirmed` fed by trigger 022_Flight_Lines — the hover re-sends fly each 2s tick until the up-line confirms or gmcp says "Flying above" (only the ring's line is captured; v4.7.321), and a fresh hover is preceded by `cq all` (not in lava) so a committed attack cannot take the fly's balance (an eaten fly = grounded-but-gated -- since v4.7.321 bounded by `FLY_CONFIRM_MAX`, not the 60s cap); (4) hovers self-tick from birth. **Wall-leap navigation** (v4.7.119, user-directed): "A wall blocks your way." / "A wall bars your path." during ANY in-flight explorer move → trigger 025 → `M.onWallBlocked()` replaces the walk with `stand;leap <dir>` — never condemns (real exit), shares the ice-slip budget; ALL swarm tactical moves also JUMP (`_tacticalGo` — a plain walk into our own wall livelocked the escape ladder, review CRITICAL). **A TUMBLE IN FLIGHT IS NOT "NOWHERE TO GO"** (v4.7.252; v4.7.482 removed the re-tumble): the mid-recovery re-tumble `and`-ed
four conditions into one `dir`, and the fall-through read a falsy `dir` as "we cannot leave" --
so while a tumble was MID-AIR the move lock made it falsy and the recovery was ABANDONED, the
attack hold cleared and the basher released with the escape still resolving (log: tumble at
13.736, "nowhere to go -- handing back" at 14.841, two attack rounds, then the tumble landed).
"Already leaving" means WAIT, "no route" means GIVE UP; the lock now holds the tick and only a
genuine dead end hands back. **MANALEECH must not hold a recovery** (v4.7.252): a real
affliction at PvP priority 13, under the PARKED floor, so `S._afflicted()` was permanently TRUE
while it was up and every hover burned its full 60s cap -- and in the tower it is re-applied
faster than it is cured. Now in `AFF_IGNORE`, and the rule generalises: blindness or a broken
limb is a state WAITING FIXES, a leech is a state waiting PAYS FOR, and only the first belongs
in a gate whose action is "stand still longer". **THE MOVEMENT LOCK** (v4.7.243, user: "If we tumble and then leap or walk in a direction it
cancels the tumble"): a tumble is ~4s between "You begin to tumble agilely to the <dir>." and
"You tumble out of the room.", and anything else we send inside that window cancels it -- and
FIVE of our own paths did. `S.moveLocked()` reads the state that already exists
(`ataxiaTemp.tumbleDir`, armed by `onTumbleStart`, released by `onTumbleDone`), so there is no
second lifecycle. Guarded: `_tacticalGo`, `_beginPull`'s arm-timeout fallback, `_maybePanic`,
`_beginEscape`'s hover, `_beginReenter`'s wall branch, and the
explorer's `_exploreMove`/`onIceSlip`/`onWallBlocked`. **`S.onVitals` was the worst**: a Roll
Hide pull tumble leaves `state == "pulling"`, whose only early return is the `recovering` one,
so two seconds into a four-second tumble it fired `cq all` + `_beginEscape`. `_maybeTincture`
is deliberately OUTSIDE the lock -- healing is not movement, and mid-tumble at crash HP is when
it is worth most. **ESCAPE MODE** (v4.7.243, user: "We should've stopped attacking here and put
a priority on leaving the room"): `ataxiaTemp.escapeMode`, the single authoritative "are we
trying to get out?", read by both `ataxiaBasher_attack` and `ataxiaBasher_tryAttack` (which was
also missing `bardComposeHold`/`phialHold` entirely). Armed at `_tacticalGo` -- the choke point
every tactical move passes -- plus the panic tumble, the no-swing pull fallback and
`_onPullSent`; cleared when the room number ACTUALLY CHANGES, on reset, and at
`ESCAPE_MODE_MAX` (12s). **It arms at `_onPullSent`, never `_beginPull`**: a pull's escape RIDES
the next attack (the `swarmPullDir` decorator makes the round `<attack>;<backdir>`), so gating
at arm time starves the swing carrying the step-out. `_beginEscape` does not arm at all when
there is no route back -- fighting in place is then the best answer and muting the basher would
be lethal. **IT USED TO ARM AND ANNOUNCE FIRST, THEN RELEASE SILENTLY (v4.7.314).** `escapeOn`
only prints when `_escapeAnnounced` is falsy and only `escapeOff` clears that flag, so the live
death log's SIX banners in 1.7s were six arm/announce/release cycles -- and each release was a
window the prompt dispatcher put a full attack round through, while the banner said the opposite.
Two rules out of it: **do not tear down (or mute, or announce) until you know you can replace it**
-- `S.disengage` had the same shape, calling `S.reset()` (which sends `cq all`) before asking
whether an escape was even possible, now gated on the side-effect-free `S._escapeRouteReady()`;
and **a hold stops the NEXT round being queued, it cannot retract one the server already holds**,
so `_tacticalGo` now sends `cq all` before its move (the escape rides the FREE queue, a committed
attack rides the STANDARD queue, and the attack takes balance first -- which is why the `-> e`
landed with nothing to backflip on). That flush is skipped in LAVA, where the queued escape is
the one command keeping us alive, and never reaches the PULL path, whose escape rides the attack.
**The validated-route rule now has the lava exception** (`S._escapeLastResort`, user-directed):
`_backDir` returns nil whenever `explore.fromRoom == MAP.current` or the anchor is stale -- both
NORMAL after a pull, a tumble or a forced move -- and the room that killed us had an east exit the
whole time. When `S._dyingFast()` (the time-to-death watchdog, or the ABSOLUTE `panicHp` floor --
**not** `_panicHpHit`, whose `panicAt` defaults to the same 35 as `escapeAt` and would make it
fire always), any planar exit that is not known lava beats standing. It reuses `S._panicDir` as
the scanner and echoes the downgrade loudly, because a deliberate rule-break that reads like an
ordinary retreat is indistinguishable from a bug. Also v4.7.314: `onTick`'s low-HP branch had **no
cooldown at all** where `onVitals` had `EMERGENCY_COOLDOWN`; it now shares both the constant and
`S._lastEmergencyAt`, since two unsynchronised clocks on one emergency is how the churn returns. **The ice-slip recovery re-sent the WRONG COMMAND** (v4.7.243): `M.onIceSlip` called
`_exploreMove`, which sends a bare `stand;<dir>` WALK -- discarding the leap/backflip the
retreat was, and a walk into our own icewall silently fails. With `MAX_ICE_SLIPS = 15` that
cost thirteen seconds in the room that killed us. Tactical slips now hand back to
`S.onMoveFailed()` (which re-sends the swarm's own verb, anchor restored, hold re-armed) under
a separate `MAX_TACTICAL_ICE_SLIPS = 3`. **The escape pull HOLDS the attack dispatcher** (v4.7.235): the hover branch always armed the hold, the indoor pull branch did not, so the next attack's `queue addclearfull` — which clears the FULL queue — threw the queued escape away. A Seasone log shows THREE complete attack rounds between the disengage and "pull move lost". General rule: **anything we queue that is not an attack must hold the dispatcher.** **The tumble CHAIN** (v4.7.245): `_roomHasDenizens()` reads `ataxia.denizensHere` (gmcp `Char.Items`), which LAGS the room change -- so the recovery tick firing on arrival reads the PREVIOUS room's company and tumbles again. A live log shows four tumbles in nineteen seconds through rooms whose descriptions named no denizens at all, while the Ablaze affix took ~1,200 per tick: HP 31% -> 14% and stuck, because a recovery that keeps moving never recovers. Same class as v4.7.125 (airborne `Char.Items` reflects the sky) with the sign flipped. `S.ARRIVE_SETTLE` (1.5s from the tumble RESOLVING, stamped in `onTumbleDone`) consumes and re-schedules the tick rather than deciding on stale data, and a future-dated stamp cannot wedge it (`since >= 0`). **ONE RETREAT, THEN WE FIGHT** (v4.7.482, the user's rule after a death: seven retreats in 35s between a 3-denizen room and a 1-denizen room, sent by three paths that did not know about each other): the re-tumble and its `S.RECOVER_TUMBLES` budget are GONE. `S.retreatSpentAt` is armed on the LANDING (`S._noteLanding`, so a refused leap or a lost tumble spends nothing; since v4.7.483 every reader and writer of the record calls it first, because a landing's GMCP precedes its text and the basher's vitals handler runs before ours, and `S.disengage` returns true while `S.moveLocked()`) and refuses, at any HP, the panic tumble, the ground escape, the disengage and a new pull (`S._retreatBlock`, `_maybePanic`, the `onTick` pull gate); a denizen in the landing room is fought by the basher. Not a walk into another room of the fight, so still allowed: the outdoor hover, the Seclusion fling, the lava escape, a retry of the same tumble. Given back (`S._restoreRetreat`) when the room is empty and `_mayReturn` holds (else heal there first), when a recovery ends, at a fit re-entry, on Righteous Fire and on a reload; `S.onRipple` clears it too. `S._retreatInFlight` holds a recovery while its own panic tumble waits in the queue for balance (at most `TUMBLE_ARM` 8s), since the next attack's `addclearfull` would wipe it. **"You cease your tumbling." was never wired** (v4.7.245): `misc_alerts/003` printed a banner and `cq all`-ed for years without telling the swarm, so a cancelled tumble sat on `tumbleDir` until the `TUMBLE_CONFIRM` fallback expired -- and v4.7.243 made that state a MOVEMENT LOCK, so those were seconds in which nothing could move. The log measures it at 4.5s at 14% HP in a burning room. `S.onTumbleCanceled()` retries immediately, sharing `_tumbleRetry()` with the timer path; ordered AFTER the trigger's `cq all` so the flush cannot wipe the retry. **A fallback timer is for when the game says NOTHING -- when it names the failure, use it.** **Tumble confirmation** (v4.7.233/234): the "begin to tumble" line is the START of a two-stage action — paralysis or prone between the halves cancels it and killed us once. "You tumble out of the room." is the completion line (`misc_alerts/005`); the room-change fallback waits `S.TUMBLE_CONFIRM` = 5s because a real tumble takes 4.0s and a 2s window would re-send one that was working — *a retry window must outlast the action it guards*. **Vitalising Tincture** (v4.7.241, boon-gated): 33% max health / 20s, fired at `escapeAt` from `onVitals` BEFORE the flee decision; `ataxia.mnemosyne.tinctureCmd` is nil by default because the command is unconfirmed. **Which jump: `S.moveVerb(dir)` (v4.7.217)** -- **`mountjump` whenever we are MOUNTED** (v4.7.345, answered BEFORE the wall and the class, since the saddle refuses both the leap and the backflip), else **`backflip`** for a Bard (faster balance; user, 2026-08-06) and **`leap`** for everyone else. The normal sweep already WALKS (`_exploreMove` sends a bare direction), so there was never balance to save there. LEAP is KEPT wherever a wall is known to stand (`_escapeSuffix` wall-mode both branches, the wall-mode re-entry, the explorer's wall-blocked reflex) -- those four ask `ataxiaBasher_mountVerb("leap")` rather than `S.moveVerb`, deliberately, so that mounting substitutes the mountjump while ON FOOT the verb stays exactly what it was: those jumps exist to clear our OWN icewall and greaves-LEAP is the ability confirmed to do that in both directions, whereas whether BACKFLIP crosses an icewall is NOT confirmed -- and guessing wrong is not a slow move, it is a silent no-op in the indoor low-HP escape, i.e. the anti-death ladder livelocking at crash HP. `moveVerb` disambiguates from `wallRaised[room]` and falls back to LEAP when the wall state cannot be resolved; the melt is hold-armed, cleared only on the melt-confirm line (trigger 026 → `onWallMelted`), re-sent while unconfirmed, capped at 4 tries; wall memory survives mid-ripple `mnem explore off/on` (wiped only on genuine ripple change) and the panic tumble avoids the walled edge; legacy `766_Wall` manual branches are gated off during explore. **Damage-suppression affixes** (v4.7.186, trigger `mnemosyne/053` -> `M.onDamageNulled`/`M.damageNulled`): the Ongoing-effects block can carry `Null Magic: All magic damage you deal is reduced by 33%.` -- one member of a family whose other affix NAMES are unknown, so the trigger parses the SENTENCE, which always names the type itself. Covers every present and future sibling without a name table that goes stale. Stored on `ataxiaTemp.mnemNulled` (NOT under the saved `ataxia` namespace -- a run-scoped fact must not persist across sessions), cleared on RIPPLE CHANGE as well as run start/end since the effects block is re-read from each ripple's WADE STATUS. First consumer: **`ataxiaBasher_bmInfuse`** -- Shindo INFUSE chooses our damage type, so unlike most affixes this one can be stepped around. `fire`->fire, `void`->MAGIC, `lightning`->ELECTRICITY, `ice`->COLD; note the two that do NOT match their own name, so a Null Magic ripple must move us off VOID rather than some element called magic. Preference **`lightning`->fire->ice->void** (`ataxiaBasher.bmInfusePrefs`, v4.7.269 user-directed); never returns nil, since an empty infuse would break the attack string, and the literal last resort now matches the head of the order rather than contradicting it. The old head was `fire`, and that was never a damage judgement -- v4.7.186 put it first purely so introducing the function behaved exactly as the hardcoded `infuse fire` it replaced. The class's own PvP offense had always disagreed (`levi_scripts/blademaster/003_BrokenStar.lua` infuses LIGHTNING in every branch), so the PvE basher was the odd one out.

**INLINE INFUSE (v4.7.273, game announcement #174).** `drawslash <t> infuselightning sternum` replaces `infuse lightning ; drawslash <t> sternum`. **Not tidiness:** `infuse` as a separate command sat in a chain `queue addclearfull` rebuilds every prompt, and a command that does not wait on balance EXECUTES ON EVERY REBUILD rather than once per swing -- the mechanic that had `shin augment` refused five times in 0.45s (v4.7.270). Woven in, it can only fire when the attack does, once per balance by construction -- which also means the v4.7.269 shin budget was rationing a spender whose real consumption had never been measured. `infuse<element>` is ONE WORD because the announcement says why (a bare element name clashes with server-side targeting against elemental denizens). **Token order is inferred from the announcement's single example** (attack, target, [direction], infuse<element>, body part) and the failure modes are ASYMMETRIC -- a malformed `infuse X` costs the infuse, a malformed inline attack is rejected WHOLE and costs the swing -- so `bash inlineinfuse off` (`ataxiaBasher.bmInlineInfuse`) restores the two-command form. PvP (`blademaster/002`, `003`) is deliberately unchanged: it queues with `addclear FREE`, which ACCUMULATES rather than being wiped, so the re-execution argument does not transfer.

**THE SHIN BUDGET (v4.7.269).** `infuse` was the ONLY shin spender in `ataxiaBasher_blademasterBashing` with no arithmetic behind it -- no cost check, no hold, no cooldown, no place in the one-spender rule -- and the only one that fired on EVERY round, which made it plausibly the largest sustained draw in the whole economy. In the tower it now requires `shin > ataxiaBasher.bmInfuseAt` (**90**). **90 is DERIVED**: `SHIN PHOENIX` needs 80, so infusing only above 90 leaves more than 80 afterwards -- an infuse can never be the action that takes Phoenix off the table. Tower-scoped (`inMnemosyne`) since nothing is being saved for outside it. The infuse's own cost is **NOT verified** -- `.claude/classes/blademaster.md` states 5 shin with no AB capture behind it, and the only code enforcing that arithmetic is the PvP airfist gate (`25 = 20 + 5`) as an opaque total -- which is why 90 is a tunable with its derivation documented rather than `80 + a constant we would be inventing`. The gate lives in the CALLER, not in `ataxiaBasher_bmInfuse`, so that function stays a pure element-chooser and its suite does not have to mock shin and the tower. When cutting damage is suppressed and shin is below the floor the sweep **echoes once per ripple** -- the user's rule is that the floor holds anyway, so we are knowingly swinging into a resistance, and a deliberate trade the log never mentions is indistinguishable from a bug.

**SHIN PHOENIX (v4.7.269, AB 321).** `SHIN PHOENIX`, self, **requires 80 shin and CONSUMES ALL OF IT**, cleanses almost every affliction **and returns us to full health** (user-confirmed; the AB states only the cleanse, so the heal is knowledge its text does not carry, and it is why this is worth automating). Fires at `hpp <= ataxiaBasher.phoenixAt` (**10**) with 80+ shin. **`hpp > 0` is not redundant** -- a zero reading is BLACKOUT, the idiom `ataxiaBasher_dangerLevel` already encodes (`if hpp == 0 then return "wait" end`), and a bare `hpp <= 10` would empty the pool every time we lose sight of our own health. It is placed **FIRST in the round** and sets `shinSpent`, because there is no round planner here -- shin priority is hardcoded position. Since it consumes the whole pool the `>= 80` gate is its own re-fire guard, so no cooldown was invented; our own cast line is uncaptured (the only phoenix trigger in the tree, `passive_active/010`, is the OPPONENT-side line for an enemy Blademaster). Worth trying at 35-40 rather than 10 once proven: `escapeAt`/`panicAt` are both 35, so at 10% the ladder has already spent the tumble and the ground -- a Phoenix at 35 would PREVENT that where one at 10 only rescues it.

**Putting Phoenix first exposed two latent traps in the augment block**, neither of which was style: it had no `shinSpent` check and it wrote `command = "shin augment "..` -- an **ASSIGNMENT** -- because nothing had ever preceded it. The phoenix was built and then silently destroyed, and the round went out with the augment alone. **A "one spender per round" rule enforced by position alone breaks the moment the positions change.** **Deluge affix** (v4.7.140, trigger 037 → `onDelugeSeen`, same shape): "All rooms are underwater" makes FLY impossible — `S._canFly()` gates the escape ladder's outdoor fly+hover (falls through to the grounded retreat / shield fallback) and the fly-kite entry, so neither wedges on a silently-rejected queued fly. **Dragged out of the sky** (v4.7.168, trigger `mnemosyne/050` → `S.onDraggedDown`): "A tentacle shoots up from the ground, wraps itself around you, and drags you back to earth." — a DENIZEN can pull us out of the air. Third way flight fails after Deluge and an eaten FLY, and the worst, because it is SILENT to the state machine: the hover keeps `S.flying` optimistically true until a flight line confirms (the guard that exists because stupidity eats queued commands), and after a drag that confirmation never comes — so the hover re-sends `fly` EVERY TICK while the tentacle yanks us back, holding us attack-GATED at crash HP until `RECOVER_MAX` expires. Latches `S.grounded` (honoured by `S._canFly` and hence `S._canHover`), corrects the flight state, and converts an in-progress hover into the grounded retreat. **Per-RIPPLE** — `S.onRipple` clears it. **BOILING LAVA -- the only unconditional "leave now"** (v4.7.254, hardened v4.7.256, trigger `mnemosyne/064` → `M.onLava`/`M.roomLava`): `You splash into boiling lava!` / `You continue to struggle in the boiling grasp of the lava as it eats away at your body.` -- **5,890 UNBLOCKABLE per tick** against a 10,939 pool, i.e. 54% of the pool, two ticks is a death, and unblockable means no shield, barrier or resistance helps. Every other hazard here can be fought through (Ablaze is ~1,200 and only gates the hover), so this is **the exception to the validated-route rule**: the escape ladder refuses unvalidated exits by user decision, but staying costs half the pool per tick, so ANY door beats the floor. **Exit order changed in v4.7.297, user-directed** (live log: exits north and west, the old order picked north -- the room already cleared -- while west led into the unswept grid): an exit `MAP.unexploredExits` has never walked now outranks the room we just left. **And again in v4.7.318, from a death: ANY forward door outranks back, walked or not.** The entry damage is SUNK -- "once we enter the room, we already take the damage" -- so retreating buys nothing against it and guarantees paying it again, because whatever drew us in (a denizen standing in the lava, an exit beyond it) is still there and the sweep or patrol routes straight back. In a well-fought room every door has a walked edge, nothing is "unexplored", and v4.7.297's pass found nothing; the death log shows enter / 5,890 / retreat / re-enter for the phantom grizzly / 5,890 / ... The order is now: any UNEXPLORED planar exit (sorted, excluding known lava) → any FORWARD planar exit not known lava (sorted, i.e. anything but the way we came) → back the way we came (last resort: provably not lava, most likely to bring us straight back) → the blind fallback → `down`. **`_nextPatrolStep` had NO lava filter at all until v4.7.318** -- the sweep and backtrack learned it in v4.7.256, the patrol's only test was `planarStep`, so once the grid was swept it round-robined the lava room forever; it now skips a known lava TARGET and a known lava first-step EDGE. The target check is not redundant: a prose-sourced exit (`0`) is unresolvable by `_exitTarget`, and `lavaEdges` only knows the door we splashed through, so a lava room reached by any other door is invisible to the edge check. **GLANCE RECON (v4.7.318, user-directed):** the sweep glances every door it has never walked before stepping (`M._glanceWanted`/`_glanceStart`, `GLANCE_TIMEOUT` 1s) -- GLANCE is free and prints the neighbour's description and exits line. It never refuses a room (the rule is enter and pass through); it PLANS: "Molten lava bubbles and churns." inside a glance (trigger `mnemosyne/090`) makes `_glanceResolve` record `ataxiaTemp.mnemLavaPlan = {room, dir, fwd}` from the glanced exits, and `onLava` fires `fwd` on the splash instead of deriving a door under fire. The glanced exits reach 008 because 005's one-shot glance token -- which existed to DISCARD a neighbour's exits line (v4.7.262) -- now also publishes it (`M._onGlanceExits`, guarded). Backtracks over walked edges get no glance. `ataxia.settings.reporting.glance = false` turns it off. `MAP.parseExitsLine` returns a SET keyed by long direction, not a list -- iterate with `pairs`. **Four review hardenings, same version:** `onLavaSeen` only counts a description line while the header token is armed for the pending direction (our OWN room's description prints on arrival/LOOK/ql and would otherwise mark the neighbour); the resolve re-ticks only if we are still in the room we glanced from (`_scheduleTick` is last-call-wins and would otherwise kill an arrival settle if something moved us mid-glance); the tick gate force-resolves a glance older than 3x `GLANCE_TIMEOUT` (a lost timer must not hold the sweep forever); and `_lavaExit`'s forward AND fallback passes use `edgeIsLava`, not `lavaRooms[_exitTarget]`, because a prose exit's destination is unresolvable and only the EDGE remembers a neighbour we splashed into from here. **v4.7.319 (the full multi-agent review of v4.7.318, probe-confirmed):** the patrol filter had created a LIVELOCK -- a lava room with its own unwalked exit was still a backtrack TARGET, refused only at the first step, so the sweep and patrol traded steps forever; the backtrack now never targets a lava room and both backtrack and patrol check the WHOLE route (`M._pathIsLavaFree`). `onLava`'s plan was gated on `first` (episode timing) instead of `entry` (the splash), so a second lava room entered within the episode gap skipped its plan and inherited the first room's REMEMBERED door -- the way we came; now gated on `entry`, and the remembered door is scoped to the episode's anchor room. Both the planned and remembered doors are `edgeIsLava`-checked at the splash (the plan cannot know at glance time). 005's send capture no longer lets `glance`/`squint`/`observe`/`look` set the last move direction (a look moved us: phantom walked edges). A glance pending for a room we LEFT is dropped at the gate (v4.7.318's settle fix otherwise stalled 30s). No glance while BLIND. `mnem explore glance [on|off]`; `mnem explore status`/`why` show the glance state. An unexplored room CAN be lava -- that is what unexplored means -- but the worst case is one more tick of damage before the next struggle line re-picks a door, where refusing to explore never recovers the sweep. Holds the attack dispatcher, resets any swarm tactic, re-sends every tick (an eaten move must be retried), and on no known exit sends `ql` and says **MOVE MANUALLY**. Both lines are used: the splash is entry, the struggle is the tick, and the tick fires without an entry line when we were already standing in it. **v4.7.256 was a DEATH**: marking the room caught one code path and three others still led back in -- the sweep BACKTRACK (once the room was walked its exits stopped counting as unexplored, but the unexplored exit BEYOND it made lava the shortest path, and `MAP.path` has no hazard filter), `S._backDir` (the room we came from is normally the safest square) and `S._panicDir`. **Remember the EDGE, not just the room**: room-keyed marking is unusable from the room next door, because `_exitTarget` returns nil when gmcp has not filled a destination id -- exactly the case for an unvisited neighbour. `M.explore.lavaEdges[from][dir]`, recorded at the moment we splash, needs no id from anyone; shared predicates `M.roomIsLava`/`M.edgeIsLava` feed all four consumers. The backtrack checks only the FIRST step (every step is re-decided on arrival, so a route we never enter is one we never traverse), and `_backDir` returning nil drops the ladder to shield-in-place -- bad, not fatal. **"We walked through it" is not the same fact as "it is survivable."** Two guards found while testing: a stale `explore.fromRoom` (current only after a sweep step, not a tumble or chase) would mark an edge out of a non-adjacent room and refuse a good exit forever, so recording requires `from ~= cur`; and both exit scans are SORTED, because an unordered choice makes the log unreadable and made the guards untestable.

**A BOSS THAT RUNS AWAY** (v4.7.255, triggers `mnemosyne/065`+`066`): `Lyaeus, the travelling bard flails in panic.` then `... a satyri bard strolls out to the southeast, ...`. **The two lines name him differently** -- proper name on the panic, generic denizen description on the departure -- so neither suffices alone: the panic says WHO, the departure says WHERE, paired within a 6s window. A boss ripple only ends when the boss dies, so a boss that leaves is not a fight we can decline. `M._chaseRefusal(dir)` is split from the send so every refusal is named and testable (nothing panicked / escaping / recovering / lava / too hurt / budget spent / basher off); **never chase while leaving** -- adding a pursuit to a retreat is how a retreat becomes a death -- and the budget is 4 per ripple since a boss kiting us across the grid is its own hazard. The HP guard is DEFAULTED (35) rather than conditional: a guard that evaporates on a missing config key would chase at crash HP on a fresh profile. **THE DEPARTURE LINE HAS TWO GRAMMARS** (v4.7.272): trigger 066 matches a direction FRAGMENT with the directions enumerated rather than the whole sentence -- because every denizen words its exit differently ("strolls"/"prowls"/"stomps") and enumerating VERBS is how you get a trigger that works for one boss and silently misses the next. That axis was right and the chosen invariant was wrong: `out to the <direction>` was **Lyaeus's** fragment, not a shared one, and `Celepharn, High Priest of Life` uses a different syntactic FRAME -- `The muted rustling of fabric accompanies Celepharn as he departs east.` The panic fired, the departure never matched, and the boss walked. The pattern is now `(?:out to the|departs?(?: to the)?)`. **One boss is not a sample.** The whole line is passed through as well, and it can only STRENGTHEN: Celepharn's departure names him where Lyaeus's says only "a satyri bard", so a name match PROVES identity while a non-match proves nothing and must still be followed (`M._fledLineNames`, compared on the FIRST WORD since the panic line carries a comma-title the room line omits) -- implemented as a veto to check, it fails four tests including the original follow. Safe because it decides nothing alone.

**Burning rooms** (v4.7.167, trigger `mnemosyne/049` → `M.onAblazeBurn`/`M.roomAblaze`): "The area is ablaze!" + "The roaring inferno engulfs you as you fight to find a way out." for ~800 every few seconds, indefinitely. Latched on the BURN LINE not the room description, so it self-expires when we leave (no "fire goes out" line has ever been captured); gates `S._canHover` — flying up to heal is a bad plan over a fire that follows you. The KITE is deliberately not gated: it lands for every swing anyway. General rule: **an optimistic flag cleared only by a CONFIRMATION line becomes a livelock the moment something makes that confirmation impossible** — such a flag needs a third input, the line that says the thing can never happen. **Haemophiliac affix pacing** (v4.7.119-120, trigger 029 → `onHaemophiliacSeen`, Splinterbark's telemetry-independent shape): kills bleed THOUSANDS + mana costs +20% — post-clear navigation holds until the bleed is CLOTTED (`ataxia.vitals.bleed < 50`; SSC `curing clotat 30` does the clotting) AND `hpp >= 90` (`M._haemoHold`, missing reading = 0 so it never wedges). The dmap standalone package mirrors the pull/funnel core (`dmap swarm <n|off>`, default off — no basher there, so the funnel waits on the user/attack-hook). Recon: **Bloodscent** (boon) auto-senses every denizen per ripple entry — trigger 028 parses `You sense <mob> (#id) at <room>.` rows into `swarm.recon` ({name,id,room} + per-room counts + crowded-room callout echo); Sleuth's `mnemSleuth` → fullsense on GO (raw capture; same-shape rows feed the parser); `mnem sense` manual. Tests `test_swarm_tactics.lua`. Full doc: `.claude/projects/mnemosyne/07-explorer.md` swarm section.

**Borrowed Power changes our GEAR (v4.7.204).** "Critical hits reach plane-razing level without requiring paragons or the Psion class -- this does NOT stack." The non-stacking clause makes the crit-TIER paragon (`crucious`) dead weight, so `ataxia.armour.borrowedPower(true)` builds a `borrowed` profile from the bash one with that slot replaced by the shifting-damage or willpower paragon and hands it to the existing `ataxia.armour.swap` (which owns the pry/insert sequencing, morph handling and swap guard). `icosagon` is deliberately kept -- it buys crit CHANCE, which the boon does not grant. **The revert is the risky half:** the boon is per-RUN, so a swap left in place costs the crit paragon everywhere OUTSIDE the tower indefinitely -- reverted on the confirmed run end, with `armour borrowed off` as the manual escape hatch for a run that ends without one. Swapping runs from the `BOON CLAIM` intercept as well as the BOONS row, because claiming happens at the boon screen: out of combat, explorer paused, the only safe moment to pry armour apart. **General rule: a per-run boon that mutates persistent state needs its revert designed before its effect.**

**Bard PERFORMANCE probe (v4.7.204).** Every other thing that tracks the bash performance is REACTIVE -- the fade line, the not-performing error, the already-performing refusal -- and each needs something to go wrong first. `M._bardPerformanceCheck` (explorer 008, both entry points, beside `_wearArmour`) ASKS instead: sends `performance`, stamps `ataxiaTemp.bardPerfProbe`, and trigger 001 clears it on the "shall last another N minutes" reply. Nothing clears it in 2s -> not performing -> recompose. Handles a reply wording we have never captured without inventing one.

**A dance is a STATE, not a rider (Songstep, v4.7.200).** Every other Mnemosyne rider in this package spends EQUILIBRIUM, so it rides free beside the swing and can be re-asserted whenever its defence drops. The Bard's Bladedance dances spend **BALANCE** (AB Hawkstep 3193: 3.00s) and are mutually exclusive ("you can only dance one thing at a time"), so a dance costs the attack and can only be SWITCHED. `ataxiaBasher_bardDance` therefore returns `""` on almost every round -- it fires only when the wanted dance differs from what is up, then holds 8s so an unconfirmed dance cannot cost every balance. On a switching round the dance REPLACES the swing (the battlerage still rides -- rage, not balance). Choice: boss -> **wavedance** (ignore 75% resistance), 2+ denizens or ripple >= `bardHawkstepRipple` (**25** -- the user's number for where the tower's difficulty steps up; an earlier guess of 5 anchored on the boss cadence, which is not the same thing) -> **hawkstep** (25% DR), else **harrying** (+50% damage); boss beats crowd. One knowingly-unverified bit: `hawkstep`/`wavedance` as GMCP defence names are inferred from `harrying`, which IS tracked -- the attempt-hold is what makes that safe to ship, since a wrong name costs one dance per 8s rather than one per round. **Rule for any new ability: check the RESOURCE first -- equilibrium/word/rage ride, balance replaces, and a mutually-exclusive balance ability is a state machine, not a keeper.**

**TEMPO: VIVACE (v4.7.311).** AB Tempo 3159 now lists a fourth tempo, Vivace 1/6/5. The 2026-09-16
analysis (`.claude/classes/bard.md`, "Tempo: the numbers") puts it first in every regime -- 5 of 12
hits from the back alone, 5 of 6 with a flourish at each return to front -- and the ranking does
not depend on the unmeasured base back bonus. It is the default (`bashTempo`, a saved moderato
migrated once), the boon-free FOOTWORK FLOURISH is ON by default (v4.7.312, user: "We should flourish
from the front to get to the back") on the tempos where the lost balance pays (Vivace always;
Adagio/Moderato only with Shadow Tempo; never Allegro/none), read from the GAME's tempo line so an
unlearned Tempo keeps it quiet; `bashflourish always` drops the tempo rule, `bashflourish off`
leaves flourish to the boon. **THE POSITION TRIGGERS COULD NOT READ A DENIZEN (v4.7.313, live
log):** `tempo/001-003` took `\w+` for the partner's name -- a player's one word, never "a royal
guard of Zanzibaar" -- so in PvE `bardtempo` was NEVER updated; Shadow Tempo's back-bonus rule
never saw "back", and the footwork flourish, seeing a "front" that never changed, flourished on
every balance (back -> side -> front, no attack ever landing). `.+?` now, and the pick latches
ONCE PER VISIT TO THE FRONT, released only when the position is seen to leave it -- a stuck flag
costs one balance, never every balance. **A trigger written for a one-word player name is a
trigger that has never fired in PvE; grep `\w+` before trusting any position flag.** The character's ABs show Tempo and
Flourish both Known: No -- Tempo (703 lessons) is the far better buy.

**DEADLY FLOURISH -- THE BARD'S SECOND BALANCE SWAP, AND FOOTWORK DECIDES THE MOMENT (v4.7.301,
`ataxiaBasher_bardFlourish`).** "Your bladedance flourish ability now deals additional cutting
damage to all denizens in your location when used on a denizen. This can only occur once every 15
seconds." User: "if we have this boon, we should use flourish every 15 seconds." AB Flourish
(Bladedance): `BLADE FLOURISH <target>`, **2.10s of BALANCE**, adventurers-only, "may not inflict
any harm" -- its whole base purpose is to "advance two positions through the bladedance
immediately (front to back, side to front, back to side)". Three AB facts, three gates: BALANCE
means it **REPLACES the flick** (the Songstep rule above; the battlerage still rides), adventurers-
only means the **boon is the denizen permit** (`type(target) == "number"`, the Spirit Rend shape),
and TWO POSITIONS means the moment matters for the thing the whole bard basher is built around --
the back-position bonus (AB Footwork, doubled by Shadow Tempo). front->back is a straight win
(skip every front and side swing), back->side lands two hits from back where the natural cycle is
five away, and **side->front is the one loss** (two hits from back becomes five) -- so the pick
**never fires from `side` while `bardtempo` is readable**, bounded twice (the dance leaves side
within four hits; `FLOURISH_SIDE_HOLD_MAX` 10s caps a stale flag, since a hold released only by a
game line livelocks the moment that line stops arriving). An unreadable position FIRES: the rule is
every 15 seconds, and a hold on a fact we cannot read is a hold we cannot justify. **The boon path needs
2+ denizens** (v4.7.313, user: "only use flourish with multiple denizens and the boon, or in the
front stance to get to the back stance (just once)" -- the later instruction; v4.7.302 had removed
the gate at the user's request). The footwork policy covers the lone mob. Send-side stamp + the v4.7.129 in-flight replay
hold as a FLOOR, and **the landed line restarts the 15s from the moment it actually executed**
(v4.7.304, `highlighting/062` -> `ataxiaBasher_bardFlourishConfirm`; captured live: "You weave a
Soulpiercer through the air in a dazzling display, the music of your bladesong sweeping forth to
wash over <target> while your feet shift to a new stance." -- two substring fragments because it
wraps, and neither contains the word "flourish", since HIGHSUN's line begins "With a flourish of
<weapon>..." (`blade_dance/005`)). The line prints with or without the boon, so it does NOT latch
the flag, and the send-side floor stays so a missed confirmation costs one window, never a re-fire. Shielded rounds skip it (punctuate breaks the shield first) and a Songstep dance
switch outranks it for the same balance, without the flourish helper even being CALLED, so it
cannot stamp a cooldown for a round it did not get. Flag lifecycle: BOONS row `mnemosyne/084`,
claim intercept, run-start reset, confirmed run-end reset plus the three `ataxiaTemp.bardFlourish*`
stamps.

**Rimewrought / Famine (v4.7.333, user-directed).** *Rimewrought* ("Perpetual ice coats your body, rendering tattoos ineffective") is the Bravado shape for TATTOOS: `mnemRimewrought` (trigger `mnemosyne/096`) gates every tattoo we SEND on `ataxiaBasher_tattoosDead()` -- the danger-ladder shield, both flee fallbacks, the hostile-player exit, the class-cheese `touch shield`, the Psion `psi manipulate touch tree`, the blackout tree, and the lock-breaker's tree+shield -- and sends `curing tree off`, because the tree of life is a tattoo too (Splinterbark's flag and its run-end restore, reused). **Keep-up too (v4.7.334):** a defence on keep-up sits at `curing priority defence <def> 25`, a standing order SSC obeys forever, so it retried dead tattoos endlessly. `stripTattooKeepup()` resets exactly the tattoos the CURRENT profile asks for (read from `ataxiaTables.classDefences.tattoos`, so a new tattoo there is covered automatically) and `restoreTattooKeepup()` puts back exactly those on run end. **The saved profile is never edited** -- `ataxia.settings.defences` is on disk, and a config an affix edits stays edited after a bad session end; the priority is a game-side setting, like the tree curing beside it. *Famine* ("Taking damage has a chance to make you more hungry...") makes hunger a damage-driven cost, so `mnemFamine` (trigger `mnemosyne/097`) opens `ataxia_hornSatiate` with NO boon held and `ataxia_famineTopUp` runs on every room's last kill (trigger 340): corpse-first with Obligate Carnivore, horn otherwise, and the existing verify chain still stops at "utterly satiated". Both latch only in the tower, are transition-guarded, and clear on run end.

**Bravado REMOVES answers rather than adding a threat (v4.7.206)** -- "perpetually reckless and unable to benefit from shields, prismatic barriers, or blood barriers". Three defensive responses become no-ops while it is up, and each keeps costing us: `touch shield` (the danger-level response AND the escape ladder's fallback), **Maran** (the emergency 5000hp PRISMATIC barrier, charges regenerating ONE PER HOUR -- gated in both the out-of-tower path and the Mnemosyne card layer) and `activate bloodshield` (the cloak's BLOOD barrier, one charge per five kills). All gated on `ataxiaBasher_bravado()`. The shield case is a CORRECTION rather than a saving: the round bought nothing *and* the basher then believed it was mitigated, so `danger == "shield"` now falls through to attacking. Hit-and-run clamps to `swarm.bravadoThreshold` (default 2, user rule), **clamping DOWN only** and covering the deep-ripple threshold too. User's framing, worth keeping: *"we will never know our health pool"* -- with every mitigation off the prompt number is all there is. **General rule: an affix that DISABLES a defence is more dangerous than one that adds damage, because the code keeps paying for the dead defence and keeps believing it worked -- when a new affix names a mechanic, grep every site that spends on it.**

**Pacing affixes (v4.7.196).** Two affixes make the instant a room goes quiet the worst instant to walk, so the auto-explorer carries two post-clear holds, both gated on 90% HP and both re-checking at 1.5s: **Haemophiliac** (`M._haemoHold`, also waits for the bleed to be CLOTTED, since SSC's `curing clotat` is doing real work while we stand still) and **Last Word** -- "Denizens explode on death!" (`M._lastWordHold`, HP only: an explosion is instantaneous, so there is nothing to clot and waiting on a bleed reading would just idle the sweep). Either holding is sufficient. Affix flags are now three (`mnemHaemophiliac`, `mnemDeluge`, `mnemLastWord`) plus the damage-suppression family on `ataxiaTemp.mnemNulled`, so the run-start reset block is **30 boons + 3 affixes = 33 lines** -- never read a boon count off that block. Captured in the same screenshot but deliberately UNHANDLED pending observation: **Necromantic** ("Denizens may revive as mindless thralls" -- potentially significant, since a room that clears then repopulates from its own corpses is exactly what `_roomHasDenizens` is trusted for) and **Iceblood** ("Taking damage causes your blood to freeze").

**HEALING METABOLISM IS THE SATIATION SKILL, CAST BELOW AN HP THRESHOLD (v4.7.452-454) -- this
supersedes the Healing Metabolism parts of the v4.7.294 and v4.7.303 notes below.** "The satiation
defence" is not a full stomach. It is the Survival ability SATIATION (AB 1390: 4.00 s of equilibrium,
100 mana), and `satiation` is a DEF name. **The skill alone gives it** (user's screen, 2026-10-26: GMCP
`+ ( def satiation ) +` came before "You begin concentrating on efficient digestion.", with no food),
and it is TIMED: about 11.3 s, ending "Your digestive efficiency returns to normal." v4.7.452 ate a
corpse or a horn item with every cast; at one cast per ~11 s that empties the six-item horn in a
minute, so v4.7.454 removed the meal. Whether food lengthens the defence is not tested. Kept up all
the time it would cost ~9 mana/s and a third of equilibrium, so (user's choice) `ataxia_satiationTick`
(`misc_scripts/022`, on every `gmcp.Char.Vitals`) sends `satiation` directly only while health is below
`satiationHpAt`% (default 75, `horn hp <n>`), with the boon held, the defence absent, equilibrium free,
mana >= 100 + `satiationManaFloor`% (default 30, `horn floor <n>`) and no
paralysis/stun/unconsciousness/asleep. GMCP `Defences.Add satiation` confirms; no Add in 5 s is a
failure, and 3 in a row stop it for 300 s, with an echo that says whether the activation line (trigger
791) was seen. A `Defences.Remove` re-checks at once. The SCORE hunger upkeep and the kill corpse
top-up serve FAMINE only; `satiatePoll` and `ataxia_satiateKillCheck` are gone. **The advisor's
Healing Metabolism <-> Obligate Carnivore pairing (v4.7.368) is removed**: corpses add nothing to a
skill-only defence, so `M.BOON_SYNERGY` is empty.

**OBLIGATE CARNIVORE + HEALING METABOLISM -- FOOD BECOMES UPKEEP (v4.7.294,
`ataxia_carnivoreEat`, `misc_scripts/022_Horn_Of_Plenty.lua`).** The horn exists because starvation
knocks you UNCONSCIOUS -- an emergency. Healing Metabolism ("health elixirs 50% more effective while
you possess the satiation defence") attacks the same axis from the other end: satiation stops being
a floor to stay above and becomes a DEFENCE WORTH HOLDING, and Obligate Carnivore ("you can EAT
corpses") supplies the food for free, delivered automatically since `340_Slain` ends "...retrieving
the corpse". **Corpses outrank the horn whenever the boon is held** -- a horn charge is one of six
on its own refill clock, a corpse is already in the pack. **Nothing is guessed**: the boon gives the
verb and every other piece is proven in-tree (`ii corpse` from `176_Butchering`, the row->id parse
from `733_Corpse_Found`, that id as an item ref from `butcher <id> for reagent`, and `eat <id>` from
the horn feeder). A bare `eat corpse` would have assumed how the game disambiguates a noun we hold
several of. **The eat is SENT DIRECTLY, never queued** (v4.7.304, from a live
log: v4.7.294 put it on the FREE queue "so the next `queue addclearfull` cannot wipe it", and it
never ate once -- the kill top-up fires at the exact moment a room clears, and the explorer's own
move for that moment is `queue addclear free stand;<dir>`, which CLEARS the free queue first; EAT
needs no balance, so there was never anything to queue for. **A queue is a place a command can be
deleted from; a balanceless command has no reason to be in one.**) The one WHEN decision that
remains is about the EATING balance (contended with every cure-herb, the reason the PvE curing
profile exists): the UPKEEP fires on a KILL -- a corpse exists and the fight is ending rather than
peaking. **NEVER A BOSS CORPSE** (v4.7.305, user: "Cant eat bosses I think" -- and the boss's
corpse was the first row of the listing that never ate). Two guards, since neither is complete
alone: `ataxia_corpseInedible` skips any row carrying the first word (>= 4 letters, the
`bardWantDance`/`_fledLineNames` rule) of a boss named THIS RUN -- `ataxiaTemp.mnemBossNames`,
recorded by `M.onObjective` and reset with the run, NOT `M.run.boss` alone, which is cleared on
every ripple change while the corpse stays in the pack for the whole dive -- and an `eat <id>`
that the confirm line (`highlighting/061`) does not follow within 3s marks that id inedible for
the session (`ataxia_corpseUnconfirmed`), so whatever the name rule cannot know costs exactly one
attempt. The listing capture stays ARMED past a skipped row and disarms on the first row it eats. The STARVATION path forces past that throttle, because a throttle
written for upkeep must not stand in front of unconsciousness. **The CORPSE top-up needs BOTH boons**: with
only Carnivore a corpse is just food and the horn already covers hunger; with only Metabolism the
food source is the HORN (v4.7.303, below -- v4.7.294 wrongly said there was none). The ATTEMPT is
stamped as well as the confirmation, because an empty pack is the normal state between kills and
would otherwise re-probe on every one.

**THE STARVATION PATH WAS NEVER WIRED IN (found in review, fixed v4.7.297).** `ataxia_hornOnHungry`
-- corpse-first, horn-fallback -- has existed since v4.7.294, but `triggers/374_Starving.lua`, the
ONLY place starvation is ever detected, called `ataxia_hornFeed` directly the whole time, so
Obligate Carnivore's entire starvation behaviour was unreachable in production: starvation still
burned a horn charge exactly as before the boon existed, and the test suite stayed green because it
calls `ataxia_hornOnHungry` directly rather than driving the trigger. **A function with a test and a
caller that bypasses it is still dead code.** Fixed by pointing the trigger at the right function.
The trigger now also owns its OWN re-fire throttle (`STARVING_RETRY`, 5s): the forced corpse-eat
deliberately bypasses `ataxia_carnivoreEat`'s own cooldown (starvation must not wait on a throttle
written for upkeep), so without a throttle at the trigger the vitals row -- which prints every
prompt while starving persists -- would re-send `ii corpse` on every single prompt.

**DEATH STARE -- THE ONCE-PER-RIPPLE INSTANT KILL, COUNTED FROM THE KILL LINE (v4.7.306,
`ataxiaBasher_deathStare`, basher/001).** "CONSIDER now costs 3 seconds of equilibrium and
instantly kills any non-boss denizen target. This can only be used once per ripple." User: at 2+
denizens immediately, and at least once per ripple. A class-agnostic EQUILIBRIUM rider PREPENDED
to the assembled round in `ataxiaBasher_assembleAttack` (first in the chain so it lands on a LIVE
target; appended after the swing it could consider a corpse; for Magi it displaces one eq cast,
which a guaranteed kill is worth). Crowd first: at 2+ denizens it fires at once. Alone it holds --
but a charge that expires with the ripple must not go unused, so after
`ataxiaBasher.deathStareAfter` seconds (default 90, measured from the first round evaluated in
that ripple) it fires on whatever non-boss target is in front of us. **The charge is spent by the
kill line, not the send**: "<mob> freezes for a moment before dying. Instantly." (trigger
`mnemosyne/086`, captured live; self-proving, so it also re-latches the flag) marks it used and
releases the in-flight replay, so a send the server ate RETRIES after 8s instead of forfeiting the
ripple -- bounded at 3 tries so a missed line cannot cost an eq spend every few seconds all
ripple. The replay is bound to the TARGET it was sent for (a retarget mid-hold stops it rather than
considering a second mob). **The ripple key is the MAP's** (`MAP._ripple`, stamped by `M.onRipple`
unconditionally), not telemetry's `M.run.ripple`, which sits behind the `_auto()` gate and never
moves with reporting off. Never on the boss (`ataxiaBasher_targetIsBoss`, the legend deck's
first-word rule hoisted to a global) and never on a shielded target.

**THE DENIZEN RESISTANCE DATABASE, AND CONSIDER AS RECON (v4.7.306, user: "I also didnt know
consider showed what they are strong against ... make a database of this and consider any mob not
in the database ... when fighting against X denizen and we know their weakness, if we can, use
their weakness against them").** CONSIDER prints, per denizen, a strength line in at least TWO grammars -- `<mob> exudes an
aura of <x>.` and `<mob> has an air of <x>.` (v4.7.310; a third would leave that mob unrecorded
until pasted) -- and `<mob> has a significant resistance against <type> damage.` (captured live: a
stout footsoldier, physical cutting and blunt; a blood-spattered jester, psychic). The block is
highlighted (v4.7.310): strength `gold` bold, resistance `indian_red` bold, weakness
`spring_green` bold, sentience `dim_grey`, health `gold`. Trigger `771_Consider_Lines` records them into
`ataxiaBasher.denizenResist[key]` -- on `ataxiaBasher` because it is KNOWLEDGE meant to persist
across sessions, keyed by the short description lowercased with the article stripped so the
capitalised aura line, the lowercase resistance rows and gmcp's item name land on one row. A
WEAKNESS row is parsed on the same shape with the noun swapped; that wording has never been seen,
so it is a place for the line to land, not a claim about it. **Unknown mobs are CONSIDERed once,
ever** (`ataxiaBasher_considerRecon`, from the round assembly): sent DIRECTLY, never in the
addclearfull chain, because CONSIDER is balanceless and a balanceless command in that chain
executes on every 0.3s rebuild (the shin-augment lesson); the row is created on the ATTEMPT so a
mob whose consider prints nothing we parse is still never asked twice (`bash resist forget <name>`
re-opens one); and NEVER while Death Stare is held, since that CONSIDER is the ripple's kill and
its output feeds the database anyway. Consumers ask `ataxiaBasher_targetResists(type)` /
`_targetWeakTo(type)` -- substring either way, so each asks in its own vocabulary, and an unknown
mob is never a guess. **Wired so far**: the Blademaster infuse element (`ataxiaBasher_bmInfuse`: a
known weakness outranks the preference order; a resisted element is skipped exactly as an
affix-suppressed one, with the same everything-suppressed fall-through) and the Bard's flick vs
punctuate (a mob that resists psychic gets punctuate, the fact the manual toggle existed for).
**Next, needing each attack's damage type confirmed from its AB before it can route**: Magi
staffcast (the crystal spells -- horripilation cold, immolation fire -- as an element choice),
Dragon gut/jab/whip/incantation vs the colour's blast, and the rest of the classes; the "Damage
dealt: N (type)" line trigger 350 already captures is the honest way to LEARN each attack's type
rather than hand-maintaining a table. `bash resist [<name>|forget <name>|clear]` shows the
database.

**SHAMAN THRICE CURSED (v4.7.386, user: "swiftcurse target, get jinx charge, then jinx target to use jinx charge and then swiftcurse").** "Your swiftcurses now build jinx charges, and your jinxes deal one extra bleed curse when used." With `mnemThriceCursed`, `ataxiaBasher_shamanThriceJinx` (basher/002) makes the swiftcurse bashtype send `jinx bleed bleed <target>` whenever `ataxiaTemp.canJinx` is up (jinx/001 latches it, jinx/002 spends it), and swiftcurse otherwise; regeneration below 60% still comes first. A charge still unspent `THRICE_JINX_STALE` (6s) after the FIRST send is treated as gone -- timed from the first send because the round is rebuilt every 0.3s -- so a jinx refused with a line we do not capture cannot strand the rotation. Wired like every boon: `M.BOON_FLAGS`, the claim alias, run start/end, and the seed. **v4.7.387:** the user then watched a charge build and dissipate unspent. jinx/001 was an exact match ending in a full stop while the pasted live line has none, so it is now start-of-line; and the charge line itself re-latches `mnemThriceCursed` in the tower for a Shaman on the swiftcurse bashtype (only the boon lets a swiftcurse build a charge), so a reimport no longer leaves the boon off until `boon claimed`. **v4.7.388:** `highlighting/071` paints both Shaman attacks (the swiftcurse's "You point an imperious finger at..." and the jinx's "Summoning your malign power...") bold chartreuse. The jinx line ENDS with the denizen's name, so a server-wrapped tail has no fixed words to anchor on: instead, a first row that does not finish its sentence colours the next row too (`tempLineTrigger(1, 1, ...)`). That is the pattern to reuse for any line whose variable part comes last.

**SERPENT ASSASSIN'S BLADE: OPEN WITH BACKSTAB WHILE HIDDEN (v4.7.393, user: "with This and darkwalker it should always open with backstab").** Assassin's Blade (`mnemAssassinsBlade`) makes a backstab from hiding instant instead of channelled; Darkwalker hides us on every kill. When the boon is held, `ataxia.defences.hiding` is up and the target is not shielded, `ataxiaBasher_serpentBashing` returns `backstab <target>` FIRST, then the Searing Light lightwall and the battlerage (no bare trailing separator) -- they used to lead the round and could reveal us before the backstab. **v4.7.394** (user: "backstab needs a dirk in our hand"): the round starts `wield shield dirk;backstab <target>`, the same wield the Serpent PvP offense uses. Darkwalker gets no flag: the game's `hiding` defence is the gate, however we got hidden. Wired: `M.BOON_FLAGS`, claim alias, run start/end. **v4.7.408:** Darkwalker's kill line "You swiftly return to concealment in the wake of your triumph." (trigger `serpent/020`, user: "this rehides us also") arrives before GMCP's `hiding` Add, exactly when the next denizen's round is built, so `ataxiaBasher_serpentHidden()` also accepts that line for 3s (a stamp on `ataxiaTemp.serpentConcealAt`, never a write to `ataxia.defences`), the line re-queues the round at once, and a GMCP Remove of `hiding` (`lostDef`) clears the stamp. **v4.7.409:** "You are already hidden." (the HIDE refusal) stamps the same way (v4.7.410: and the successful HIDE, "You conceal yourself using all the guile you possess."; v4.7.411: the landed backstab, "You leap from the shadows and plunge your dagger into <mob>'s unsuspecting back!", trigger `serpent/021`, is highlighted bold chartreuse and DROPS the stamp and the `hiding` defence, since it reveals us -- user: "When we backstab we become unhidden"; v4.7.412: "Your attack has brought you out of hiding.", trigger `serpent/022`, does the same; v4.7.413: the refusal "You must be hiding or phased to backstab.", trigger `serpent/023`, does the same AND re-sends the round at once so the garrote / bite goes out), and the wield stays `wield shield dirk` (user: "wield shield dirk is fine").

**A VENOM TEARING THROUGH US -> PURGE (v4.7.392, user: "We need to purge in this instance").** On "You scream out in agony as a vicious venom tears through your body." trigger `serpent/019` sends a direct `purge` (the same unqueued send `serpent/014` uses for the "purge the venom ... before you may secrete another" refusal), throttled to once per 2s (`ataxiaTemp.venomAgonyPurgeAt`). Start-of-line, so the full stop is optional; a denizen's relapse line ("... screams out in agony, struck by ...", mnemosyne/108) does not match.

**SERPENT VENOM BOONS (v4.7.381, user: "we should use venom instead of garrote with these boons" -- "secrete camus;bite target").** With Serpent's Maw (`mnemSerpentsMaw`: venoms unblockable vs denizens, +50% base) or Toxicologist (`mnemToxicologist`: venoms relapse against denizens) the basher's swing is `purge;secrete camus;bite <target>` (Camus, AB 1292 -- cannot envenom a weapon, so it is secreted and bitten; `purge` first since v4.7.383, user: "It should be purge;secrete camus;bite target") instead of `garrote`; a shielded round still flays. Both in `M.BOON_FLAGS` (so the generic BOONS row re-latches them), the claim alias, run start/end; Serpent's Maw added to the seed. The bite is highlighted bold chartreuse (`highlighting/068`, v4.7.384) and Toxicologist's relapse line ("... screams out in agony, struck by the effects of a vicious venom.") bold yellow (`mnemosyne/108`), which also re-latches `mnemToxicologist` in the tower.

**SEARING LIGHT -- THE SERPENT'S LIGHTWALL AS A ROOM NUKE, FIRST IN THE ROUND (v4.7.307,
`ataxiaBasher_searingLightwall`, basher/002).** "Conjuring a lightwall now deals fire damage to
all denizens in your location." User: "in a room of 2 or more denizens the first thing we need to
do is conjure lightwall in any direction." AB Lightwall (Subterfuge 1244): `CONJURE LIGHTWALL
<direction>`, **4.00s of EQUILIBRIUM**, 45 mana -- so it RIDES beside the balance garrote (the Kai
Choke rule), prepended FIRST per the user (and both commands fire back to back the instant the
round executes, so order only decides which one a mid-chain refusal costs). **No crowd gate**
(v4.7.309, user: "regardless of denizen as it does fire damage one time" -- v4.7.307's 2+ gate
withdrawn), a 250-mana floor (the Kai Choke floor: never scrape a dry pool for a rider), **ONCE
PER ROOM PER RIPPLE, FULL STOP** (v4.7.310, user: "only do the lightwall attack one time per room"
-- the 60s re-arm withdrawn): the rooms conjured this ripple live in `ataxiaTemp.lightwallRooms`,
keyed on the MAP's current room (stable under dementia) and wiped when the MAP's ripple counter
moves, so a room patrolled back into is not conjured twice. Direction: "any" per the user, so the first PLANAR exit of the room's known exits,
sorted -- and **"There is already a lightwall in that direction."** (trigger `serpent/001`,
captured long ago) marks that exit spent for the room and clears the attempt, so the next rebuild
tries the next exit rather than replaying a refusal. Send-side stamp as a floor + the in-flight
replay, and BOTH lines captured live (trigger `mnemosyne/088`): the conjure ("You form a ball of
light in your palm and hurl it northwards.") releases the replay and restamps the room from the
LANDED moment; the boon's proc ("...searing the location with solar force.", an end fragment
because it wraps) prints only with the boon, so it also re-latches the flag. Fires on a shielded
round too -- the wall is room-wide, not a strike on the shield -- and still first, ahead of the
flay. **Open and deliberately not guessed**: whether our OWN lightwall darkshades US when the
sweep or the escape ladder walks through it; if it does, `SNUFF LIGHTWALLS` on room clear is the
fix and the explorer's room-clear hook is where it goes.

**HEALING METABOLISM ALONE: HOLD "UTTERLY SATIATED" OFF THE HORN (v4.7.303; WRONG MODEL, superseded by v4.7.452 above -- this upkeep is FAMINE's only now; user-directed:
"When we have this boon we need to be full satiation. I have a horn which produces food ... If
HUNGER is lower than utterly satiated").** Six horn charges on a refill clock is a real cost and
the user has priced it. **Three ways to notice hunger, because none is complete alone**: (1) the
SCORE row `| Hunger : <state>` -- trigger `374` now captures WHATEVER the row says (it used to match
only the three emergency states) and hands it to `ataxia_hungerSeen`, which classifies: emergency
states take the starvation path whether or not any boon is held, anything else below "utterly
satiated" is upkeep, and "utterly satiated" closes the episode -- the classification lives in the
script because a guard inside a trigger is a guard the suite cannot see; (2) the satiation DEFENCE
leaving `gmcp.Char.Defences` -- the boon itself calls it "the satiation defence", so it is in DEF;
its GMCP name is INFERRED (any defence containing "satiat") and unverified, which is safe because a
Remove can only follow an Add, so a wrong guess simply never fires (the Songstep reasoning); (3) a
SCORE on a KILL when the last reading is older than `ataxia.settings.satiatePoll` (default 300s,
`horn poll <n|off>`) -- kill-driven rather than a timer so it runs only while bashing, at the
moment a fight is ending, with no lifecycle wiring of its own; not spent at all when Obligate
Carnivore is also held, since the corpse top-up already keeps satiation up blind and free. **Every
upkeep feed is VERIFIED**: SCORE again 6s later, and a row still short feeds again FORCED past the
horn's 20s cooldown -- one loaf may not climb the whole ladder -- bounded at `SATIATE_MAX_CHAIN`
(3) per episode, an episode ending on "utterly satiated" or after 300s of silence, so an empty
horn, a refused eat or an unparseable row can never spend charges forever. Corpses still outrank
the horn (unforced, so a closed corpse throttle falls through). The eat is the proven
`ataxia_hornFeed` path -- `probe horn` -> first listed id -> `get <id> from horn;eat <id>` -- so
nothing new is guessed about the horn. The starvation path's 5s re-fire throttle moved from the
trigger into `ataxia_hornOnHungry` so a SCORE reading is never swallowed by it.

**SPIRIT REND -- THE THIRD MONK EQ RIDER, AND THE ORDER IS THE DECISION (v4.7.292,
`ataxiaBasher_spiritRend`).** "Your kaido enfeeble ability costs no kai and can target denizens,
halving the target's current health... every 60 seconds." User doctrine: Rain form, above 50%
target health. **The AB and the boon disagree on three facts and each shapes the code**: AB Enfeeble
(Kaido 901) charges 61 kai (the boon removes it, so there is NO kai gate), says "Works on/against:
**Adventurers**" (the boon is the only thing making this legal in PvE, so it is `type(target) ==
"number"` gated -- against a player it is an ordinary 61-kai ability), and mentions no cooldown (the
60s is denizen-only). **No prone gate**: the AB's "reduced to 25% if not prone" clause is in the
ADVENTURER ability, and the boon restates the denizen effect flatly, so requiring prone would invent
a mechanic from the wrong paragraph. **No mana floor**, unlike Kai Choke, whose AB lists 50 mana --
this one lists kai and nothing else. **IT SORTS AHEAD OF KAI CHOKE**: three riders now share one eq
slot, resolved by an `or` chain (which short-circuits, so a loser is never CALLED and cannot stamp
its own retry guard for a round it did not win). Rend goes first because **its window CLOSES** --
illegal below 50%, and halving is worth twice as much at 80% as at 40% -- while the choke is just as
good next round; *the ability whose opportunity expires outranks the ones that merely recur*, the
Stormcleaver-before-Thunderclap reasoning. The 60s clock starts at the CONFIRMED line ("You
violently propel your kai energy at <mob>, enfeebling him.", trigger `080`, also chartreuse-bold
highlighted there rather than in a second trigger), never at send. An unreadable target does NOT
fire and warns once per run -- the `rwBisect` rule, plus the Arc proof-of-life, because a silent
refusal here would be invisible (no balance is spent, so nothing else looks wrong).
`bisectTargetHp` was hoisted to `ataxiaBasher_targetHpPct()` so a second class could reach it.
**Fires in Tekura too, since v4.7.297** -- see the Tekura/Kaido note further down, and
`.claude/classes/monk.md`. **Trigger `080`'s pattern spanned the denizen name in one anchored
regex (found in review, fixed v4.7.297)**: the name is arbitrary length, Achaea wraps server-side
at the player's WIDTH (the v4.7.286 rule), and a longer or titled denizen name pushes ", enfeebling"
onto a second physical line -- silently failing the match, so nothing ever stamped the 60s cooldown
and the ability would spam every `SPIRIT_REND_RETRY` (6s) against a server-enforced 60s cooldown.
Split into two substring fragments (the `057`/`058` convention) so either half of a wrapped line
still confirms.

**TEKURA GETS THE SAME THREE KAIDO RIDERS (v4.7.297, user-directed): "The monk boons should also be
coded to be used when I am in tekura. In tekura I am only in one stance. SO the stance criteria for
tekura needs to be removed."** Kai Choke, Kai Enfeeble (Spirit Rend) and Numbness are all Kaido
abilities, and Kaido is the skill Tekura and Shikudo SHARE (`.claude/classes` table: "Monk:
Tekura/Shikudo, Kaido, Telepathy") -- "Rain form" was always user doctrine for *which Shikudo form*
to use them in, never a restriction to Shikudo itself. Before this fix `ataxia.vitals.form` is
`nil` for a Tekura Monk, so a bare `form ~= "Rain"` gate silently blocked all three the entire time
these boons existed, for Tekura specifically -- and separately, the `elseif tekura then` branch of
`ataxiaBasher_monkBashing2` never called any of the three rider helpers at all, so fixing the gates
alone would still have shipped nothing for Tekura. Both halves needed the fix: a new shared
`ataxiaBasher_monkKaidoReady()` gate (`stance-truthy OR form == "Rain"`, reusing the dispatcher's
own `tekura`/`shikudo` discriminator locals) replaces all three bare `form ~= "Rain"` checks, and
the Tekura branch now prepends the same `rend or choke or numb` chain, in the same rend-before-
choke-before-numb order, ahead of its `unwield all;combo ... rhk/sdk ucp ucp`. **No stance-NAME
filtering, deliberately**: per the user, a Tekura Monk sits in exactly one stance during ordinary
bashing (Horse/Bear appear only in the TK6 backbreaker's finishing sequence against an
already-dying target, per `.claude/classes/monk.md`), so truthy `stance` alone is the whole test
-- filtering by stance NAME would invent a restriction the boon text never states, in the direction
that costs damage rather than the direction that is safe.

**AUDIT -- THE FIRST INPUT THAT CAN PROVE THE PANEL WRONG (v4.7.290, `mnem audit`,
`mnemosyne/013_Audit.lua` + trigger `078`).** Everything else on the bonuses panel is DERIVED from a
boon's description sentence, so a misparse yields a confident number with nothing to contradict it
-- `Ogre's Defence` sat there as +2% for a day. AUDIT is the game's own accounting. Two uses: a
**BASELINE** captured once per RUN at the wade entry (user: "in the very beginning"; once per run,
not per ripple -- it is a run-scoped fact and re-asking would dump an 18-line block at every boon
screen), and a **MEASUREMENT** -- `current - baseline` is what the run's boons ACTUALLY bought, in
the game's numbers, against a known set of claims. That is the only way to settle whether boon
resistances add, diminish or multiply, and **nothing here assumes an answer**: the delta is
reported, not modelled (the shin/rage probe rule, v4.7.141/269). **THE VOCABULARY DIFFERS AND THAT
IS DATA**: `Electricity` is our `Electric` (normalised, or measured and derived rows never line
up); **`Cutting` and `Blunt` are NOT `Physical`** -- the game tracks them separately with different
numbers (76.2% vs 78% in the first capture) while every boon description says "physical", so
folding them would invent a figure that is neither, and no `Physical` row is synthesised; and there
is **no `Arcane` row**, one more point toward Arcane == Magical which v4.7.289 declined to assume
and which this does not settle either. **Armed by the OUTPUT, not by our send** -- the trigger
fires on `Audit records:`, so a manual AUDIT is captured identically and a wrong send fails
VISIBLY rather than leaving a silently absent baseline. **Deliberately NOT `_captureLines`**: that
helper holds one global slot and a second caller force-finishes the first (v4.7.93), while this
baseline fires from `_exploreResume` off `GO!` -- the instant the monster capture is arming. A
resistance row is recognised by its PERCENTAGE (an unseen category must never be promoted into a
damage type); a `+60  -0` pair stays two numbers (netting hides a penalty); the baseline never
drifts (`mnem audit reset` drops it, for a run joined late); and there is NO delta from a single
reading, since "no second reading yet" and "the boons bought nothing" are different answers.

**PER-UNIT DAMAGE BOONS ARE SCALED, NOT FLAT (v4.7.427, user: "This boon is additive for how much
mana we have" / "Brute force is based on strength. we have 16. 16 x 4").** `Mana Powered` ("4% bonus
damage for every 1000 maximum mana") read as +4% where the truth was +28%; `Brute Force` /
`Mental Prowess` / `Deadly Finesse` (4% per point of one stat, user's figure, `M.STAT_DAMAGE_PER_POINT`)
and `Trainwreck` (2% per point of three stats) likewise. `M._dmgScaledFrom` + `M._dmgScaledValue`
(011) multiply by max mana from gmcp (WHOLE thousands, user-confirmed) or our stats, and the row
prints the arithmetic; `_dmgGenericFrom` stands down for "for every" / "for each point" sentences. **An
unknown number is listed, never summed as 0.** Stats come from the STAT box (`mnemosyne/110_Stat_Row`
-> `M.onStatLine`, two stats per row) into `ataxiaTemp.charStats`; `M._statCheck()` (from
`B.refresh`/`B.report`) sends `stat`, not gagged, only when a held boon needs a stat and there is no
reading since the last claim, at most once per 20 s. `mnem bonuses stat` forces one. Full detail:
`.claude/projects/mnemosyne/05-commands.md`.

**OFFENSE ON THE PANEL, AND THE +22% THAT WAS +30% (v4.7.289).** The live panel under-reported
resistance because the all-damage branch took `desc:match("(%d+)%%")` -- the FIRST percentage in the
sentence -- and `Ogre's Defence` reads "You lose **2%** critical strike chance, but you gain **10%**
resistance to all damage." The number must be the one ADJACENT to the phrase; this is the
two-numbers-in-one-sentence trap `BONUS_EXCEPTIONS` exists for, reappearing in the one branch not
reading positionally. **The OFFENSE section sums generic damage bonuses additively**, and the
measurement is the design: 35 catalogue entries mention dealing more damage and only SEVEN are the
always-on every-swing kind. **CONDITIONAL** ones ("20% while chrono blur is up", "10% when above 90%
mana") are shown with their clause CAPTURED FROM THE SENTENCE and excluded from the total -- summed,
they give a headline wrong almost all the time. **ABILITY-SPECIFIC** ones ("your STERNUM STRIKES
deal an additional 300%", Warmarch's paean +200%) do not match at all, because every pattern
requires the subject to be YOU and the object to be BARE "damage" -- the `_procFrom` distinction
again, and Warmarch alone would have put the headline 200 points out. The total prints with the
boons that make it up, so it is AUDITABLE rather than asserted. **A WEAKNESS IS A NEGATIVE
RESISTANCE** ("a 10% weakness to psychic damage", "you take 10% additional physical damage") and
nets onto that type's own row, or the panel reports a defence we do not have. **WHEN TWO SOURCES
CAN DESCRIBE THE SAME FACT, EXACTLY ONE MUST OWN IT** -- three double-counts in two days: the
Poison alias in the all-damage fold (v4.7.288), the exception AND the generic parser both reading
`Silvestri's Grace` (+50% instead of +25%; the exception wins, since it exists because the sentence
cannot be parsed safely), and `Damage` printed in STATS beside Strength. **The eight identical
resistance rows now collapse to one** `All types +N%` when every type is equal -- the v4.7.287
reason for folding "all" into every type stands where there IS a comparison to make, and buys
nothing where there is not; a mixed set still prints per type.

**THE 2026-09-01 REBALANCE, AND WHY A SEED CANNOT CORRECT ITSELF (v4.7.288).** The game rewrote
fourteen boons, deleted three, renamed one and added thirty-three. Editing `010_Boon_Seed.lua`
**reaches nobody on its own**: the seed merges into `history.boonLibrary` at load through
`_boonDbMerge`, which is FILL-ONLY -- it never overwrites a field the library already holds,
because observed data beats seeded data -- and every previous release had already merged the OLD
text in. `_bonusDesc` prefers the library over the seed, so the stale numbers would land on the
`mnem bonuses` panel as fact. Fill-only is right for ENRICHMENT and wrong for a RETCON, so
`M._boonSeedRetcon()` overwrites the named boons and drops the deleted ones **once per epoch**
(`M.BOON_SEED_EPOCH`, the `controlMobsSeeded`/`panicAt35` shape) -- once, because an unconditional
rewrite would undo a real in-game sighting on every load, which is the fill-only rule broken in the
other direction. `_learnBoon` DOES overwrite, so a sighting still wins afterwards; that
self-healing is not enough alone, since a boon may not come round for many runs and a RENAMED one
(`Trenchfoot` -> `Sprightly`) never comes round under the old name at all. **The 30 new boons whose
effects the announcement did not state are seeded as NAMES WITH NO DESCRIPTION** -- that is the
entry, not a gap: it makes the boon known so `mnem boondb` shows it as an explicit hole. They are
DECLARED in `M.BOON_UNDESCRIBED` rather than written inline, so the invariant got stricter -- the
suite asserts every undescribed entry is declared (an accidental omission still fails) and every
declaration is present (a stale one fails). Deliberately NOT extrapolated from the three Mastery
boons that do have text: one line would have generated the other five, which is exactly the
hand-maintained name->amount table this module exists to replace. `Cavalry` is on the "new" list
and we already had its text, so **"new" is not strictly new** and the `or {}` in the seeding loop
is load-bearing. **A BOON THAT CAPS HEALING BREAKS EVERY "STAND STILL UNTIL HEALTHY" GATE:**
`Battlemaster's Fury` used to read "you can no longer be healed above 30% health" against a
`recoverAt` of **95%**, so holding it made every hover and ground recovery burn its full 60s cap
forever -- the MANALEECH shape of v4.7.252 with a different cause, and nothing in the package knew.
It is a balance boon now, so there is nothing to fix; grep `recoverAt` when the next one appears.
Also: `Meathead`'s cost changed stupidity -> confusion, which is not cosmetic, because stupidity
EATS QUEUED COMMANDS. The 13 new affixes and their first-appearance ripples are recorded in
`.claude/projects/mnemosyne/03-parsing-triggers.md` rather than coded -- the affix layer learns
each sentence from WADE STATUS at runtime -- along with two facts that bound the worst case: the
enemy-spawning affixes are all mutually exclusive with one another (so `Necromantic`'s
repopulation, which is what makes `_roomHasDenizens` untrue, has a ceiling), and a manifested
nightmare's attack speed was reduced, which weakens the one seeded `controlMobs` default.

**`BOON CONTEMPLATE` NOW PRINTS A CATEGORY, AND THE PARSER WOULD HAVE EATEN IT (v4.7.288).**
`_parseContemplate` was a `meta -> desc -> quote` state machine that knew exactly three labels and
treated **any** other non-blank line as the start of the description -- so the new category line,
and the unlocked-by line, would have been concatenated into `info.description`, which reaches
`_learnBoon`, which OVERWRITES, replacing good library text with `"Category: Offensive Your fire
damage..."` and serving it to the bonuses panel. We have never seen the wording, so the fix matches
the SHAPE: while still in the meta block, a short `Label: value` line is meta, and an unrecognised
label is KEPT in `info.meta` rather than dropped -- storing it under whatever the game calls it is
how we learn what to call it. **The bound is the interesting half**: an unbounded shape rule
swallowed `"Your options are simple: hit harder."` in testing, so a label is capped at
`META_LABEL_WORDS` (3). Widening what a parser accepts obliges you to say what it must still refuse
(v4.7.262).

**SESSION STATS RESET ON A FRESH RUN, KEPT ACROSS A RESUME (v4.7.296).** The `tarc` HUD's
kills/gold/DPS/damage-taken now reset via `resetBashingStats()`, called from `M.onRunStart()`
right beside the identical AUDIT-baseline logic (v4.7.291) and for the same reason: a pause
(`WHISPER ... beseech that it grow still`) does not end the run server-side, so the next wade
re-enters the SAME run and wiping progress on a mere pause/resume would lose data for nothing.
Opposite of the ~40 boon flags reset UNCONDITIONALLY on the same trigger line -- those answer "do
we hold this boon right now" and a stale answer is actively wrong, where session stats carry no
such requirement. Above the `_auto()` gate, like the audit baseline, since session stats have no
dependency on REST telemetry.

**BERSERKER'S EDGE -- HOLD RAGE INSTEAD OF SPENDING IT (v4.7.296).** "1% extra damage per point of
battlerage held, up to 100 rage." Not a new system: `ataxiaBasher.rageFloor` (v4.7.141) already
exists for "gear pays a bonus while battlerage is at or above a threshold", and
`ataxiaBasher_rageAfford` already gates all 37 rotation call sites -- so the boon is that mechanism
PINNED AT ITS OWN CAP (`rageFloor = 100`), landing the hold on every class with zero per-rotation
code, since `rage >= cost + 100` can never hold for any real cost once rage itself caps at 100.
**Bypasses the user alias's `MAX_FLOOR` clamp (46) on purpose** -- that clamp exists so a human
typing a number cannot accidentally strand their own rotation, which is precisely the outcome this
automated boon wants. **The revert is designed with the effect** (the Borrowed Power rule,
v4.7.204): the pre-boon floor is saved ONCE (guarded against a second confirm overwriting it with
the boon's own 100) and restored on the confirmed run end, mirroring the Borrowed Power branch of
`M.onRunEnd()` exactly, plus a defensive revert at run start for a prior run that ended without
confirmation. **A manual `bash floor` command always wins**: it drops the saved-for-boon
bookkeeping, so the automatic revert later finds nothing to restore rather than clobbering a
choice the user made afterwards. Culling's own, unrelated floor exemption is untouched.

**THE REVERT HAD NO RECONNECT PATH (found in review, fixed v4.7.297).** The two revert call sites
above are both Mnemosyne-specific trigger lines -- neither fires on a plain disconnect/reconnect or
a SYSUPDATE reload mid-run. A player holding the boon who drops connection before the confirmed
run-end line prints keeps `ataxiaBasher.rageFloor` pinned at 100 **on disk**, since that field (and
the two bookkeeping keys the revert reads) all live on the serialized `ataxiaBasher` table --
silently starving all 37 rotation affordability checks, in and out of Mnemosyne, PvE or PvP, until
the next wade's defensive reset or a manual `bash floor`. `ataxia_loadSettings()`
(`001_Save_Load_Settings.lua`) now calls `ataxiaBasher_berserkersEdgeRevert()` defensively right
after the basher block loads, mirroring the run-start safety net. Safe even for a run still
genuinely in progress: worst case is a few seconds at the pre-boon floor until the next wade
re-applies it, against leaving an ordinary bashing session silently capped indefinitely.

**A LATENT MOCK CRASH, TABLE-SIZE DEPENDENT (v4.7.296).** Both `mock_mudlet.lua`'s
`M.fire_timers()` and a test-local `fireOfferWait()` helper walked a timer table with a bare
`pairs()` loop; `_flushPendingOffer`'s catalogue trickle (v4.7.295) arms a follow-up timer FROM
INSIDE another timer's own callback -- an ordinary self-rearming pattern this codebase uses
throughout -- which adds a key to the table `pairs()` is still iterating, undefined in Lua and
surfaced as `invalid key to 'next'`. It fired only near a hash-table rehash boundary, so it was a
flake an unrelated test could trigger just by leaving a few more timers lying around than usual;
real Mudlet has no equivalent hazard, since its timer registry is not a Lua table this code
iterates. Fixed in both places by snapshotting keys before iterating; semantics otherwise
unchanged. **Break-back note:** the `fireOfferWait()` fix reproduced the crash 10/10 runs when
reverted; the general-purpose `mock.fire_timers()` fix, exercised only by a small dedicated test,
did not reproduce on 15 runs -- recorded honestly since forcing a specific rehash boundary
deterministically is not practical, not claimed as a clean break-back it did not achieve.

**KEEPING THE CATALOGUE CURRENT (v4.7.295, `mnem boonfill`).** A boon's description is shown ONCE,
on a screen gone a second later, so the catalogue cannot be rebuilt and a hole stays a hole until
something asks. `boonFill` used to read `ataxiaTemp.boonsOwned` alone -- the smaller half, since the
holes are precisely the boons we have NEVER been offered (25 declared in `M.BOON_UNDESCRIBED` after
the 2026-09-01 rebalance, plus four we automate with no text at all: Kai Unleashed, Daemon Jaws,
Necrotic Aura, Icy Heart). `BOON CONTEMPLATE <name>` answers for any name, held or not, so
`M.boonGaps()` unions the SEED (carrying every declared hole), the LIBRARY and `boonsOwned`,
dedupes, and SORTS so a batch is deterministic rather than `pairs()`-ordered. **It now fills itself,
one gap per boon screen** -- and the MOMENT is the design: the boon screen is the only long quiet
stretch in a run, but it is also when the offer capture runs, and `_captureLines` holds ONE global
slot whose second caller force-finishes the first (v4.7.93). So the trickle fires only AFTER the
offer is flushed, waits `BOON_FILL_IDLE` (4s), and still refuses if anything holds the slot; ONE per
screen, because a trickle cannot starve a capture. Batched by default (`BOON_FILL_BATCH` 8) for the
same reason -- filling twenty-five at once is that race, self-inflicted. `mnem boonfill gaps` names
the holes without spending a command. **A NAME THE GAME REFUSES IS NOT A GAP (v4.7.308):** "You
consider for a time, but no information comes to you on such a boon." (trigger `mnemosyne/089`)
records the name in flight in `M.history.boonUnknown`, drops it from `boonGaps()`, and says which
name it was -- until then the trickle asked the same unrecognised announcement-spelled name at every
boon screen forever, and the silent send meant the apostrophe got blamed. `mnem boonfill unknown`
lists them; `mnem boonfill retry <name>` re-arms one after the seed's spelling is corrected.

**SEASONAL CHURN: THE REGISTRY EXISTS AND ITS RESET IS HALF-WIRED (audited 2026-09-02, corrected
2026-09-03, KNOWN AND UNFIXED).** Achaea adds and removes boons every season, and this package
absorbs that BY HAND. The mechanism not to was built in v4.7.241 -- `M.BOON_FLAGS`, a NAME -> FLAG
table in `004_Parsers`, whose own comment says a hand-written trigger per boon "is not reasonable
for the next ten" -- and only half of it covers both ends: **`M.latchBoonFlag` is called
(`004:1608`); `M.clearBoonFlags` is called from `M.onRunEnd()` (`004:264`) and NOWHERE AT RUN-START.**
(An earlier pass of this audit read `clearBoonFlags` as dead everywhere, which understated the gap
by half.) So registry boons are latched generically, cleared on a CONFIRMED run end, and otherwise
cleared only where somebody also hand-added them to the two legacy reset lists -- with no run-start
safety net, which is the load-bearing half (see below). Measured surface: **42 boon flags, 13 on the
registry, ~29 hand-wired
across four files each** (BOONS-row trigger, claim-intercept line, run-start reset, run-end reset,
plus the consuming code). **Three flags are asymmetric today** -- `dwTimequake` and
`dwHeraldInfirmity` have a run-END reset but no run-START, `mnemIcyHeart` the reverse; run-start is
the load-bearing one, since trigger `001` fires on the wade line with no telemetry gate while
`onRunEnd` needs its confirmation, so a flag missing from run-start stays armed indefinitely. **Four
boons we automate have no catalogue entry at all** (`Kai Unleashed`, `Daemon Jaws`, `Necrotic Aura`,
`Icy Heart`). **And nothing detects a REMOVAL**: Reaper's deletion (2026-09-01) cost two triggers,
four functions, a claim latch, two reset lines and three tests, left a live trigger matching a line
that can never print again, and left stale prose in a project doc edited that same session -- we
knew only because an announcement was pasted in. **When auditing this surface, note that a flag may
be cleared on a shared multi-assignment line** (`a, b, c = false, false, false`), so a naive
`grep "FLAG = false"` under-reports and manufactures false defects.

**Boon re-latch** (v4.7.188, corrected v4.7.192): every boon flag latches from the `BOON CLAIM` alias or a BOONS-list row, so a boon owned BEFORE its handling shipped -- or claimed outside the alias -- stays inert silently. `M._relatchBoons()` sends **`BOON CLAIMED`** once per run to re-latch all 33 at once (**corrected v4.7.203** -- it sent bare `BOONS` from v4.7.188, which is NOT a command: the game answers it with its syntax help, so the re-latch never re-latched anything and printed a syntax block into combat. Three passes touched the function reasoning about WHEN to send and never WHAT, and its test pinned the string `"boons"` without checking it was a real command. Unexplained syntax help in a combat log is always one of our commands being rejected), called from `M.onRipple` (every mode) AND both explorer entry points. Its guard lives on **`ataxiaTemp`**, not `ataxia.mnemosyne`: `ataxia` is serialized wholesale and `deepMerge` lets a disk value win, so a guard stored there would come back TRUE after a reload while the bare-global boon flags came back nil -- defeating the function on exactly the path it exists for. Deliberately NOT latched from boon DESCRIPTIONS (unlike the damage affixes): a boon description also appears on the OFFER screen, listing boons we declined.

**The BONUSES panel (`ataxia.mnemosyne.bonuses`, files 011/012, v4.7.287, `mnem bonuses`).** Folds
this run's claims into TEN sections, in render order -- AFFIXES, BOONS, STATS, OFFENSE, RESISTANCES, DMG BOOSTS, AUDIT (measured), IMMUNE TO, ON-HIT PROCS, COSTS. A run's boons arrive one at a time across an hour, each announced once on a
screen that is gone a second later, so nothing could answer "what am I immune to, how much fire
resistance do I have, what is my strength" -- `mnem boons` prints names with no arithmetic and the
offer-screen immunity note (v4.7.224) says it ONCE. **The numbers are DERIVED FROM THE DESCRIPTION,
not from a name table** (v4.7.264, v4.7.186): measured against the described seed entries before (297 at the time, 299 now)
committing, procs parse 9/9, stats 18/22, resistances 11/16, so `M.BONUS_EXCEPTIONS` is **six
entries against the community file's forty-seven** -- only sentences a regex provably cannot read
(TWO NUMBERS OF OPPOSITE SIGN, `Earthen Will`'s "gain 15% physical ... lose 10% magical", where
taking the first reports a penalty as a bonus; or TWO STATS SHARING ONE NUMBER). Ported in DESIGN
from a community window, and **three of the four porting-audit findings would each have shipped
broken**: `silver` (its Physical colour) IS NOT IN our palette and `fg()` throws at render time on a
panel that redraws per claim (hence `tools/check_colours.py`, below); its rarity palette uses the
RESERVED `orange` for epic (we use `gold`); and `Careless Whisperer` disagrees between the two
sources (community: Cold +10; our seed: an immunity boon) so it is **deliberately absent** and
contributes no row rather than a guessed one. Fire/Venom/Asphyxiation Mastery were missing from our
seed entirely and are added marked **SECOND-HAND**, the v4.7.278 honesty marker. Design calls:
**"All damage" folds into every TYPE** rather than a row of its own (at the point of use "+15% to
everything" and "+15% fire" are the same fact); **on-hit procs are gated on the literal phrase "your
attacks"**, because the identical "chance to afflict the target with" clause also covers
ABILITY-specific procs (draconic blast, `scream`, `confront`) that fire only on that one ability;
**type damage boosts stay OUT of the stat totals** (a Damage stat lifts everything, a Fire boost
lifts one type); **INERT is three-state** -- a Shaman boon whose spirit is unattuned is MARKED not
hidden, but `nil` means "cannot tell" and must never render as INERT; **COSTS is a section**, since
a panel showing only upside lies by arrangement. **NOT gated on `inMnem()`** (unlike the map): boons
persist for the whole run and the panel is as useful on the riverbank deciding whether to dive again
as it is mid-ripple. Bare `mnem bonuses` REPORTS to the console rather than toggling -- one source,
two surfaces -- and the empty panel says WHY it is empty, because a blank panel and a broken panel
look identical. 011 is pure and unit-tested (`test_mnem_bonuses.lua`); 012 is Geyser and is not, the
005/006 split exactly.

**Auto-explorer (`ataxia.mnemosyne.explore`, file 008):** `mnem explore on` auto-sweeps the ripple's 4×4 — it drives the **basher in manual mode** (combat + no-flee, never mapper-moving) and handles *navigation* itself: room clear (`ataxia.denizensHere` empty) → step through a usable unexplored exit or backtrack via `MAP.path` to the nearest room with one, moving with `queue addclear free stand;<dir>` (stands first — you're often prone post-fight). `usableUnexplored` keeps **planar** unwalked exits, plus **only `down`** from a room with no planar exit at all — the entry **holding room's `down`** into the grid. `up`/`in`/`out` are never used (there is no `up` in Mnemosyne), and a 4×4 room's deeper `down` isn't taken. Event-driven (`gmcp.Room` + `"targets updated"` → debounced tick, `moving` guard); it echoes each step (`room clear → moving <dir>`) and once per room `clearing this room (N denizen(s))`. When the grid is fully swept it does **not** stop — on a **boss ripple** (every 5th) the boss spawns at the end in any already-cleared room, so it **patrols** (`_nextPatrolStep`, round-robin re-visit) to find + kill it, capped at `MAX_PATROL_LOOPS` fruitless loops. **Pauses** at the boon screen (`onBoonScreen` — sets `explore.pausedAtBoon`, halts navigation but **keeps the basher on** in explore mode; **auto-resumes on `GO!`** via `exploreOnGo` — a `look` to lock in the holding room's `down` exit, then `_exploreResume()` — or `mnem explore on` manually).

**A PAUSE IS THREE QUESTIONS, NOT ONE (v4.7.263).** `pausedAtBoon` was consulted in **2 of the 8
paths that could still act**, two of which send movement. `M._navRefusal()` (008, reason-string
form like `_stepRefusal`/`_chaseRefusal`) is now the single owner, and every site is classified:
**INITIATION** (sweep, patrol, pull, re-entry, boss chase, map upkeep, wall melt) suspends;
**COMPLETION** (a move in flight landing, failing, slipping, retrying) never does, because
suspending it strands `moving`/`swarmHold`/`S.state`; **SELF-PRESERVATION** (lava, escape ladder,
panic tumble, recovery loop, tincture, disengage) never does. Two traps, both of which this code
fell into: **(1) `S._enabled()` must stay pause-blind** -- it gates `S.onVitals`, `S.disengage`
AND `S.onTick` together, so the obvious one-line fix would kill the escape ladder, the panic
tumble, the tincture and the forced disengage at a stroke (the bug with its sign flipped); the
gate belongs on the *idle assess* inside `onTick`, at its single call site, never inside
`_beginPull`, which stamps. **(2) The old gate was in the wrong PLACE** -- third line of
`_exploreTick`, above the swarm delegation -- and every swarm state machine self-ticks through
`M._scheduleTick`, so pausing froze the recovery loop: the ladder fired ONCE and then disabled
itself (`S.onVitals` returns early while `recovering`, and only the tick can leave that state),
until GO, which needs the user at the keyboard. It now sits BELOW the delegation. The arrival tick
is still re-armed while paused, deliberately -- `_beginEscape`'s indoor branch does not
self-schedule and has no other clock -- while the watchdog, being navigation-only, does not. It **stops** (restoring the saved basher state) on leaving Mnemosyne (strict `ataxiaBasher.inMnemosyne`, still detected during the pause), on `mnem explore off`, or the patrol cap. Safety: start-guard (`area==""`), stall watchdog, basher save/restore, `sysLoadEvent` reset, and **ice handling** — icy rooms print "You slip and fall on the ice as you try to leave" (move fails, but the exit is fine), so trigger `011_Ice_Slip.lua` → `onIceSlip` re-sends the move (no failed-exit charge) until you leave, capped at `MAX_ICE_SLIPS`. **Dizziness** (v4.7.426): "The ground seems to tilt and you fall with a thump." takes balance and fails the move, and can be uncurable, so trigger `mnemosyne/109` -> `onDizzyFall` re-sends the same way (timeout +3s for the lost balance; tactical moves go back to the swarm) and NEVER condemns the exit, not even at its `MAX_DIZZY_FALLS` cap -- the fall is ours, not the door's; the move timeout also skips the condemn while `ataxia.afflictions.dizziness` is up. **Wears armour before sweeping** (v4.7.175): `M._wearArmour()` fires from BOTH `exploreOn()` and `_exploreResume()` — the latter is the PER-RIPPLE entry (GO calls it after every boon screen), so armour is re-asserted before each dive, not only the first `explore on`. Sent DIRECTLY, not queued, because `queue addclearfull` wipes queued lines; deliberately ungated on a worn-check since there is no reliable worn-state to read and the failure mode of guessing wrong is exactly what it exists to prevent. Pure logic (`_nextExploreStep`/`_roomHasDenizens`) is unit-tested; the timer/event machine is validated in-game.
