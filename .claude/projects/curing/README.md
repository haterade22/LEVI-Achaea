# Afflictions, locks and server-side curing: the reference that was in CLAUDE.md

> Moved verbatim from `CLAUDE.md` on 2026-11-13 (`docs/adrs/002-knowledge-delivery-tiers.md`). Until then every session loaded this text. It is not yet reconciled with the other documents of this subject: where they disagree, check the code or the game source, then correct the wrong one.

### Afflictions
- Negative status effects applied during combat (~55+ different afflictions)
- Must be cured in correct order (priority-based)
- Some afflictions hide or fake others (diagnosis required)
- GMCP provides: `gmcp.Char.Afflictions.List`, `.Add`, `.Remove`

**TRUTHSEEKER makes the `?` markers phantoms (v4.7.257).** The boon (uncommon) reads "The God
of Darkness allows your eyes to perceive the truth of all hidden afflictions that may befall
you" -- so while it is held there are no hidden afflictions and every `?` in the prompt is
false. **The prompt is the least of it**: `ataxia.afflictions.unknown` is a counter that only
ever goes UP in `gotUnknownAff` (nothing decrements it), and the Mnemosyne recovery gate reads
`unknown > 0` as a real affliction -- so a phantom count makes `S._afflicted()` permanently
true, `S._reenterReady()` can never pass, and every hover burns its full 60s cap. A live
screenshot showed ~20 banked. It also spammed `diagnose` via the `>= 2` branch. Refused at the
SOURCE (`gotUnknownAff` returns before even arming the next-line capture) rather than filtered
at each reader, because the boon means the INPUT is wrong; and the flag-setting paths (trigger
`mnemosyne/067`, the `BOON CLAIM` intercept) also CLEAR what is already banked, since they are
how the flag returns after a reload or mid-run re-latch -- by then the phantoms exist and
stopping new ones would leave the old ones forever.

#### Cure Types
| Action | Description | Examples |
|--------|-------------|----------|
| **Eat** | Consume herb or mineral | Bloodroot (paralysis), Kelp (asthma) |
| **Apply** | Apply salve to body part | Epidermal (anorexia), Mending (crippled) |
| **Smoke** | Smoke from pipe | Elm (aeon), Valerian (slickness) |
| **Sip** | Drink elixir | Immunity (voyria) |
| **Writhe** | Escape bindings | Entangled, Transfixed, Webbed |
| **Clot** | Stop bleeding | Bleeding |
| **Focus** | Mental cure | Breaks some locks |
| **Tree** | Tree tattoo | Cures random affliction |

#### Herb/Mineral Groupings
**Authoritative, code-checked version: `kb/afflictions/catalog.md`** (generated from the game's HELP 13.7.2 joined to our cure and priority tables). The lists below are a quick summary.

Each herb has an alchemical mineral equivalent (same cure balance):
- **Ginseng/Ferrum**: Addiction, Haemophilia, Lethargy, Nausea
- **Kelp/Aurum**: Asthma, Clumsiness, Sensitivity, Weariness
- **Goldenseal/Plumbum**: Epilepsy, Impatience, Stupidity, Dizziness
- **Bloodroot/Magnesium**: Paralysis, Slickness (alt)
- **Lobelia/Argentum**: Agoraphobia, Recklessness, Vertigo
- **Bellwort/Cuprum**: Generosity, Pacifism, Peace
- **Prickly Ash/Stannum**: Confusion, Dementia, Paranoia

#### Complete Cure Herb Reference
**Sources:** [Venom (Skill)](https://wiki.achaea.com/Venom_(Skill)), [Oppression](https://wiki.achaea.com/Oppression)

| Herb | Afflictions Cured |
|------|-------------------|
| **kelp** | clumsiness, healthleech, weariness, asthma, sensitivity, parasite |
| **ginseng** | nausea, haemophilia, addiction, darkshade, flushings, lethargy, scytherus |
| **goldenseal** | stupidity, impatience, depression, sandfever, epilepsy, dizziness, dissonance, shyness |
| **lobelia** | recklessness, vertigo, spiritburn, tenderskin, loneliness, claustrophobia, masochism, agoraphobia, hypochondria |
| **ash** | confusion, hypersomnia, hallucinations, paranoia, dementia, crescendo |
| **bellwort** | timeloop, justice, lovers, peace, pacified, generosity, indifference, diminished |
| **bloodroot** | paralysis |

#### Venom → Affliction → Cure Reference
| Venom | Affliction | Cure | Combat Use |
|-------|------------|------|------------|
| **curare** | paralysis | bloodroot | Venomlock, prevent tree |
| **kalmia** | asthma | kelp | Softlock, block smoking |
| **xentio** | clumsiness | kelp | Kelp stack, 33% miss chance |
| **euphorbia** | nausea | ginseng | Block parry, enable limb prep |
| **gecko** | slickness | bloodroot (or smoke valerian) | Softlock, block salves (smoking valerian only works without asthma) |
| **slike** | anorexia | apply epidermal (or FOCUS) | Softlock, block eating |
| **prefarar** | sensitivity (or removes deafness) | kelp | Damage amplification |
| **vardrax** | addiction | ginseng | Riftlock helper, eating triggers cooldown |
| **delphinium** | sleep | wake/insomnia | Sleeplock, prone via leg break |
| **epseth** | crippled leg (level 1) | mending | Limb pressure |
| **epteth** | crippled arm (level 1) | mending | Limb pressure |
| **voyria** | voyria (sip damage) | antidote | Lock aff for healers |
| **eurypteria** | recklessness | lobelia | Lock aff for Depthswalker |
| **digitalis** | shyness | goldenseal | Mental stack |
| **larkspur** | dizziness | goldenseal | Mental stack |
| **monkshood** | disloyalty | smoke valerian | Hinder loyalty-based abilities. "Disfigurement" is the OLD name: the game still accepts it but answers with Disloyalty, and our code must record `disloyalty` |
| **aconite** | stupidity | goldenseal | Mental stack, focus bait |
| **darkshade** | darkshade (light allergy) | ginseng | Hinder targeting |
| **notechis** | haemophilia | ginseng | Lock aff for Magi/Sylvan, Agony synergy |
| **sumac** | none: DAMAGE only | n/a | Not an affliction venom (wiki Venom (Skill): "minor damage to adventurers and denizens"; it gives no affliction). No venom gives impatience. |
| **vernalius** | weakness | kelp | Hinder physical actions |
| **oleander** | blindness | apply epidermal | Hinder targeting |
| **colocasia** | blindness + deafness | apply epidermal (each) | Full sensory denial |
| **loki** | random affliction | varies | Unpredictable pressure |

#### Hellforge Investments (Infernal Only)
| Investment | Affliction | Cure | Notes |
|------------|------------|------|-------|
| **INVEST TORTURE** | haemophilia | ginseng | Enables Agony passive healing |
| **INVEST EXPLOIT** | weariness + paranoia | kelp + ash | Two affs at once, blocks Fitness |
| **INVEST TORMENT** | healthleech | kelp | Sustained damage, confusion if already has healthleech |
| **INVEST PUNISHMENT** | scaling damage | n/a | More damage on wounded targets |

#### Affliction Locks

**See also**: `.claude/classes/lock_types.md` for comprehensive documentation.

##### Softlock (3 affs)
```yaml
afflictions:
  asthma: "Prevents smoking pipes - cured by eating Kelp"
  anorexia: "Prevents eating herbs - cured by applying Epidermal or Focus"
  slickness: "Prevents applying salves - cured by eating Bloodroot or smoking Valerian"
escape: "FOCUS to cure anorexia, then eat bloodroot, then eat kelp"
```

##### Venomlock (4 affs)
```yaml
afflictions: [paralysis, asthma, anorexia, slickness]
paralysis: "Prevents Tree tattoo - cured by eating Bloodroot"
escape: "FOCUS to cure anorexia, then eat bloodroot (cures para OR slick)"
```

##### Truelock / Hardlock (5 affs)
```yaml
afflictions: [paralysis, asthma, anorexia, slickness, impatience]
impatience: "Prevents using Focus - cured by eating Goldenseal"
escape: "None without external help"
requires: "Class-specific affliction to block passive cures"
```

##### Focuslock (Alternative to Truelock)
```yaml
afflictions: [paralysis, asthma, anorexia, slickness]
strategy: "Stack mental afflictions (goldenseal cures) instead of impatience"
mental_affs: [stupidity, dizziness, epilepsy, shyness, depression]
escape: "Focus may randomly cure anorexia instead of mental aff"
```

##### Riftlock (Limb-based)
```yaml
afflictions:
  broken_arms: "2 broken arms - prevents rifting herbs"
  slickness: "Prevents applying mending salve"
  asthma: "Prevents smoking valerian"
helper: "Addiction (Vardrax) forces eating held items"
escape: "Smoke valerian → mend arms → rift herbs"
```

##### Salvelock (Enhanced Riftlock)
```yaml
afflictions:
  mangled_arms: "Level 2+ breaks - prevents Restore ability"
  slickness: "Prevents applying mending"
  asthma: "Prevents smoking"
escape: "Very difficult - requires multiple mending applications"
```

##### Sleeplock (Timing-based)
```yaml
steps:
  1: "First Sleep/Delphinium strips Insomnia defence"
  2: "Second strips Gypsum/Kola defence"
  3: "Third puts opponent to sleep"
timing: "All three must hit in rapid succession"
```

##### Aeonlock (Time-manipulation)
```yaml
afflictions:
  aeon: "Only one action at a time on lengthy balance"
  asthma: "Prevents smoking Elm to cure aeon"
strategy: "Stack kelp affs to keep asthma stuck"
kelp_stack: [asthma, clumsiness, sensitivity, weariness, healthleech]
```

**`getLockingAffliction()` returns a CURSE NAME, not an affliction (2026-10-11).** It is inline in `_groups.yaml`. Called with `"name"` it returns the target class's lock AFFLICTION (`voyria`, `recklessness`, `haemophilia`, ...). Called any other way it returns the SHAMAN `CURSE <target> <name>` word: `plague`, `reckless`, `stupid`, `weariness`, `paralyse`, `haemophilia` (wiki Curses). An Apostate's DEADEYES takes AFFLICTION words, `paralysis` among them, and SICKEN gives MANALEECH first, then slickness, not paralysis (Mystor's log, 2026-10-11; `kb/CONFLICTS.md`). There is no haemophilia stare, so that word is not valid for every class. The Infernal group lock sent the curse word as a VENOM ("plague") until v4.7.407. Ask for `"name"` and map the affliction to your own class's delivery.

#### Class-Specific Lock Afflictions
| Classes | Extra Affliction | Blocks |
|---------|-----------------|--------|
| Knights, Monk, Serpent, Sentinel, Druid, Blademaster, Elemental Lords | Weariness | Various passive cures |
| Apostate, Pariah, Bard, Priest | Voyria | Sip-based healing |
| Magi, Sylvan | Haemophilia | Blood-based cures |
| Alchemist | Stupidity | Transmutation cures |
| Depthswalker | Recklessness | Shadow cures |
| Psion | Confusion | Mental cures |
| Jester, Occultist, Shaman | Paralysis | Already in base lock |

#### Server-Side Curing (SSC)
Achaea provides built-in curing that simulates average latency. Custom systems can integrate with or replace it.

**Core Commands:**
| Command | Description |
|---------|-------------|
| `CURING ON/OFF` | Enable/disable the system |
| `CURING STATUS` | Show current curing status |
| `CURING AFFLICTIONS ON/OFF` | Toggle affliction curing |
| `CURING DEFENCES ON/OFF` | Toggle defence upkeep |
| `CURING SIPPING ON/OFF` | Toggle health/mana sipping |
| `CURING SIPHEALTH/SIPMANA <percent>` | Set sip thresholds |
| `CURING FOCUS ON/OFF` | Toggle FOCUS ability usage |
| `CURING TREE ON/OFF` | Toggle TREE tattoo usage |
| `CURING BATCH ON/OFF` | Send multiple cures at once |

**Priority Management:**
| Command | Description |
|---------|-------------|
| `CURING PRIORITY LIST` | List affliction cure priority |
| `CURING PRIORITY <aff> <priority>` | Move affliction priority |
| `CURING PRIORITY <aff><N> <priority>` | Priority at exactly N stacks (e.g. `BURNING5`) |
| `CURING PRIORITY RESET` | Reset to default priority |
| `CURING PRIORITY DEFENCE LIST` | List defence upkeep priority |

**BASE + PER-STACK, and a bare write is the BASE (announcement 2026-08-19, v4.7.278).** A bare
`CURING PRIORITY BURNING 8` answers every stack count with no entry of its own; `BURNING5 2`
overrides at exactly five. The two used to conflict, which is why our table carried a value for
EVERY level of every stacking affliction -- and why its bare entries were **unreachable**, along with
every runtime write that targeted them. **The Damnation defence was one of those**: it raised
`curing priority burning 1`, the one value the per-stack entries override, so the response to the
Paladin kill condition had never taken effect. Rules that follow:
- **Never write a bare stack name to escalate** -- a bare write is the base, and the base is what the
  overrides beat. `002_Damnation_Defence.lua` and the anti-Magi/Firelord swaps all write the LEVEL.
- **Only escalate a level that has a static entry** in `ataxia_defaultCuringPrios()`, so
  `ataxia_restorePrio` has an exact value to put back on `normal`. On a class set the value is that set's own, and an
  unknown one writes nothing (v4.7.480, below). `ataxia_defaultPrioAff` falls back to
  the family base for a level with no entry of its own; without it the restore concatenated nil.
- **Escalate the STATIC table, not just the dynamic swap.** `Algedonic.AntiPaladin` only runs once
  the target is KNOWN to be a Paladin, so a missed class read used to cost the entire response.
  `burning5 = 2` in the table answers the same threat with no detection at all.
- **A family's escalation must be re-flattened in the PvE delta whenever the cure shares a contended
  balance.** Burning is salve-cured, so `burning5 = 2` would outbid every limb for mending -- the
  exact failure the bash profile exists to fix. See `008_Bash_Curing_Profile.lua`.
- **A stacking aff with a BARE-ONLY entry is correct** (pressure, the fracture family, `tempered*`):
  one base covers every count. Do not "complete" them.
- Nothing parses a **rejected** `curing priority`. After adding any suffixed name: `reset prios`
  from `normal` (since v4.7.480 it writes nothing on any other set), then `CURING PRIORITY LIST`, and confirm it came back. Silence is not success.
- **Deleting a key from the Lua table does NOT delete the row from the server-side curingset.**
  `ataxia_sendDefaultPrios` only writes what the table holds; it never sends
  `CURING PRIORITY RESET`. Orphaned per-stack rows persist at their old values, so a base changed
  without accounting for them produces a value that never applies -- the same class of bug the
  base/override change fixed.
- **Bulk writes use the MULTI-SET form** (v4.7.403): `curing priority a 1 b 2 ...`, built by `ataxia_prioMassCommands` (20 pairs a command), one command a second. One affliction per command in bursts of 5 sat exactly at Announce #5450's 5-a-second limit, and a live login drew seven "You have exceeded the spam threshold for curing priority" refusals, each a DROPPED write. Trigger 787 now catches that line: `ataxia_prioSpamRejected` forgets the recorded send and retries once (at most once a minute).
- **The throttle counts COMMANDS, not calls** (`ataxia.prioThrottle`, v4.7.276). Semicolon batches
  are charged for every command in them; the server cap is 5/sec and several sites batch three.
- **A swap that WRITES needs a restore designed with it.** `Algedonic.AntiPaladin` wrote stored
  priorities for years with no restore anywhere -- survivable only because the writes were
  unreachable. A restore also has to answer two questions the write does not: can it actually send
  right now (the bash-set guard drops these), and how does it recover if its latch is lost to a
  reload.

**The table only matters once it is SENT (v4.7.397).** Editing `ataxia_defaultCuringPrios()` changes nothing on the server by itself: until v4.7.397 only `reset prios` sent it, and a live capture found the `normal` set two months behind. Now `ataxia_sendDefaultPrios()` stores a fingerprint (`ataxia.settings.prioSentSig`) after its LAST batch, and `ataxia_prioSyncCheck()` (login +20s) re-sends a changed table, after `ataxia_curingsetRefresh` confirms the active set is `normal`; in any other set it only tells the user. Verify with a captured `CURING PRIORITY LIST` and `python tools/kb_prio_diff.py <file>`.

**Curingsets** (save/load priority configurations):
| Command | Description |
|---------|-------------|
| `CURINGSET NEW <name>` | Create new curingset |
| `CURINGSET SWITCH <name>` | Switch to a curingset |
| `CURINGSET LIST` | List all curingsets |
| `CURINGSET CLONE <from>` | Clone into current setup |

**KNOW WHAT SETS EXIST BEFORE TOUCHING THEM (v4.7.247).** `ataxia/009_Curingset_State.lua`
parses `CURINGSET LIST` into `ataxia.curingsets` (ordered list, per-name COUNTS so duplicates
stay visible, the `(current)` marker, used/allowed) via TEMP triggers armed only when we asked
-- a set-name row is a bare lowercase word and would be a catastrophic permanent trigger.
Queries answer **nil = unknown** as a third state; a caller reading unknown as "no" creates a
set that already exists (burning one of a hard-capped 22) or refuses one that does. This exists
because `ataxia_bashProfileInstall` used to send `curingset new`/`switch` and then write ~55
`curing priority` commands on timers ASSUMING both worked -- at the cap (live capture: 22 of 22)
both fail, the PVP set stays active, and those writes rewrote it, while `installed = true` was
set regardless. It is the one path that bypasses `ataxia_sendCuringPriority`'s guard by calling
`send()` directly. Now: `ataxia_bashInstallDecide` (pure, tested) returns proceed/create/abort,
**an unreadable list ABORTS rather than falling through to create**, `create` re-reads the list
to VERIFY the set appeared before writing, `bashProfileOn` refuses a set proven absent, and
`aconfig bashcuring status` reports what the GAME says instead of the old `installed` flag
(which only ever meant "we ran the installer"). `classDetect.setup()` was equally blind --
`curingsetMap` names 27 sets against a cap of 22 and it sent every `curingset new` silently
(`send(..., false)`), so it could never succeed and never said so; it now plans against free
slots (`classDetect.planCuringsets`, pure + sorted so drops are deterministic) and reports what
it could not create. Command: `curingsets`.

**`classDetect` stays on `normal` while in a party (v4.7.474).** `classDetect.inParty` reads `ataxia.channels.party` (GMCP `Comm.Channel.List`). The target is who the leader calls and many people attack us, so one class says little: the 2026-11-03 group fight switched sets 77 times in 19 minutes.

**A target change switches the set only while no one is hitting us** (`classDetect.facingClass`, `class_detect/001`). A hit is a class line that names us (`classDetect.noteHit`).

**An automatic shield waits for a due lock-breaker, for at most 4 s** (`ataxia_shieldWaitsForLockBreak`, `can(x)/003_Lock_breakers.lua`; the user, 2026-11-09: "Lock breaker and then shield"). A new automatic `touch shield` must ask it, unless it answers a blow that lands now.

**CRITICAL: `CURING PRIORITY <aff> <n>` writes a STORED priority into whichever curingset is
ACTIVE.** Any code path that writes priorities while a non-default set is selected mutates
that set permanently. Until v4.7.480 `ataxia_restorePrio()` then wrote the *default* table's value
into the *other* set, rotting it one affliction at a time; it now writes that set's own value (below). Route every priority write through
`ataxia_sendCuringPriority()` (`ataxia/ataxia/002_Prio_Management.lua`), which throttles to
4/sec (server limit 5/sec, Announce #5450) **and** drops stored affliction writes while the
PvE bash set is active. The one exception is the batch at a `classDetect` switch, one `send()` charged to the same window.
A swap we will undo goes through `ataxia_setAffPrio` or `ataxia_sendPrioSwap`, which call it and record the swap. Its classifier matched **letters only** until v4.7.278, so every
stack-suffixed write (`curing priority burning5 9`) slipped the guard into whatever set was
active. The [+]/[-] links in `ataxia_showPrios` write any name in `ataxia.curingprio`. Trigger 717 only fills that cache, and the chain it belongs to could not open on the game's header (716's pattern) since at least the 2026-10-10 capture (fixed v4.7.480), so which names reached those links before then is unproven. `CURING PRIOAFF <aff>` is a *temporary* prioritisation, writes nothing
stored, and is always safe.

**One priority list per curingset (v4.7.480, `ataxia/ataxia/002_Prio_Management.lua`:163-258, tests `src_new/tests/test_curingset_priorities.lua`, on a fake server;
not run in Mudlet; design and limits in `kb/curing/server-side-curing.md`).** The user: "The purpose of curing sets is to set priorities based on the class you are facing. Classes through skills can only give specific afflictions. So we do curing  sets for them. If Infernal can never give impatience. no need for Impatience to be curing priority impatience 2". So a class set's values are its own:
- `ataxia.curingprio` mirrors the ACTIVE set only, once a `classDetect` switch, a login read of a class set or a typed list has refreshed it. It is saved with `ataxia`, and a login that lands on `normal` does not refresh it, so it can then hold another set's values. `ataxiaPrioSets.baseline[set]` holds a class set's values, read from the game, and `ataxiaPrioSets.live[set]` names the swaps the game has not confirmed back.
  `ataxiaPrioSets` is not saved with `ataxia`; a package reload or a connection keeps all but the reads in flight (`ataxia_prioSetsReset`, :234). For a Mudlet restart the names left up and their own values go to `ataxia_curingset_swaps.lua` in the profile folder (:179).
- **The switch is one send** (`ataxia_switchCuringsetSend(name, from)`, :595; `classDetect` calls it through `switchSend`, `class_detect/001`:214): the set we leave goes back to its own values, then
  `curingset switch <name>`, then `curing priority list`. Queued stored writes are dropped, and defence writes are kept. The cache empties, so `ataxia_getPrio` answers 0 until the list arrives. A read lost on a repeat visit or on `normal` is not asked again, so that visit's cache stays empty (Limits in the kb page).
- **The read is hidden.** Trigger 716 now matches the real header (`Your affliction curing priorities for the priority set <name>:`). Its old exact pattern could not match that header, so 716/717/718 could not open on it since at least the 2026-10-10 capture.
  A list the user types still prints the game's own lines and changes no baseline, and it now refreshes the cache and saves.
- **The restore rule.** `ataxia_restorePrio` (:469) on a class set writes that set's baseline value, else the value the file kept for a name left up at a restart, and nothing when neither is known. On `normal` it writes the table in `ataxia_defaultCuringPrios()`. The name stays live until trigger 719 confirms that value, so a refused or dropped restore goes back at the next switch.
- **A swap needs a baseline.** `ataxia_setAffPrio` and `ataxia_sendPrioSwap` (:458) write nothing on a class set whose list has not been read, or on any set while it is unknown; a read that gave way is asked again, up to 3 times.
- **On a class set, a value the user tunes during a visit is adopted** (`ataxia_prioTuned`, :788, from trigger 719). `ataxia_sendDefaultPrios` stops at a `classDetect` switch or bash on (`ataxiaPrioGen`). No write passes the queue, except the one send at a switch, which drops the queued stored writes first.
- **A confirmation line is never adopted by the wrong set.** The line can arrive from the set we left at any lag. `echoes` (:366-409) lists the lines we expect per name: leaving (a name going back at a switch), cancelled (a restore overtaken by a newer swap) and plain (a swap's own line). A line takes a cancelled entry first, then a leaving one, then the oldest plain one; a name's list is trimmed to 8 by dropping its oldest entries that are not leaving. A line with no entry is not adopted during the quiet window while replies are overdue (`quietUntil`).
- **Login does not know which set the server is on.** `ataxia_prioLoginStart` (:812) marks it unknown first: no swap, no restore and no adoption until it is known. A six-class `ataxia_loginCuringsetNormal` (`login/001_Login_Function.lua`:19) makes it known and moves a bash session's `restoreTo` to `normal`. `ataxia_prioLoginRead` (:822), last in `levilogin`, asks with a hidden `CURINGSET LIST` and sends no switch; on a class set it also reads the list, hidden. With the bash profile active the set stays unknown until bash off names it (`ataxia_prioBashReleased`, :862). A link drop sets `offline` (:265): no switch, no restore, and no state change until `levilogin`.
- **`reset prios` asks the game first** (`ataxia_resetPrios`, `001_Default_Curing_Prios.lua`:187): it writes only on `normal`, and otherwise prints one line and writes nothing. While bashing it does not ask and leaves the bash set first, as before, so the global table lands in the set it returns to.

**PvE bashing curing profile** (`ataxia/ataxia/008_Bash_Curing_Profile.lua`, v4.7.172): the
default table (`001_Default_Curing_Prios.lua`) is tuned entirely for PvP, which loses bashers.
Its stated reason named two contended balances that the PvP ordering spends on afflictions that do
nothing to a denizen. **The first is WRONG: potash/moss does NOT share the eating balance.** It has its own
clock (settled 2026-11-07, `kb/CONFLICTS.md` #11, now Resolved): in our Serpent spar all 4 of Saibel's potash
eats fell inside her herb eat-to-eat, one 0.001 s after a magnesium (`kb/raw/logs/ours/2026-11-07_164635_Saibel.log`
rows 415, 418), and her herb eats stayed 1.506 s or more apart around them; Mystor's client already timed moss on its
own `[Moss Recov]`, and an Apostate ate plumbum and potash in the same second. So moss costs the basher no cure-mineral.
The second stands: **mending/restoration shares the SALVE balance with crackedribs/fractures/traumas**. So the PvE table
inverts it — cure-channel blockers (anorexia/slickness/paralysis) > limbs at 4-6 (arms gate
the attack, legs gate every escape) > damage math > salve competitors parked at 20 > junk
mental spray parked at 25. It also **re-flattens the PvP burn escalation** (`burning4`/`burning5`
back to the base): burning is salve-cured, so the PvP `burning5 = 2` -- which exists because broken
head + burning 5 IS Damnation -- would outbid every limb for mending, and a denizen cannot perform
Damnation. Held in a server-side `bash` curingset so the swap is ONE command
rather than ~55 throttled pushes (~15s). Switched on `"basher enabled"` / `"basher disabled"`;
opt-in via `aconfig bashcuring install`. A priority at/above `ataxiaBashProfile.PARKED` (20)
means SSC will not cure it, so it stays up for the whole fight — **anything testing
"affliction-free" must treat a parked aff as not-an-affliction** (see `S._afflicted` in
mnemosyne/009, whose recovery hover would otherwise never land). Full detail in
`memory/curing.md`.

**Manual Queue:**
| Command | Description |
|---------|-------------|
| `CURING QUEUE ADD <cure>` | Add manual cure to queue |
| `CURING QUEUE LIST` | List queue contents |
| `CURING PREDICT <aff>` | Tell system you have an affliction |
| `CURING PRIOAFF <aff>` | Temporarily prioritise an affliction |

**Example Pattern (Ataxia style):**
```lua
ataxia.afflictions = ataxia.afflictions or {}

local function affsAdd()
  local aff = gmcp.Char.Afflictions.Add.name
  ataxia.afflictions[aff] = true
  raiseEvent("aff gained", aff)

  -- Special handling
  if aff == "amnesia" then
    send("touch flaws")
  elseif aff == "aeon" then
    send("curing batch off")
  end
end

registerAnonymousEventHandler("gmcp.Char.Afflictions.Add", affsAdd)
```
