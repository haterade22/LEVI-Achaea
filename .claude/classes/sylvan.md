# Sylvan

## Metadata
- **Type**: Base Class
- **Combat Style**: Affliction | Damage
- **Difficulty**: Medium
- **Lock Affliction**: Haemophilia (prevents clotting, key for bleeding damage)

## Skills
```
Propagation: Plant growth and manipulation
Groves: Forest grove creation and manipulation
Weatherweaving: Weather and elemental manipulation
```

## Kill Routes

### Primary Kill: Thornrend Bleed
```yaml
type: damage
summary: Stack bleeding through thorns, kill through bleedout

prerequisites:
  - Must apply haemophilia to prevent clotting
  - Build bleeding through thorn attacks

steps:
  1: "Apply haemophilia (prevents clotting)"
  2: "Use Propagation thorn attacks"
  3: "Stack bleeding rapidly"
  4: "THORNREND for additional bleeding"
  5: "Target bleeds out and dies"

notes: "Haemophilia is critical - prevents them from clotting bleeding"
```

### Alternative Kill: Grove/Weather Lock
```yaml
type: affliction
summary: Use grove and weather for affliction stacking

steps:
  1: "Create and empower grove"
  2: "Use grove abilities for entanglement"
  3: "Apply weather effects for afflictions"
  4: "Stack toward true lock"
  5: "Apply haemophilia for lock"
  6: "Damage to death through lock"

required_afflictions:
  - asthma: "blocks smoking"
  - anorexia: "blocks eating"
  - slickness: "blocks applying"
  - paralysis: "blocks tree"
  - impatience: "blocks focus"
  - haemophilia: "prevents clotting (class-specific)"
```

### Alternative Kill: Weather Damage
```yaml
type: damage
summary: Use weather manipulation for sustained damage

steps:
  1: "Call weather effects (lightning, hail, etc.)"
  2: "Apply sensitivity"
  3: "Stack weather damage"
  4: "Kill through accumulated elemental damage"
```

## Offensive Abilities
```yaml
# Propagation
thornrend:
  skill: Propagation
  balance: bal
  effect: "Rend target with thorns, causes bleeding"
  syntax: "THORNREND <target>"
  notes: "Primary bleeding attack"

entangle:
  skill: Propagation
  balance: eq
  effect: "Entangle target in vines"
  syntax: "ENTANGLE <target>"

growth:
  skill: Propagation
  balance: eq
  effect: "Accelerate plant growth"
  syntax: "GROWTH"

thistles:
  skill: Propagation
  balance: eq
  effect: "Create thistles for damage"
  syntax: "THISTLES <target>"

# Groves
grove_create:
  skill: Groves
  balance: eq
  effect: "Create a grove"
  syntax: "GROVE CREATE"

vinetangle:
  skill: Groves
  balance: eq
  effect: "Tangle target in grove vines"
  syntax: "VINETANGLE <target>"
  notes: "Grove must be active"

# Weatherweaving
call_weather:
  skill: Weatherweaving
  balance: eq
  effect: "Call weather effect"
  syntax: "CALL <weather>"
  weather:
    - lightning: "Lightning damage"
    - rain: "Water effects"
    - hail: "Ice damage"
    - wind: "Air effects"

lightning:
  skill: Weatherweaving
  balance: eq
  effect: "Strike with lightning"
  damage_type: electric
  syntax: "CALL LIGHTNING <target>"

sunbeam:
  skill: Weatherweaving
  balance: eq
  effect: "Focus sunlight for damage"
  syntax: "SUNBEAM <target>"
```

## Defensive Abilities
```yaml
barkskin:
  skill: Propagation
  effect: "Bark armor for damage reduction"
  syntax: "BARKSKIN"

grove_protection:
  skill: Groves
  effect: "Protection while in grove"
  notes: "Grove provides various benefits"

weather_defense:
  skill: Weatherweaving
  effect: "Weather-based defense"
  notes: "Can use weather for protection"
```

## Passive Cures
```yaml
# Sylvan relies on standard curing
# Haemophilia blocks their ability to clot
```

## Limb Strategy
```yaml
enabled: false
notes: "Sylvan is bleed/affliction-based, not limb-based"
```

## Bashing (PvE)
```yaml
attack_command: "THORNREND <target>"
attack_skill: Propagation
battlerage_abilities:
  - thornrend: "Basic damage + bleed"
  - lightning: "Weather damage"
```

## Fighting Against This Class
```yaml
priority_cures:
  - haemophilia: "EAT GINSENG - restore clotting ability"
  - entanglement: "WRITHE out of vines"
  - bleeding: "CLOT to reduce bleeding"
  - asthma: "Restore smoking ability"

dangerous_abilities:
  - thornrend: "Rapid bleeding application"
  - haemophilia: "Prevents clotting"
  - lightning: "High burst damage"
  - entangle: "Locks you in place"

avoid:
  - "Standing in their grove"
  - "Letting haemophilia stick"
  - "Ignoring bleeding (will bleed out)"
  - "Being entangled"

recommended_strategy: |
  Cure haemophilia immediately - it's their key affliction.
  Clot bleeding regularly when able.
  Leave their grove if possible.
  Writhe out of entanglement quickly.
  Apply haemophilia back to disrupt their curing.
  Pressure them before bleed can stack.
```

## Implementation Notes
```
Triggers to watch for:
- "rends you with thorns" - thornrend
- "You are entangled" - entanglement
- "blood flows" or bleeding messages - bleeding stacking
- "calls lightning" - weather attack
- Grove activation messages

GMCP considerations:
- Track gmcp.Char.Afflictions for afflictions
- Bleeding amount tracking important
- Haemophilia in afflictions

Edge cases:
- Haemophilia blocks clotting (their key affliction)
- Grove provides bonuses in that room
- Weather effects can vary by outdoor/indoor
- Thornrend causes rapid bleeding
- Entanglement requires writhe
- Bleeding can stack very high with haemophilia
```
