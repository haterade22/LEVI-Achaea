# Apostate

## Metadata
- **Type**: Base Class
- **Combat Style**: Affliction | Damage
- **Difficulty**: Medium
- **Lock Affliction**: Voyria (blocks immunity elixir sip, cured first by Demon Syphon)

## Skills
```
Evileye: Gaze-based affliction application (delivers ALL lock afflictions)
Necromancy: Death magic, corpse manipulation, and Daegger Hunt
Apostasy: Demon summoning (Baalzadeen) and unholy powers
```

## Core Combat Mechanics
```yaml
combat_style: "Affliction-heavy momentum-based class"

evileye_afflictions:
  description: "Can deliver ALL lock afflictions via Evileye alone"
  lock_affs: [asthma, anorexia, paralysis, impatience]
  slickness_note: "Requires manaleech to be present to deliver slickness"

instakill:
  name: "Catharsis"
  condition: "Target at 50% mana or below"
  counter: "Prioritize sipping mana over health"

passive_cure:
  name: "Demon Syphon"
  tick: "Every 10 seconds"
  priority: "Always cures voyria FIRST if present"
  counter: "Time voyria application to land right after syphon tick"
```

## Daemonic Entities
```yaml
baalzadeen:
  description: "Primary demon companion, always with Apostate"
  abilities:
    syphon: "Passive cure every 10 seconds"
    restore: "Heal Apostate's health and mana (uses balance)"
    apathy: "Apostate takes no damage, then 60% of total when ends"
    trace: "Track target's movements (useful vs serpents)"
    strip: "Remove defenses"
    sear: "Fire damage"
    beckon: "Pull targets from adjacent rooms"
    catharsis: "Instakill at 50% mana"
  notes: "All abilities consume Baalzadeen's health"

bloodworms:
  description: "Summoned in room and adjacent rooms"
  afflictions: [masochism, dizziness, damage]
  trigger: "Activates when you are UNDEAF"
  counter: "Keep deafness up"

fiend:
  description: "Bleeding-focused entity (mutually exclusive with Nightmare/Daemonite)"
  effects:
    - "Applies bleeding"
    - "Applies haemophilia"
  synergy: "Combines with Daegger Hunt for massive bleed"
  danger: |
    Low bleeding builds up, then haemophilia applied.
    When you cure haemophilia, you've built up 600+ bleeding.
    Clotting drains mana significantly -> Catharsis range.
  counter: "Curseward or leave room when bleeding exceeds 500"

nightmare:
  description: "Sleep-focused entity (mutually exclusive with Fiend/Daemonite)"
  afflictions: [hypersomnia, dementia, hellsight]
  kill_route: "Opens sleep lock potential (rarely used, unreliable)"
  counter: |
    Put metawake up when afflicted with hypersomnia (if not low mana).
    Drop metawake when hypersomnia cured.
    Warning: Metawake has high mana drain.

daemonite:
  description: "Hinder-focused entity (mutually exclusive with Fiend/Nightmare)"
  effect: "Throws you off balance periodically"
  usage: "Mostly used as group combat hinder"
  counter: "Leave room"
```

## Kill Routes

### Primary Kill: Catharsis (Mana Kill)
```yaml
type: execute
summary: Drain mana to 50%, then Catharsis for instant kill

prerequisites:
  - Target must be at 50% mana or below
  - Baalzadeen must be present

steps:
  1: "Apply afflictions via Evileye to pressure curing"
  2: "Use Fiend + Daegger Hunt for bleeding pressure"
  3: "Target clots bleeding, draining mana"
  4: "Apply manaleech for additional mana drain"
  5: "When target at 50% mana, CATHARSIS <target>"

notes: "Primary kill method - always watch target's mana"
```

### Alternative Kill: Affliction Lock
```yaml
type: affliction
summary: Use Evileye to deliver all lock afflictions

steps:
  1: "Apply asthma via Evileye (blocks smoking)"
  2: "Apply anorexia via Evileye (blocks eating)"
  3: "Apply manaleech (required for slickness delivery)"
  4: "Apply slickness via Evileye (blocks applying)"
  5: "Apply paralysis via Evileye (blocks tree)"
  6: "Apply impatience via Evileye (blocks focus)"
  7: "Apply voyria for class-specific lock"
  8: "Damage to death or Catharsis"

required_afflictions:
  - asthma: "blocks smoking"
  - anorexia: "blocks eating"
  - slickness: "blocks applying (needs manaleech first)"
  - paralysis: "blocks tree"
  - impatience: "blocks focus"
  - voyria: "blocks immunity, but cured first by Syphon"
```

### Alternative Kill: Corrupt Burst
```yaml
type: damage
summary: Stack afflictions then Corrupt for massive damage

prerequisites:
  - Target must have many afflictions
  - Works best with Int spec (Grook Apostates)

steps:
  1: "Stack afflictions via Evileye and entities"
  2: "Include afflictions from allies if in group"
  3: "CORRUPT <target>"
  4: "Damage scales with TOTAL afflictions (not just Evileye)"
  5: "Follow up with Catharsis if not dead"

mechanics:
  - "Removes only Evileye-given afflictions"
  - "Damage scales based on ALL afflictions target has"
  - "Example: 5 Evileye affs + 3 entity affs = damage scales on 8"

notes: "Risky but viable, especially for Int spec Grook Apostates"
```

### Alternative Kill: Bleed Out (Fiend + Daegger)
```yaml
type: damage
summary: Stack bleeding through Fiend and Daegger Hunt

steps:
  1: "Summon Fiend"
  2: "Use Daegger Hunt for additional bleeding"
  3: "Fiend applies haemophilia to prevent clotting"
  4: "Bleeding builds rapidly"
  5: "Target dies to bleed or mana drain from clotting -> Catharsis"

notes: "Synergy between Fiend and Daegger Hunt is very effective"
```

## Offensive Abilities
```yaml
# Evileye
evileye:
  skill: Evileye
  balance: eq
  effect: "Apply affliction via gaze"
  syntax: "EVILEYE <target> <affliction>"
  afflictions:
    - asthma: "EVILEYE ASTHMA"
    - anorexia: "EVILEYE ANOREXIA"
    - slickness: "EVILEYE SLICKNESS (needs manaleech)"
    - paralysis: "EVILEYE PARALYSE"
    - impatience: "EVILEYE IMPATIENCE"
    - manaleech: "EVILEYE MANALEECH"
    - many_more: "Various mental/physical afflictions"

# Necromancy
daegger_hunt:
  skill: Necromancy
  balance: eq
  effect: "Causes bleeding, synergizes with Fiend"
  syntax: "DAEGGER HUNT <target>"
  notes: "Rebounding hinders this slightly"

soulspear:
  skill: Necromancy
  balance: eq
  effect: "Drain life from target"
  damage_type: magic
  syntax: "SOULSPEAR <target>"

# Apostasy
summon:
  skill: Apostasy
  balance: eq
  effect: "Summon daemonic entity"
  syntax: "SUMMON <entity>"
  entities: [baalzadeen, bloodworms, fiend, nightmare, daemonite]

catharsis:
  skill: Apostasy
  balance: eq
  effect: "Instant kill at 50% mana"
  syntax: "CATHARSIS <target>"
  notes: "Main execute - watch target mana!"

corrupt:
  skill: Apostasy
  balance: eq
  effect: "Massive damage based on affliction count"
  syntax: "CORRUPT <target>"
  notes: "Removes Evileye affs, damage scales on ALL affs"

beckon:
  skill: Apostasy
  balance: eq
  effect: "Pull targets from adjacent rooms"
  syntax: "BECKON" or "BECKON <target>"
  blocked_by: [offbalance, prone, being_blocked]
  notes: "Can beckon everyone or specific target"

gravehands:
  skill: Apostasy
  balance: eq
  effect: "Strong movement hinder"
  syntax: "GRAVEHANDS"
  counters: [evade, swing, aerial, "move 2 rooms away"]
```

## Defensive Abilities
```yaml
demon_syphon:
  skill: Apostasy
  effect: "Passive cure every 10 seconds"
  priority: "Always cures voyria FIRST"
  notes: "Time voyria to land right after syphon"

apathy:
  skill: Apostasy
  effect: "Take no damage, then 60% of total when ends"
  syntax: "ORDER BAALZADEEN APATHY"
  notes: "Trades immediate damage for reduced total"
```

## Passive Cures
```yaml
demon_syphon:
  cures: [various, voyria_first]
  tick: "Every 10 seconds"
  notes: "Always prioritizes curing voyria first"
```

## Limb Strategy
```yaml
enabled: false
notes: "Apostate is affliction/mana-based, not limb-based"
```

## Bashing (PvE)
```yaml
attack_command: "ORDER BAALZADEEN ATTACK <target>"
attack_skill: Apostasy
battlerage_abilities:
  - baalzadeen_attack: "Demon damage"
  - soulspear: "Magic damage"
```

## Fighting Against This Class
```yaml
priority_cures:
  - paralysis: "Cure first to maintain offensive pressure"
  - asthma: "Critical for smoking ability"
  - manaleech: "Prevents slickness delivery + drains mana"
  - slickness: "Restore salve application"
  - anorexia: "Restore eating ability"
  - haemophilia: "Prevent bleed buildup (cure before 500+ bleeding)"

dangerous_abilities:
  - catharsis: "INSTANT KILL at 50% mana - prioritize mana sipping!"
  - gravehands: "Strong movement hinder"
  - corrupt: "Massive burst damage based on affliction count"
  - fiend_daegger: "Bleed + haemophilia combo"
  - beckon: "Pulls from adjacent rooms"

avoid:
  - "Being below 50% mana (Catharsis range)"
  - "Letting bleeding build above 500 with haemophilia"
  - "Being undeaf near bloodworms"
  - "Standing in gravehands when you can escape"
  - "Having too many mental afflictions vs Int spec Apostate"

use_instead_of_shield: |
  CURSEWARD is better than shield when close to lock.
  Shield is not useless but well-timed curseward hinders more.
  Lower paralysis priority when curseward is up.

escape_strategy: |
  Gravehands counter: Evade, Swing up into trees, Aerial, etc.
  Normal movement has low success chance but try anyway.
  Once out, move 2 ROOMS away to avoid Beckon (only works adjacent).

rebounding: "Keep rebounding up - hinders Daegger Hunt slightly"

disloyalty: |
  If stacked properly (behind asthma), disloyalty can disrupt
  their entity-dependent offense significantly.

recommended_strategy: |
  PRIORITIZE SIPPING MANA over health - Catharsis kills at 50% mana!
  Keep deafness up to avoid Bloodworm afflictions.
  Cure paralysis first to maintain pressure.
  Watch for asthma + manaleech combo (slickness incoming).
  Curseward when close to lock instead of shield.
  If bleeding builds with haemophilia active, curseward or flee.
  Move 2 rooms away when escaping gravehands to avoid beckon.
  Time voyria application right after Demon Syphon tick (10s).
```

## Implementation Notes
```
Triggers to watch for:
- "Summoning up the curse of X" - Deadeyes curse (439_NEW_DEADEYES.lua)
- "fixes you with an icy stare" - Evileye affliction incoming
- "A fiendish * appears" - demon summoned
- "Baalzadeen syphons" - passive cure tick (10s cycle)
- "Gravehands burst from the ground" - movement hinder
- "beckons" - being pulled from adjacent room
- "corrupts you" - massive damage incoming
- "catharsis" - instant kill attempt (check mana!)
- "Bloodworms" - keep deafness up
- Fiend bleeding messages
- Daegger Hunt bleeding messages

Deadeyes Curse Mappings (439_NEW_DEADEYES.lua):
- clumsy → clumsiness
- stupid → stupidity
- dizzy → dizziness
- plague → voyria
- sicken → manaleech (first), slickness (if manaleech present)
- vomiting → nausea
- reckless → recklessness
- paralysis → paralysis
- sleep → hypersomnia
- bleed → haemophilia

GMCP considerations:
- Track gmcp.Char.Afflictions for current affs
- CRITICAL: Track gmcp.Char.Vitals.mp for Catharsis threshold
- Demon presence via room items
- Bleeding amount tracking important

Edge cases:
- Evileye is eq-based, entity orders vary
- Demon Syphon ALWAYS cures voyria first (10s tick)
- Slickness requires manaleech to be present first
- Corrupt removes only Evileye afflictions but damage scales on ALL
- Beckon blocked by offbalance, prone, or being blocked
- Beckon only works on adjacent rooms - move 2 away to escape
- Curseward > Shield when near lock
- Apathy: No damage during, then 60% of total at end
- Fiend/Nightmare/Daemonite mutually exclusive (only one in room)
- Bloodworms only trigger when undeaf

Catharsis Threshold:
- INSTANT KILL at 50% mana
- Always prioritize mana sipping
- Clotting bleeding drains mana significantly
- Watch for Fiend + Daegger bleed -> clot -> mana drain -> Catharsis
```

---

## CC_Apostate System (015_CC_Apostate.lua)

### Architecture
The Apostate offensive system was consolidated into a single `apostate` namespace following the Blademaster pattern. `015_CC_Apostate.lua` is the **sole** file in the apostate script dir — there are no 001-014 files. Everything (namespace, state, V3 routing, curse engine, attack builder, dispatch, backward-compat wrappers, and daemon utilities) lives inside 015.

### File Map
| File | Purpose |
|------|---------|
| `015_CC_Apostate.lua` | Complete unified system — namespace, state, V3 routing, curse engine, attack builder, dispatch, backward-compat wrappers (`015:860-946`), daemon utilities (`015:948-1045`). The only file in the dir. |

### Entry Point
```lua
apostate.dispatch()
-- 1. Validate target exists and is in room
-- 2. Check for aeon (don't act)
-- 3. Rebound hold gate (reboundHold.gate)
-- 4. Initialize pm (target mana) if not set
-- 5. Select curses via dual-slot engine
-- 6. Reset disfigure flag when asthma is no longer a curse
-- 7. Build attack (pre + main + post)
-- 8. Ensure baalzadeen is summoned (dedup via baalzadeenSummoned flag)
-- 9. Check for paralysis (don't send if paralyzed)
-- 10. Assemble and send via queue addclearfull freestand
-- 11. Start asthma confirm timer if manaleech was delivered (V3)
```

### Namespace & State
```lua
apostate = apostate or {}
apostate.state = {
  mode = "lock",              -- "lock", "corrupt", "vivisect", "sleep", "group", "mental"
  corrupted = false,          -- corrupt has been fired (awaiting catharsis)
  lastCorruptTime = 0,        -- corrupt cooldown tracking
  daeggerhere = false,        -- daegger summoned
  freshblood = false,         -- fresh blood available for bloodpact
  fiendthing = "nightmare",   -- preferred lesser daemon
  wantDisloyalty = false,     -- disfigure toggle
  disfigureSent = false,      -- disfigure spam protection (once per asthma round)
  disfigureTrigger = nil,     -- one-shot tempTrigger ID for disfigure on deadeyes text
  pendingDisfigure = false,   -- flag: disfigure should fire with next deadeyes
  asthmaConfirmTimer = nil,   -- timer: confirm asthma if target doesn't smoke after manaleech
  baalzadeenSummoned = false, -- summon sent, awaiting GMCP confirmation (prevents spam)
  partyrelay = true,          -- relay to party
}

apostate.config = {
  corruptThreshold = 0.7,   -- V3 probability threshold for corrupt consideration
  lockThreshold = 0.3,      -- V3 threshold for "has affliction"
  catharsisThreshold = 50,  -- mana % for catharsis execute
  sapThreshold = 60,        -- mana % for sap consideration
  debugEcho = false,        -- enable debug output
}
```

### Kill Routes (6 Modes)
| Mode | Command | Description |
|------|---------|-------------|
| **lock** | `apostate.setMode("lock")` | DEADEYES curse delivery with kelp stack + asthma-conditional branching toward truelock |
| **mental** | `apostate.setMode("mental")` | Flood goldenseal/lobelia mentals: impatience → stupid → dizzy → vertigo (all 25% deliver-once), paralysis-first on curse 2; transitions to lock selectors once `mentalReady()` (impatience 100% + 2 of stupidity/dizziness/vertigo at 25%). `015:410-464`, routed in `selectCurses` `015:501-505` |
| **group** | `apostate.setMode("group")` | Pure lock pieces only — no hinder (clumsiness/weariness), no probability gates |
| **corrupt** | `apostate.setMode("corrupt")` | Stack afflictions → `demon corrupt` for damage / catharsis setup |
| **vivisect** | `apostate.setMode("vivisect")` | Truelock → prone → shrivel 4 limbs → vivisect |
| **sleep** | `apostate.setMode("sleep")` | Wrapper-only mode (`levisleepapo()`); `selectCurses()` has **no** sleep branch, so it falls through to the lock curse selectors (no hypersomnia/sleep-specific curse logic — `015:468-511`) |

### Dual-Slot Curse Priority Engine
DEADEYES delivers 2 curses per action (2.3s balance). Each slot has an independent priority chain.

**Curse 1 (`selectPrimaryCurse`)** — Truelock chain with asthma-conditional branching:
```
Without asthma (prob < 33%):
  clumsiness (if < 33%) → weariness (if < 33%) → asthma
  Kelp stack: both clumsy + weariness must stick before asthma.
  Both are kelp-cured → forces 2 kelp eats before asthma can be cured.

With asthma (prob >= 33%):
  manaleech → impatience → sicken (slickness, gated by impatience)
  → anorexia (gated by slickness) → weariness
  → class lock affliction → plague (voyria fallback)
  Skip clumsiness entirely — lock speed over hinder pressure.
```

**Curse 2 (`selectSecondaryCurse(c1)`)** — Paralysis-first, fill missing lock pieces:
```
anorexia+sicken pairing (when c1 == "anorexia", pair with sicken
  unless both slickness AND paralysis are confirmed at 100%)
→ paralysis → asthma → manaleech (gated by asthma >= 33%)
→ impatience → sicken (gated by impatience + asthma >= 33%)
→ anorexia (gated by slickness) → weariness
→ class lock affliction → plague fallback
```

**Key rules:**
- Curse 2 never duplicates curse 1 — the `c1` parameter is checked at every step
- Sicken cascade: delivers `paralysis → manaleech → slickness` in order based on what target has
- Manaleech is smoke-cured — only delivered when asthma probability >= 33%
- Anorexia only delivered after slickness (no point blocking eating if they can still apply salves)
- Slickness delivered via sicken, gated behind impatience (blocks focus cure of anorexia)

**Group Mode (`selectPrimaryCurseGroup` / `selectSecondaryCurseGroup`):**
```
Curse 1: impatience → asthma → manaleech → sicken (slickness) → anorexia → class lock → plague
Curse 2: [anorexia+sicken pairing] → paralysis → fill remaining in same order
No probability gates, no hinder afflictions — pure lock pieces for coordinated group combat.
```

**Orchestrator (`selectCurses`):**
- Curseward detected → breach + secondary (all modes)
- Truelock >= 70% → class lock aff + secondary (all modes)
- Group mode → group curse selectors (no hinder)
- Mental mode → mental curse selectors (goldenseal/lobelia flood, then transition to lock)
- Lock mode → lock curse selectors (asthma-conditional branching)
- No `sleep` branch — sleep mode uses the default lock selectors.

**Class-lock curse mapping:** at every class-lock selection point the class affliction from `getLockingAffliction()` is passed through `toEvileyeCurse()` / `EVILEYE_CURSE_MAP` (`015:225-231`), which translates `paralyse` → `paralysis` (Jester/Occultist/Shaman) to match the Evileye curse name.

### Disfigure Integration
Disfigure is **NOT** inlined with `;`. The code deliberately avoids `;` (a server-side `;` would consume EQ before deadeyes fires — see inline comment `015:664-673`). Instead, on an asthma round `buildAttack` sets `pendingDisfigure`, and after the queued DEADEYES is sent, `dispatch()` arms a **one-shot `tempTrigger`** on the literal game text `"curse of asthma"` (`015:759`) that then sends `disfigure <target>` and self-kills:
- Only in lock (or mental) mode, once per asthma round (`disfigureSent` flag)
- Acts as an **asthma probe**: if target smokes before next balance, asthma was cured → skip manaleech
- If they don't smoke → asthma confirmed → safe to push manaleech next round
- Flag resets and the stale trigger is killed when asthma is no longer selected as a curse (`015:712-719`); trigger is also killed on mode change (`015:846-849`)

### Asthma Confirmation Timer (V3)
When manaleech is delivered and asthma probability is between 0 and 1.0:
- Start 2.5s timer
- If target doesn't smoke within 2.5s → `collapseAffPresentV3("asthma")` confirms asthma
- Rationale: manaleech is smoke-cured; if they can't smoke to cure it, asthma is blocking smoke

### Lock Progression
```
softlock  = asthma + anorexia + slickness
hardlock  = softlock + impatience
truelock  = hardlock + paralysis
classlock = truelock + voyria (class lock aff)
```

### Attack Builder Priority
Kill condition checks in order:
1. `needVivisect()` — All 4 limbs broken → vivisect
2. `needShieldStrip()` — Catharsis/corrupt ready but target shielded → demon strip
3. `needTrample()` — Truelocked + target prone → trample
4. `needCatharsis()` — Target mana below `catharsisThreshold` → demon catharsis
5. `needCorrupt()` — Corrupt damage >= assessed health, or pushes mana to catharsis range
6. Corrupt followup — Corrupt already fired + no shield → demon catharsis
7. `needShrivel()` — Vivisect mode, truelocked, prone, limbs remaining → shrivel next limb
8. Default: DEADEYES dual-curse delivery (arms `pendingDisfigure` on asthma rounds — fired later via one-shot trigger, not inline — + contemplate)

**Note:** `needSap()` / `sapThreshold` (60%) are defined (`015:570-572`) but **never consumed** by `buildAttack` (`015:636-681`) — a dead gate.

### Corrupt Damage Calculator
```lua
function apostate.corruptDmg()
  -- Physical affs × 7 + Mental affs × 8 + Smoke affs × 9
  -- V3 mode: weights each affliction by probability (0.0-1.0)
  -- V1/V2 mode: binary 1.0 or 0 per affliction
end
```

### V3/V2/V1 Tracking Integration
Same routing pattern as Blademaster:
| Helper | Purpose |
|--------|---------|
| `apostate.hasAff(aff)` | Check affliction via V3 → V2 → V1 routing |
| `apostate.getAffProb(aff)` | Get affliction probability (V3: 0.0-1.0, V2/V1: binary) |
| `apostate.getTrackingSystem()` | Returns "V3", "V2", or "V1" |
| `apostate.getLocks()` | Returns `{softlock, hardlock, truelock}` probabilities |

### Commands
| Alias | Regex | Action |
|-------|-------|--------|
| `cath` | `^cath$` | `apostate_lock()` → lock mode |
| `KELP STACK` | `^kel$` | class-conditional: `apostate_weari()` vs `apostate_kelp()` (Occultist/Pariah/Priest targets get weari branch) — lock mode |
| `apo` | `^apo$` | class-conditional: `apostate_weari()` vs `apostate_clumsy()` (Occultist/Pariah/Priest → weari) — lock mode |
| `MENTAL AFFS` | `^men$` | `apostate_mental()` → mental mode |
| `Illusion Curse` | `^kee$` | `apostate_clumsyillusion()` → lock mode |
| `Group Attack` | `^yy$` | `apostate_group()` (group mode) — **DISABLED** (`isActive: 'no'`) |
| `VIVISECT` | `^viv$` | **BROKEN** — calls undefined `apostate_viviprio()` (the defined wrapper is `apostate_vivisect()`); alias currently no-ops |

> Note: `^ll$` is the **Monk LEFT LEG** alias (sets `targetlimb` + `dwcprep()`), not an Apostate lock command. No `^slee$` or `^corr$` aliases exist — sleep mode is reachable only via `levisleepapo()`, corrupt mode only via `corruptKill()` / `cathCorrupt()`.

### Backward Compatibility (in 015, `015:860-946`)
| Legacy Function | Mode Set |
|-----------------|----------|
| `leviclumsapo()` | lock |
| `leviweariapo()` | lock |
| `levisleepapo()` | sleep |
| `apostate_lock()` | lock |
| `apostate_lockattack()` | (current) |
| `apostate_lockImpale()` | lock |
| `apostate_sleepattack()` | sleep |
| `apostate_clumsy()` | lock |
| `apostate_vivisect()` | vivisect |
| `apostate_weari()` | lock |
| `apostate_mental()` | mental (`setMode("mental")`, `015:909-912`) |
| `apostate_kelp()` | lock |
| `apostate_group()` | group |
| `apostate_clumsyillusion()` | lock |

Legacy global wrappers kept: `corruptDmg()`, `corruptKill()`, `cathCorrupt()`

### Daemon Utilities (in 015, `015:948-1045`)
Mostly **presence-check predicates and a predictor**, not summoners (except `bloodPact`). Global functions called by dispatch, the attack builder, and triggers:

| Function | Purpose |
|----------|---------|
| `bloodPact()` | Bloodpact setup (summons daegger / manages pentagram) — the one that actually issues commands |
| `bloodworm()` | Presence check: true if a bloodworm is in `ataxia.denizensHere` |
| `baalzadeen()` | Presence check: true if Baalzadeen is in `ataxia.denizensHere` |
| `apopentagram()` | Room-item check: true if "a floating silver pentagram" is in `zgui.roomItemList` |
| `demon()` | Returns the **current** lesser-daemon type string ("daemonite"/"nightmare"/"fiend", else "") |
| `daemonite()` | Presence check: true if a daemonite is present |
| `fiend()` | Presence check: true if a razor fiend is present |
| `nightmare()` | Timer-based hellsight/dementia affliction **prediction** (not a summon) — `015:1034-1045` |

### Pre/Post Attack Actions
**Pre-attack:**
- Bloodpact setup (fresh blood + no pentagram active)
- Daegger summon when catharsis/prone situations require it

**Post-attack:**
- Bloodworm summon (when fresh blood available)
- Daemon resummon (when wrong daemon type present)
- Disfigure for disloyalty (when asthma is held and `wantDisloyalty` enabled)

**Disfigure (one-shot trigger, NOT inline):**
- On asthma rounds, `buildAttack` sets `pendingDisfigure`; after the queued DEADEYES is sent, `dispatch()` arms a one-shot `tempTrigger("curse of asthma", ...)` that sends `disfigure <target>` (`015:759`). A `;` separator is deliberately avoided (it would consume EQ before deadeyes fires).

**Design decision:** Daegger hunt was intentionally removed from commands — it slows offense when seconds matter.

### Filler Afflictions
When all lock pieces are applied, the system falls through to filler curses:
```
stupidity, dizziness, weariness, nausea, confusion, addiction,
epilepsy, dementia, vertigo, recklessness, masochism, agoraphobia,
claustrophobia, paranoia
```
These increase corrupt damage and add curing pressure.

### Baalzadeen Summon Dedup
`baalzadeenSummoned` flag prevents summon spam during GMCP round-trip delay:
- Set `true` on summon send
- Reset `false` on success trigger (025) or failure trigger (014)

### Debug & Status
```lua
apostate.debugEcho()
-- Displays: current curses, stuck lock afflictions, tracking system
-- Format: [APO] Curses: c1 + c2 | Stuck(V3): asthma, impatience, ...

apostate.status()
-- Displays: mode, tracking system, corrupt damage estimate,
-- lock probabilities (soft/hard/true), current curse selections,
-- daemon type, corrupted state, target mana, last assess value
```

### Changelog
- **v1.0** (Jan 2025): Consolidated 14 files → single `015_CC_Apostate.lua`
- Integrated V3 affliction tracker (probability-based decisions)
- Dual-slot curse engine with sicken cascade
- Removed daegger hunt from attack commands
- Added corrupt damage calculator with V3 weighting
- Backward-compat wrappers (in 015, `015:860-946`) for all legacy function names
- **v1.1** (Mar 2025): Kelp stack + asthma-conditional branching
- Curse 1 rewritten: clumsy+weariness before asthma (kelp stack), skip clumsy once asthma lands
- Anorexia gated behind slickness (no point blocking eating if they can still apply)
- Slickness gated behind impatience (blocks focus cure of anorexia)
- Disfigure fired via one-shot `tempTrigger("curse of asthma")` after the queued deadeyes (probes asthma; `;` deliberately avoided so it doesn't consume EQ before deadeyes)
- Added asthma confirm timer (2.5s V3 collapse after manaleech delivery)
- Added baalzadeen summon dedup (`baalzadeenSummoned` flag)
- Added group mode with pure lock pieces (no hinder, no probability gates)
- Added reboundHold gate to dispatch
- Anorexia+sicken pairing in Curse 2 (fills uncertain slickness/paralysis)
