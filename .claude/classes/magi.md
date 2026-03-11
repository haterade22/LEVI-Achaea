# Magi

## Metadata
- **Type**: Base Class
- **Combat Style**: Affliction | Damage (Hybrid)
- **Difficulty**: Hard
- **Lock Affliction**: Haemophilia (prevents clotting, disrupts cure system)
- **Offense System**: `magi.offense` namespace (`004_Magi_Offense.lua`)
- **Dispatch**: `zz` → `magi.offense.dispatch()`, mode switch via `mm <mode>`

## Skills

### Elementalism
Elemental magic channelling fire, water, air, and earth. Core offensive skill. Requires opening channels to elemental planes (200 mana each, willpower maintenance cost). Channels can be attacked — protect with Fortification or Binding.

### Crystalism
Vibrational crystal magic using refined crystal shapes embedded in rooms. Provides room control, afflictions, and utility. Requires a Master Crystal (in House/City hall) to refine shapes. Vibrations persist in rooms until dampened or destroyed.

### Artificing
Staff creation and crystal enhancement. The Magi staff is the primary combat weapon — holds up to 4 crystals that modify staffcast behavior. Also includes elemental summoning treaties.

---

## Resonance System

The core combat mechanic. Every Elementalism spell builds resonance in its element(s) from 0→3 (minor→moderate→major). Each level triggers a passive affliction on the target. At level 3 (major), EMANATION consumes all 3 stacks for a powerful burst effect.

### Resonance Levels & Passive Effects
```yaml
air:
  1 (minor): "asthma"
  2 (moderate): "sensitivity"
  3 (major): "healthleech"
  emanation: "paralysis + dizziness"

earth:
  1 (minor): "random limb break"
  2 (moderate): "stun + paralysis"
  3 (major): "cracked ribs"
  emanation: "calcified skull (blocks head cures) / calcified torso (blocks restoration)"

fire:
  1 (minor): "strips temperance → scalded (or ablaze if already scalded)"
  2 (moderate): "blistered"
  3 (major): "burning +2"
  emanation: "burning +2 (cap 5)"

water:
  1 (minor): "frostbite"
  2 (moderate): "stuttering + cold damage"
  3 (major): "anorexia"
  emanation: "hypothermia setup"
```

### Resonance Budgeting
- **Never waste capped resonance** — if fire==3, emanate fire before casting more fire spells
- Emanation consumes all 3 stacks and delivers the emanation effect
- Building past 3 wastes the passive effects at each level
- Some spells build multiple elements (e.g., magma = earth+fire, mudslide = earth+water)

### Resonance from GMCP
Resonance levels are read from `gmcp.Char.Vitals.charstats` via `get_resonance()` in `001_Resonance.lua`. Stored in `magi.resonance = {fire=N, water=N, earth=N, air=N}`.

---

## Elementalism Spells (Complete Reference)

### Offensive Spells (Resonance-Building)

| Spell | Elements | EQ | Afflictions / Effects | Notes |
|-------|----------|----|-----------------------|-------|
| **Firelash** | Fire | ~2.3s | ablaze (burning), burns +1 | Ranged/melee fire damage; melts icewalls |
| **Freeze** | Air/Water | ~3.0s | shivering → frozen → hypothermia chain | Strips insulation; requires shivering + 1 broken limb for frozen |
| **Dehydrate** | Fire/Water | 2.3s | weariness + nausea (both missing); burning + frozen (if weariness present + nausea absent) | Complex branching — see trigger 015_Dehydrate.lua |
| **Fulminate** | Air/Fire | 2.4s | fulminated → epilepsy → paralysis (smart chain) | Lightning bolt; burns +1 |
| **Bombard** | Air/Earth | 2.4s | clumsiness | Rock barrage |
| **Mudslide** | Earth/Water | 2.3s | slickness + prone | Knockdown; key lock spell |
| **Magma** | Earth/Fire | 2.3s | scalded (20s duration) | Can't re-magma while scalded |
| **Transfix** | Air/Fire | 3.0s | stupidity (if moderate+ resonance) | Mesmerization; removes blindness |
| **Gust** | Air | 3.0s | none (knockback) | Directional push or room clear |
| **Geyser** | Earth/Fire/Water | 3.0s | none (disruption) | Removes flying/treed targets |

### Higher-Order Spells

| Spell | Elements | EQ | Requirements | Effects |
|-------|----------|-----|-------------|---------|
| **Hypothermia** | Air/Water | 2.6s | Target frozen | Removes freeze cure ability; setup for glaciate |
| **Shalestorm** | Earth | 2.4s | Earth resonance ≥2 | Periodic pummeling with limb breaks; stays active |
| **Firestorm** | Air/Fire | 4.0s | None | Room-wide spreading fire; no caster immunity |
| **Conflagrate** | Fire | 2.35s | Burns ≥2, fire ≥2 | Sets conflagrated flag; periodic damage |
| **Glaciate** | Air/Water | 3.0s | Target frozen + hypothermia, water≥2, air≥2 | Heavy damage — primary water kill route |
| **Emanation** | Per element | 2.4s | Major resonance (level 3) | Consumes 3 stacks for burst effect (see above) |
| **Convergence** | All four | 2.9s | Moderate resonance in all 4, dissonance stage 4 | Marks target; bypasses shields |
| **Purity** | Water | 3.0s | Major water resonance | Removes resonance; grants affliction immunity |

### Staffcast Abilities (from Elementalism)

| Ability | Elements | EQ | Requirements | Effects |
|---------|----------|-----|-------------|---------|
| **Destroy** | Fire | 3.6s | Conflagrated + target ≤40% HP | **Instant kill**. Enhanced by ashbeast (bypasses starburst) |
| **Stormhammer** | Air/Fire | 6.0s | 1200 mana | High damage to 1-3 same-city enemy targets |
| **Holocaust** | Fire | 6.0s | 1500 mana | Delayed explosion (10-60s timer); room-wide |
| **Magmasphere** | Earth/Fire | 6.0s | — | Delayed magma eruption; breaks limbs |

### Defensive Spells

| Spell | Elements | EQ | Effect |
|-------|----------|-----|--------|
| **Reflection** | Air/Fire | 3.0s | Illusion absorbs one attack |
| **Stonefist** | Earth | 4.0s | Prevents staff disarming |
| **Stoneskin** | Earth | 2.0s | Physical damage reduction (blunt > cutting) |
| **Chargeshield** | Air/Earth | 4.0s | Electric damage resistance |
| **Bloodboil** | Fire/Water | 4.0s | Self-affliction cure; potential double cure at Fire/Water major |
| **Diamondskin** | Earth/Fire/Water | 2.0s | Cutting resistance + modest blunt reduction |

### Terrain Spells

| Spell | Elements | EQ | Effect |
|-------|----------|-----|--------|
| **Firewall** | Fire | 3.0s | Directional fire barrier |
| **Icewall** | Water | 3.0s | Directional ice barrier |
| **Fog** | Air/Water | 4.0s | Obscuring fog (reveals hidden) |
| **Hellfumes** | Air/Earth | 4.0s | Choking noxious cloud |
| **Flood** | Water | 4.0s | Water room coverage |
| **Quake** | Earth | 3.2s | Drains water via earthquake |
| **Hailstorm** | Air/Water | 3.5s | Enemy-exclusive hailstone barrage |

### Utility Spells

| Spell | Elements | EQ | Effect |
|-------|----------|-----|--------|
| **Light** | Fire | 3.0s | Reveals hidden targets |
| **Scry** | Water | 1.0s | Locates adventurers |
| **Erode** | All four | 2.5s | Strips defenses (shield, chargeshield, insulation, temperance); decreases resonance unless MAINTAIN |
| **Illusion** | Air/Fire | 2.0s | Creates room illusion (optional LETHAL variant) |
| **Simultaneity** | — | 4.0s | Opens all four channels simultaneously |

---

## Artificing Abilities (Complete Reference)

### Staff & Staffcast
- **Staff**: Primary combat foci. 1000 mana to create, 150 mana per staffcast. 4s EQ. Holds up to 4 crystals
- **Staffcast**: Cast the staff's embedded crystal spell at a target. EQ-based (separate from spell balance)

### Crystal Enhancements (for Staff)

Staff holds up to 4 crystals. **Current loadout: Rapidity, Glacial, Horripilation, Immolation, Scintilla** (5 available, staff holds 4 — swap as needed).

| Crystal | Effect | Notes |
|---------|--------|-------|
| **Scintilla** | Fire spell — creates a spark on target that ignites after 4s if target takes OTHER damage | Two-phase: spark → ignition (burning + burns++). Key for calcify pressure |
| **Horripilation** | Frost spell — applies waterbond/blistered (slickness-like) | Key lock piece for salve pressure |
| **Glacial** | Enhanced horripilation — binds target with water bonds (15-45s depending on freeze) | Pairs with horripilation crystal |
| **Immolation** | Applies ablaze 4s after staffcast | Delayed fire pressure |
| **Rapidity** | Doubles staffcast speed, halves damage | Speed vs damage tradeoff |
| **Lightning** | Electricity spell — damage | Base staff damage crystal (not in current loadout) |
| **Shock** | Pairs with lightning — inflicts stupidity | Mental affliction delivery (not in current loadout) |

### Elemental Treaties & Summons
Pacts with Elemental Plane denizens. Maximum 2 active elementals (1 per plane):

| Elemental | Plane | Ability | Effect |
|-----------|-------|---------|--------|
| **Waterweird** | Water | — | Water travel/current immunity |
| **Djinn** | Air | ELEMENTAL LEVITATE | 100 mana, 3.6s EQ |
| **Sandling** | Earth | ELEMENTAL DESCEND | 250 mana, 4s EQ |
| **Efreeti** | Fire | Passive | Periodic enemy ignition |
| **Stoneback** | Earth | ELEMENTAL BULWARK | Protective ability, 3.6s EQ |
| **Breath** | Air | ELEMENTAL BREATHMELD | Tracking, 1s EQ, 2min cooldown |
| **Mistfiend** | Water | ELEMENTAL CONDENSE | Water control, 300 mana, 4.2s EQ |
| **Ashbeast** | Fire | ELEMENTAL SURGE | Destroys water constructs, 3.6s EQ. **Enhances Destroy (bypasses starburst)** |

### Artefact Abilities (Configurable in System)
These require specific purchased artefacts and are gated behind config toggles:

| Ability | Command | Effect | Config Toggle |
|---------|---------|--------|---------------|
| **Arachnideye Trample** | `arachnideye trample <target>` | Knocks prone + disorientation | `magi.offense.config.useArachnideye` |
| **Webbomb** | `webbomb <target>` | Entangles + grounds (prevents flight escape) | `magi.offense.config.useWebbomb` |

Both are **free actions** (don't consume spell balance) and are prepended to the attack queue when enabled.

---

## Crystalism Abilities (Complete Reference)

### Core Mechanics
- **Refine**: Extract crystal shapes from Master Crystal (50 mana, 1s bal)
- **Fold**: Restore Master Crystal facets using pearls
- **Spin**: Prepare crystals for embedding
- **Embed**: Activate vibration in room (300 mana, 3.1s EQ)
- **Dampen**: Destroy your own vibrations (4s bal)
- **Focus**: Consolidate all vibes to current room (100 mana, 4s EQ)
- **Destabilise**: Destroy vibrations with potent environmental effects (400 mana). Each vibe type has unique destabilization effect

### Combat Vibrations

| Vibration | Shape(s) | Effect | Lessons |
|-----------|----------|--------|---------|
| **Dissipate** | Pentagon | Attacks enemy mana pools | 6 |
| **Palpitation** | Cylinder | Heart attack damage | 15 |
| **Tremors** | Disc, Egg | Strips levitation; knocks non-levitating enemies prone | 88 |
| **Oscillate** | Diamond | Periodic amnesia | 555 |
| **Stridulation** | Cylinder, Polyhedron | Destroys enemy equilibrium | 945 |
| **Disorientation** | Spiral | Periodic dizziness | 703 |
| **Forest** | Diamond, Pyramid | Crystal shards causing bleeding | 1152 |
| **Dissonance** | Cylinder, Sphere, Spiral | Damage + periodic defense stripping | 1290 |
| **Plague** | Cube, Pyramid, Spiral | Variety of afflictions | 1394 |
| **Lullaby** | Pyramid | Puts enemies to sleep | 1532 |
| **Retardation** | Disc | Aeon effect to all in room; disables passive vibe effects | 1635 |

### Utility/Defensive Vibrations

| Vibration | Shape(s) | Effect | Lessons |
|-----------|----------|--------|---------|
| **Heat** | Pyramid | Soothing warmth; counters cold effects | 33 |
| **Alarm** | Spiral | Alerts when enemies enter/leave room | 66 |
| **Reverberation** | Disc, Pentagon | Protects vibes from destruction (not Dampen/Retardation) | 133 |
| **Sonicportal** | Sphere, Torus | Opens portal between you and target | 177 |
| **Adduction** | Disc, Polyhedron | Pulls people from adjacent rooms | 222 |
| **Harmony** | Egg, Sphere | Healing vibration (HEALING or RESTORATION mode) | 333 |
| **Creeps** | Torus | Causes shyness/fear in enemies | 377 |
| **Silence** | Egg | Cancels most sound in room | 422 |
| **Revelation** | Cube, Diamond | Reveals concealed adventurers | 466 |
| **Grounding** | Sphere | Roots you; prevents movement | 511 |
| **Energise** | Polyhedron | Drains enemy HP; stored for later (ABSORB ENERGY) | 842 |
| **Gravity** | Egg, Torus | Pulls sky/tree entities down | 1083 |

### Cataclysm (Transcendent)
Requires TWO transcendent Magi spinning all 11 crystal shapes. Enables Elementalism casting through vibration at 3-room radius. Second Magi must IMBUE to complete.

### Default PvP Vibe Set
Auto-managed via `magi.offense.setupVibes()` or `mm vibes`:
```
dissonance, energise, creeps, palpitation, tremors, disorientation, plague, lullaby
```

---

## Kill Routes

### Primary Kill: Fire/Burn Damage
```yaml
type: damage
summary: Stack burns → conflagrate → stormhammer/destroy finisher
mode: "fire" (mm fire)

pipeline:
  1: "Magma → scalded (20s duration, can't re-magma while active)"
  2: "Dehydrate/Fulminate/Firelash → increment burn counter (0-5)"
  3: "At burns >= 2 + fire >= 2 → CONFLAGRATE"
  4: "Conflagrated + HP < 35% → DESTROY (instant kill)"
  5: "HP <= 25% → STORMHAMMER (up to 3 targets)"

key_spells:
  magma: "Applies scalded (20s), builds earth+fire resonance"
  dehydrate: "Burns +1, builds fire+water. If nausea+no weariness → also freezes"
  fulminate: "Burns +1, builds air+fire. Smart chain: fulminated→epilepsy→paralysis"
  firelash: "Burns +1, builds fire. Applies burning"
  conflagrate: "Requires burns >= 2, fire >= 2. Sets conflagrated flag"
  destroy: "Instant kill. Requires conflagrated + HP < 35% (configurable)"
  stormhammer: "High damage, up to 3 same-city enemy targets"
```

### Alternative Kill: Water/Glaciate
```yaml
type: damage
summary: Freeze → hypothermia → glaciate instant kill
mode: "water" (mm water)

pipeline:
  1: "Build water + air resonance"
  2: "Freeze target (requires shivering + broken limb)"
  3: "Hypothermia (requires frozen + water >= 2 + air >= 2)"
  4: "GLACIATE (requires hypothermia + water >= 2 + air >= 2) — heavy damage"

key_spells:
  freeze: "Requires shivering + 1 broken limb. Applies frozen"
  hypothermia: "Requires frozen + dual resonance. Removes freeze cure ability"
  glaciate: "Requires hypothermia + dual resonance. Heavy damage finisher"
```

### Alternative Kill: Affliction Lock
```yaml
type: affliction
summary: Use resonance passive effects + mudslide + vibrations for truelock
mode: "lock" (mm lock)

pipeline:
  1: "Build kelp stack via resonance passives (asthma, frostbite, sensitivity)"
  2: "Mudslide at water == 2 + asthma → slickness + prone"
  3: "Horripilation via staffcast → waterbond/blistered (slickness path)"
  4: "Earth resonance → paralysis (passive at level 2)"
  5: "Embedded vibrations for impatience/stupidity"
  6: "Scintilla for calcify pressure (blocks restoration)"
  7: "Truelock → damage to death"

required_afflictions:
  - asthma: "blocks smoking (air resonance passive at level 1)"
  - anorexia: "blocks eating (water resonance passive at level 3)"
  - slickness: "blocks applying (horripilation/mudslide)"
  - paralysis: "blocks tree (earth resonance passive at level 2)"
  - impatience: "blocks focus (vibrations)"
  - haemophilia: "class lock aff (prevents clotting)"
```

### Salve Pressure
```yaml
type: hybrid
summary: Scalded + earth resonance + calcify for salve-curable affliction overload
mode: "salve" (mm salve)

strategy:
  - "Scalded strips caloric (fire passive)"
  - "Earth resonance breaks limbs (salve cures)"
  - "Calcified torso blocks restoration salve"
  - "Cracked ribs from earth emanation"
  - "Scintilla spark → ignition for more burns (salve pressure)"
```

### Group PvP
```yaml
type: damage
summary: Pure damage output, stormhammer multi-target
mode: "group" (mm group)

strategy:
  - "Stormhammer priority at 50% HP (up to 3 same-city enemies)"
  - "Emanation fire for AoE burning pressure"
  - "Shalestorm for room-wide earth damage"
  - "Scintilla auto-fires when shalestorm active"
```

---

## Meteorite Shield Breaking

When target has shield up, select meteorite variant based on resonance state to build missing resonance while stripping:
```lua
-- Priority: build missing resonance while stripping shield
if fireWillBurn then "cast meteorite flaming"     -- fire not at 3, builds fire + burning
elseif earth < 3 then "cast meteorite pure"        -- builds earth
elseif water < 3 then "cast meteorite frozen"       -- builds water + frozen
else "cast erode at target shield"                   -- all capped, just strip
```

---

## Shalestorm + Scintilla Automation

**Key insight from Tabethys (xMagi author)**: Scintilla creates a spark that only ignites when the target takes OTHER damage. Shalestorm provides constant automatic damage → guarantees spark ignition. This makes scintilla essentially "free" calcify pressure whenever shalestorm is running.

**Implementation**: When shalestorm is active, the system auto-casts `staffcast scintilla` in ALL modes (not just lock/salve). This fires at priority 5 in selectSpell(), after shield strip but before emanations.

**Conditions**:
- `st.shalestorm` — shalestorm must be running (guarantees ignition)
- `not st.calcifiedTorso` — don't waste if already calcified
- `not st.scintillaSpark` — don't re-cast if spark is already pending (4s timer)
- `r.earth >= 2` — need moderate+ earth resonance

**Scintilla mechanics**:
- Phase 1: `staffcast scintilla at <target>` → applies spark (4s timer)
- Phase 2: If target takes ANY damage during spark window → ignition → burning + burns++
- Shalestorm's periodic earth damage auto-triggers phase 2

Existing lock mode (earth==3) and salve mode (earth>=2) scintilla branches remain unchanged — they fire even WITHOUT shalestorm.

---

## Configurable Utility Abilities (Artefact-Dependent)

Free-action abilities that can be prepended to the attack queue. Require specific purchased artefacts — **default OFF**.

### Arachnideye Trample
- **Command**: `arachnideye trample <target>`
- **Effect**: Knocks target prone + disorientation
- **Gate**: Only fires when target is NOT already prone
- **Toggle**: `mm arach` or `mm arachnideye`
- **Config**: `magi.offense.config.useArachnideye`

### Webbomb
- **Command**: `webbomb <target>`
- **Effect**: Entangles + grounds target (prevents flight escape)
- **Gate**: Only fires when target is NOT already entangled
- **Toggle**: `mm web` or `mm webbomb`
- **Config**: `magi.offense.config.useWebbomb`

### Implementation in sendAttack()
```lua
-- Utility prefix is prepended BEFORE stand::wield::spell::assess
-- Example output: "queue addclearfull freestand arachnideye trample Targname::stand::wield staff shield::spell::assess Targname"
if magi.offense.config.useArachnideye and not haveAff("prone") then
  prefix = "arachnideye trample " .. target .. sep
elseif magi.offense.config.useWebbomb and not haveAff("entangled") then
  prefix = "webbomb " .. target .. sep
end
```

---

## Offensive System Architecture

### Namespace
```lua
magi.offense = {
  state = {         -- runtime combat state
    mode = "fire",
    burns = 0,
    conflagrated = false,
    scalded = false,
    scaldedTimer = nil,
    calcifiedTorso = false,
    calcifiedSkull = false,
    shalestorm = false,
    scintillaSpark = false,
    scintillaTimer = nil,
    firestorm = false,
    hypothermia = false,
    frozen = false,
    shivering = false,
    partyrelay = true,
    debug = false,
  },
  config = {        -- persistent config
    destroyThreshold = 35,
    stormhammerThreshold = 25,
    scaldedDuration = 20,
    useArachnideye = false,
    useWebbomb = false,
  },
}
```

### Decision Tree Priority (selectSpell)
```
1.  DESTROY — conflagrated + HP < 35%
2.  SHIELD STRIP — meteorite variant selection
3.  GLACIATE — hypothermia + water>=2 + air>=2
4.  STORMHAMMER — HP <= 25%
5.  SHALESTORM+SCINTILLA — shalestorm active + earth>=2 + !calcifiedTorso + !scintillaSpark
6.  EMANATION EARTH — earth==3 + (frostbite OR burning>1 OR shivering OR no caloric)
7.  HYPOTHERMIA — frozen + dual resonance
8.  MUDSLIDE — asthma>=50% + water==2
    MODE-SPECIFIC: lock / salve / group sub-trees
9.  MAGMA — not scalded
10. FREEZE — shivering + broken limb
11. CALCIFIED PATH — calcifiedTorso + conditions
12. BURNING PATH — burns tracking → conflagrate/dehydrate/fulminate/emanation
13. SHALESTORM/FALLBACK — earth>=2 or generic resonance building
```

### Mode-Specific Sub-Trees

**Lock Mode** (`selectLockSpell()`):
1. Horripilation for waterbond/blistered (if missing + no paralysis/anorexia)
2. Magma for scalded (if not scalded)
3. Scintilla at earth==3 + !calcifiedTorso
4. Emanation earth at earth==3 + calcifiedTorso
5. Build earth (bombard/mudslide) if earth < 2
6. Build air (fulminate) if air < 3
7. Emanation air at cap
8. Fallback: dehydrate

**Salve Mode** (`selectSalveSpell()`):
1. Emanation earth at cap
2. Magma for scalded (if not scalded)
3. Scintilla at earth>=2 + !calcifiedTorso
4. Build earth (bombard) if earth < 3
5. Emanation fire at cap
6. Fallback: dehydrate

**Group Mode** (`selectGroupSpell()`):
1. Stormhammer at HP <= 50% (higher threshold for group)
2. Emanation fire at cap
3. Emanation earth at cap
4. Shalestorm (if not active + earth >= 2)
5. Magma (if not scalded)
6. Fallback: dehydrate

**Burning Sub-Tree** (`selectBurningSpell()`):
1. Conflagrate (burns>=2, fire>=2, not conflagrated)
2. Dehydrate for freeze+burn combo (conditions met)
3. Fulminate (air==0, water==2, fire will burn)
4. Dehydrate if weariness present
5. Emanation fire at cap
6. Earth building (magma/bombard at earth==1)
7. Emanation water at cap
8. Fallback: dehydrate

### Key Files
| File | Purpose |
|------|---------|
| `scripts/.../mage/001_Resonance.lua` | Creates `magi` table, `get_resonance()` reads GMCP charstats |
| `scripts/.../mage/004_Magi_Offense.lua` | Unified offense system (dispatch, decision tree, all modes) |
| `scripts/.../mage/005_Stormhammer_Targeting.lua` | Smart multi-target stormhammer with city filtering |
| `triggers/.../general/015_Dehydrate.lua` | Dehydrate success — weariness/nausea/frozen chain + burns |
| `triggers/.../general/021_Spell_Outcomes.lua` | Spell success detection (magma, dehydrate, fulminate, bombard, firelash, mudslide) |
| `triggers/.../general/021_Freeze.lua` | Freeze spell — frozen/shivering/caloric chain |
| `triggers/.../general/023_Shalestorm.lua` | Shalestorm state tracking with anti-illusion guard |
| `triggers/.../general/024_Meteorite.lua` | Meteorite shield-break variant detection |
| `triggers/.../general/025_Burns_Tracking.lua` | Burns counter from efreeti/conflagrate/firestorm |
| `triggers/.../general/026_Calcify.lua` | Calcified torso/skull detection and fade |
| `triggers/.../enamation/001-004` | Emanation fire/water/air/earth triggers |
| `triggers/.../magi_offense_tracking/001-015` | Resonance affs, transfix, scintilla, staffcast, deepfreeze, erode |
| `aliases/.../magi_things/006_Magi_Mode.lua` | `mm` mode-switch + utility toggle alias |

### Trigger Architecture
- **`general/`**: 015_Dehydrate, 021_Spell_Outcomes (unified), 021_Freeze, 023_Shalestorm, 024_Meteorite, 025_Burns_Tracking, 026_Calcify
- **`magi_offense_tracking/`** (001-015): Resonance afflictions, emanations, transfix, scintilla, staffcast, deepfreeze, erode
- **`enamation/`** (001-004): Emanation triggers (air, water, fire, earth)
- **`vibes/`**: Vibration management triggers

### Key Trigger Patterns
- **Burns tracking**: Counter 0-5, incremented by fire effects, decremented by "fires diminish". `magi.offense.state.burns` + backward-compat `tburns` global
- **Fulminate smart chain**: fulminated → epilepsy → paralysis (state-based via `haveAff()`)
- **Scintilla**: Two-phase — spark (4s timer) then ignition (burning + burns++)
- **Scalded**: 20s timer via `tempTimer` in 021_Spell_Outcomes
- **Calcified torso**: Trigger-based clear (026_Calcify fade pattern), not timer-based
- **Erode**: Multiline trigger (015_Erode, `conditonLineDelta: 3`) parses defense name from followup line
- **Freeze**: 021_Freeze.lua — tracks frozen/shivering/caloric chain
- **Emanation triggers**: Use `an? \w+ staff` pattern (not hardcoded staff names) + target validation

### Commands
| Alias | Action |
|-------|--------|
| `zz` | `magi.offense.dispatch()` (current mode) |
| `xx` | `magi.offense.setMode("fire"); magi.offense.dispatch()` |
| `vv` | `magi.offense.setMode("water"); magi.offense.dispatch()` |
| `cc` | `magi.offense.setMode("lock"); magi.offense.dispatch()` |
| `sr` | `magi.offense.setMode("group"); magi.offense.dispatch()` |
| `srr` | Stormhammer direct fire |
| `mm` | Show full status (mode, resonance, burns, scalded, calcify, shalestorm, hypothermia, frozen, arach, web) |
| `mm fire/water/lock/salve/group` | Set mode (no dispatch) |
| `mm debug` | Toggle debug echo |
| `mm vibes` | Auto-embed missing PvP vibrations |
| `mm reset` | Reset all offense state |
| `mm arach` / `mm arachnideye` | Toggle arachnideye trample prefix |
| `mm web` / `mm webbomb` | Toggle webbomb prefix |

### Dispatch Guard Chain
```
1. Class check (gmcp.Char.Status.class == "Magi")
2. Balance + equilibrium gate
3. Aeon check
4. Target validation
5. Update resonance from GMCP
6. Sync firestorm state from legacy global
7. selectSpell() → sendAttack()
```

### sendAttack() Flow
```lua
-- Output format:
-- queue addclearfull freestand [utility_prefix::]stand::wield staff shield::spell::assess target
```

### Backward Compatibility
Old function names still work via wrappers:
- `MagiMain()` → fire mode dispatch
- `MagiLock()` → lock mode dispatch
- `MagiWaterFocus()` → water mode dispatch
- `MagiFireNew()` → fire mode dispatch
- `MagiSalveFocus()` → salve mode dispatch

Legacy globals: `tburns`, `tfirelash`, `timmolation`

### V3 Affliction Tracking Integration
| Helper | Purpose |
|--------|---------|
| `magi.offense.hasAff(aff)` | Routes to `haveAff()` → V3 at 30% threshold |
| `magi.offense.getAffProb(aff)` | Routes to `getAffProbabilityV3()` (0.0-1.0) |
| `magi.offense.hasShield()` | V1 fallback for rebounding+shield (GMCP timing gap) |
| `magi.offense.targetShielded()` | V1 fallback for shield only |

### Target Change Reset
Registered via `registerAnonymousEventHandler("ataxia target changed", ...)` with handler ID cleanup pattern.

---

## Bashing (PvE)
```yaml
attack_command: "STAFFCAST FIRE <target>"
attack_skill: Elementalism
```

---

## Fighting Against This Class
```yaml
priority_cures:
  - scalded/ablaze: "APPLY CALORIC - prevents burn stacking"
  - frozen: "APPLY CALORIC - prevents hypothermia/glaciate"
  - frostbite: "EAT KELP - prevents freeze setup"
  - haemophilia: "EAT GINSENG - restore clotting"
  - sensitivity: "EAT KELP - reduce their damage"
  - calcified_torso: "Blocks restoration (very dangerous)"
  - burning: "Keep caloric up, cure burns before conflagrate"
  - shivering: "Cure before they can freeze you"

dangerous_abilities:
  - destroy: "Instant kill when conflagrated + low HP (< 35-40%)"
  - glaciate: "Heavy damage when hypothermia + dual resonance"
  - stormhammer: "High damage to up to 3 targets"
  - conflagrate: "Massive burn damage setup (burns >= 2)"
  - emanation_earth: "Calcify skull/torso — blocks head cures or restoration"
  - shalestorm: "Persistent earth damage with limb breaks"
  - convergence: "Bypasses shields at dissonance stage 4"

avoid:
  - "Letting burns stack to 2+ (conflagrate threshold)"
  - "Being frozen with their water+air resonance high (glaciate path)"
  - "Standing in rooms with embedded vibrations"
  - "Ignoring scalded (enables full burn pipeline)"
  - "Low health when conflagrated (destroy instant kill)"
  - "Letting shalestorm run unchecked (auto-triggers scintilla sparks for calcify pressure)"

recommended_strategy: |
  Cure caloric (scalded/ablaze/frozen) immediately — this disrupts both kill routes.
  Eat kelp for asthma/frostbite to prevent lock and freeze setups.
  Leave rooms with embedded crystals when possible.
  Pressure Magi before they build resonance — they need 2-3 attacks to set up.
  Watch for meteorite shield-strip variants (they adapt to resonance state).
  Haemophilia is their class lock aff — cure with ginseng.
  Strip shalestorm if possible — it provides free limb breaks and enables scintilla automation.
```

---

## Reference Files
- `C:\Users\mikew\Downloads\xMagi.lua` — Aegoth/Tabethys decision tree (fully implemented)
- `C:\Users\mikew\Downloads\magi2.mpackage` — State-tracking triggers (fully implemented)
- `C:\Users\mikew\Downloads\magiaddtriggs.mpackage` — Display-only duplicates (no tracking value)
- `C:\Users\mikew\Downloads\ExpertDiagnoser.mpackage` — Generic target cure tracking system (equivalent to V3)
