# Magi

## Metadata
- **Type**: Base Class
- **Combat Style**: Affliction | Damage (Hybrid)
- **Difficulty**: Hard
- **Lock Affliction**: Haemophilia (prevents clotting, disrupts cure system)
- **Offense System**: `magi.offense` namespace (`004_Magi_Offense.lua`)
- **Dispatch**: `zz` → `magi.offense.dispatch()`, mode switch via `mm <mode>`

## Skills
```
Crystalism: Vibrational crystal magic (room control, afflictions via embedded crystals)
Elementalism: Elemental magic (fire, water, air, earth resonance system)
Artificing: Item creation and enhancement (staffs, crystals)
```

## Resonance System

The core mechanic. Every elementalism spell builds resonance in its element (0→3). At level 3, EMANATION consumes all 3 stacks for a powerful effect. Resonance also causes passive effects at each level.

### Resonance Levels & Passive Effects
```yaml
air:
  1: "asthma"
  2: "sensitivity"
  3: "healthleech"
  emanation: "paralysis + dizziness"

earth:
  1: "random limb break"
  2: "stun + paralysis"
  3: "cracked ribs"
  emanation: "calcified skull (blocks head cures)"

fire:
  1: "strip temperance → scalded/ablaze"
  2: "blistered"
  3: "burning +2"
  emanation: "burning +2 (cap 5)"

water:
  1: "frostbite"
  2: "stuttering"
  3: "anorexia"
  emanation: "hypothermia setup"
```

### Resonance Budgeting
- **Never waste capped resonance** — if fire==3, emanate fire before casting more fire spells
- Emanation consumes all 3 stacks and delivers the emanation effect
- Building past 3 wastes the passive effects at each level

## Kill Routes

### Primary Kill: Fire/Burn Damage
```yaml
type: damage
summary: Stack burns → conflagrate → stormhammer/destroy finisher
mode: "fire" (mm fire)

pipeline:
  1: "Magma → scalded (20s duration, can't re-magma while active)"
  2: "Dehydrate/Fulminate/Firelash → increment burn counter"
  3: "At burns >= 2 + fire >= 2 + air >= 2 → CONFLAGRATE"
  4: "Conflagrated + HP < 35% → DESTROY (instant kill)"
  5: "HP <= 25% → STORMHAMMER (up to 3 targets)"

key_spells:
  magma: "Applies scalded (20s), fire resonance"
  dehydrate: "Burns +1, water resonance. If nausea+no weariness → also freezes"
  fulminate: "Burns +1, fire+air resonance"
  firelash: "Burns +1, fire resonance"
  conflagrate: "Requires burns >= 2, fire >= 2, air >= 2. Sets conflagrated flag"
  destroy: "Instant kill. Requires conflagrated + low HP"
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
  4: "GLACIATE (requires hypothermia + water >= 2 + air >= 2)"

key_spells:
  freeze: "Requires shivering + 1 broken limb. Applies frozen"
  hypothermia: "Requires frozen + dual resonance (water >= 2, air >= 2)"
  glaciate: "Instant kill. Requires hypothermia + dual resonance"
```

### Alternative Kill: Affliction Lock
```yaml
type: affliction
summary: Use resonance passive effects + mudslide + vibrations for truelock
mode: "lock" (mm lock)

pipeline:
  1: "Build kelp stack via resonance passives (asthma, frostbite, sensitivity)"
  2: "Mudslide at water == 2 + asthma for anorexia"
  3: "Horripilation via staffcast for slickness"
  4: "Earth resonance for paralysis"
  5: "Embedded vibrations for impatience/stupidity"
  6: "Truelock → damage to death"

required_afflictions:
  - asthma: "blocks smoking (air resonance passive)"
  - anorexia: "blocks eating (mudslide)"
  - slickness: "blocks applying (horripilation)"
  - paralysis: "blocks tree (earth resonance passive)"
  - impatience: "blocks focus (vibrations)"
  - haemophilia: "class lock aff (prevents clotting)"
```

### Salve Pressure
```yaml
type: hybrid
summary: Scalded + earth resonance for salve-curable afflictions
mode: "salve" (mm salve)

strategy:
  - "Scalded strips caloric (fire passive)"
  - "Earth resonance breaks limbs (salve cures)"
  - "Calcified torso blocks restoration"
  - "Cracked ribs from earth emanation"
```

### Group PvP
```yaml
type: damage
summary: Pure damage output, stormhammer multi-target
mode: "group" (mm group)

strategy:
  - "Stormhammer priority (up to 3 same-city enemies)"
  - "Emanation fire for AoE burning pressure"
  - "Firestorm for room-wide fire damage"
```

## Meteorite Shield Breaking

When target has shield up, select meteorite variant based on resonance state:
```lua
-- Priority: build missing resonance while stripping shield
if fireWillBurn then "meteorite flaming 4"      -- fire not at 3, builds fire + strips shield + burning
elseif earth < 3 then "meteorite pure 4"         -- builds earth
elseif water < 3 then "meteorite frozen 4"        -- builds water + frozen
else "erode maintain"                              -- all capped, just strip
```

## Vibration System (Crystalism)

Room-embedded crystals that cause persistent effects:
```yaml
vibes:
  dissonance: "Damage on entry"
  energise: "Increased damage"
  creeps: "Fear/affliction"
  palpitation: "Heart effects"
  tremors: "Prone/stun"
  disorientation: "Confusion"
  plague: "Disease spread"
  lullaby: "Sleep"
```

Auto-managed via `magi.offense.setupVibes()` or `mm vibes`.

## Offensive System Architecture

### Namespace
```lua
magi.offense = {
  state = {        -- runtime combat state
    mode = "fire",
    burns = 0,
    conflagrated = false,
    scalded = false,
    scaldedTimer = nil,
    calcifiedTorso = false,
    calcifiedSkull = false,
    shalestorm = false,
    firestorm = false,
    hypothermia = false,
  },
  config = {       -- persistent config
    debugEcho = false,
  },
}
```

### Decision Tree Priority (selectSpell)
```
1.  DESTROY — conflagrated + HP < 35%
2.  SHIELD STRIP — meteorite variant selection
3.  GLACIATE — hypothermia + water>=2 + air>=2
4.  STORMHAMMER — HP <= 25%
5.  EMANATION EARTH — earth==3 + (frostbite OR burning>1 OR shivering OR no caloric)
6.  HYPOTHERMIA — frozen + dual resonance
7.  MUDSLIDE — asthma>=50% + water==2
8.  MODE-SPECIFIC: LOCK (horripilation, lock tracking)
9.  MAGMA — not scalded
10. FREEZE — shivering + broken limb
11. CALCIFIED PATH — calcifiedTorso + conditions
12. BURNING PATH — burns tracking → conflagrate/dehydrate/fulminate/emanation
13. SHALESTORM/FALLBACK — earth>=2 or generic resonance building
```

### Key Files
| File | Purpose |
|------|---------|
| `scripts/.../mage/001_Resonance.lua` | Creates `magi` table, `get_resonance()` reads GMCP charstats |
| `scripts/.../mage/004_Magi_Offense.lua` | Unified offense system (dispatch, decision tree, all modes) |
| `scripts/.../mage/005_Stormhammer_Targeting.lua` | Smart multi-target stormhammer with city filtering |
| `triggers/.../general/021_Spell_Outcomes.lua` | Spell success detection (magma, dehydrate, fulminate, etc.) |
| `triggers/.../general/022_Resonance_Afflictions.lua` | Resonance passive effect tracking (12 patterns) |
| `triggers/.../general/023_Shalestorm.lua` | Shalestorm state tracking with anti-illusion guard |
| `triggers/.../general/024_Meteorite.lua` | Meteorite shield-break variant detection |
| `triggers/.../general/025_Burns_Tracking.lua` | Burns counter from efreeti/conflagrate/firestorm |
| `triggers/.../general/026_Calcify.lua` | Calcified torso/skull detection |
| `triggers/.../enamation/001-004` | Emanation fire/water/air/earth triggers |
| `aliases/.../magi_things/006_Magi_Mode.lua` | `mm` mode-switch alias |

### Commands
| Alias | Action |
|-------|--------|
| `zz` | `magi.offense.dispatch()` (current mode) |
| `sr` | `magi.offense.setMode("group"); magi.offense.dispatch()` |
| `mm` | Show status |
| `mm fire/water/lock/salve/group` | Set mode |
| `mm debug` | Toggle debug echo |
| `mm vibes` | Auto-embed missing vibrations |
| `mm reset` | Reset all offense state |

### Backward Compatibility
Old function names still work via wrappers:
- `MagiMain()` → fire mode dispatch
- `MagiLock()` → lock mode dispatch
- `MagiWaterFocus()` → water mode dispatch
- `MagiFireNew()` → fire mode dispatch
- `MagiSalveFocus()` → salve mode dispatch

## Bashing (PvE)
```yaml
attack_command: "STAFFCAST FIRE <target>"
attack_skill: Elementalism
```

## Fighting Against This Class
```yaml
priority_cures:
  - scalded/ablaze: "APPLY CALORIC - prevents burn stacking"
  - frozen: "APPLY CALORIC - prevents hypothermia/glaciate"
  - frostbite: "EAT KELP - prevents freeze setup"
  - haemophilia: "EAT GINSENG - restore clotting"
  - sensitivity: "EAT KELP - reduce their damage"
  - calcified_torso: "Blocks restoration (very dangerous)"

dangerous_abilities:
  - destroy: "Instant kill when conflagrated + low HP"
  - glaciate: "Instant kill when hypothermia + dual resonance"
  - stormhammer: "High damage to up to 3 targets"
  - conflagrate: "Massive burn damage setup"
  - emanation_earth: "Calcify skull/torso"

avoid:
  - "Letting burns stack to 2+ (conflagrate threshold)"
  - "Being frozen with their water+air resonance high (glaciate path)"
  - "Standing in rooms with embedded vibrations"
  - "Ignoring scalded (enables full burn pipeline)"
  - "Low health when conflagrated (destroy instant kill)"

recommended_strategy: |
  Cure caloric (scalded/ablaze/frozen) immediately — this disrupts both kill routes.
  Eat kelp for asthma/frostbite to prevent lock and freeze setups.
  Leave rooms with embedded crystals when possible.
  Pressure Magi before they build resonance — they need 2-3 attacks to set up.
  Watch for meteorite shield-strip variants (they adapt to resonance state).
  Haemophilia is their class lock aff — cure with ginseng.
```
