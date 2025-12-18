# Dragon

## Metadata
- **Type**: End-Game Class
- **Combat Style**: Damage | Affliction
- **Difficulty**: Hard
- **Lock Affliction**: Varies by combat approach

## Skills
```
Dragoncraft: Dragon-specific abilities and powers
Draconic Skills: Varies by dragon color
```

## Dragon Colors
```yaml
red:
  description: "Fire-focused dragon"
  breath_weapon: "Fire breath"
  battlerage: "Fire-based abilities"
  strength: "High fire damage, ablaze application"

black:
  description: "Acid/Poison-focused dragon"
  breath_weapon: "Acid breath"
  battlerage: "Acid-based abilities"
  strength: "Damage over time, corrosion"

silver:
  description: "Ice-focused dragon"
  breath_weapon: "Ice breath"
  battlerage: "Ice-based abilities"
  strength: "Freezing, control"

gold:
  description: "Lightning-focused dragon"
  breath_weapon: "Lightning breath"
  battlerage: "Lightning-based abilities"
  strength: "High burst damage"

blue:
  description: "Water-focused dragon"
  breath_weapon: "Water breath"
  battlerage: "Water-based abilities"
  strength: "Drowning, water control"

green:
  description: "Poison/Nature-focused dragon"
  breath_weapon: "Poison breath"
  battlerage: "Poison-based abilities"
  strength: "Affliction stacking, venoms"
```

## Kill Routes

### Primary Kill: Breath Weapon Execute
```yaml
type: execute
summary: Build breath charge, then use devastating breath attack

prerequisites:
  - Must build breath charge
  - Target should be weakened

steps:
  1: "Use dragon attacks to build breath charge"
  2: "Apply afflictions for pressure"
  3: "When breath fully charged, BREATHE <element> AT <target>"
  4: "Massive elemental damage"

notes: "Breath weapon varies by dragon color"
```

### Alternative Kill: Damage Pressure
```yaml
type: damage
summary: Use draconic attacks for sustained damage

steps:
  1: "Apply sensitivity"
  2: "Use claw, tail, and bite attacks"
  3: "Mix in breath attacks when charged"
  4: "Kill through accumulated damage"

notes: "Dragons have high base damage"
```

### Alternative Kill: Affliction Route
```yaml
type: affliction
summary: Stack afflictions toward lock (especially green dragon)

steps:
  1: "Apply afflictions through attacks"
  2: "Green dragon excels at venom-like afflictions"
  3: "Stack toward true lock"
  4: "Damage to death through lock"

required_afflictions:
  - asthma: "blocks smoking"
  - anorexia: "blocks eating"
  - slickness: "blocks applying"
  - paralysis: "blocks tree"
  - impatience: "blocks focus"
```

## Offensive Abilities
```yaml
# Dragoncraft
bite:
  skill: Dragoncraft
  balance: bal
  effect: "Bite attack"
  damage_type: physical
  syntax: "BITE <target>"

claw:
  skill: Dragoncraft
  balance: bal
  effect: "Claw attack"
  damage_type: physical
  syntax: "CLAW <target>"

tail:
  skill: Dragoncraft
  balance: bal
  effect: "Tail swipe, can prone"
  syntax: "TAIL <target>"

breathe:
  skill: Dragoncraft
  balance: eq
  effect: "Breath weapon attack (element varies by color)"
  syntax: "BREATHE <element> AT <target>"
  elements:
    - fire: "Red dragon - fire damage + ablaze"
    - acid: "Black dragon - acid damage + corrosion"
    - ice: "Silver dragon - ice damage + freezing"
    - lightning: "Gold dragon - electric damage"
    - water: "Blue dragon - water damage + drowning"
    - poison: "Green dragon - poison + afflictions"

roar:
  skill: Dragoncraft
  balance: eq
  effect: "Terrifying roar"
  syntax: "ROAR"
  notes: "Fear effect"

fly:
  skill: Dragoncraft
  balance: eq
  effect: "Take flight"
  syntax: "FLY"
  notes: "Aerial mobility"
```

## Defensive Abilities
```yaml
scales:
  skill: Dragoncraft
  effect: "Natural armor from dragon scales"
  notes: "Passive damage reduction"

flight:
  skill: Dragoncraft
  effect: "Aerial evasion"
  syntax: "FLY"
  notes: "Can avoid ground-based attacks"

regeneration:
  skill: Dragoncraft
  effect: "Dragon regeneration"
  notes: "Passive health regeneration"
```

## Passive Cures
```yaml
# Dragons have various innate resistances
# Specific cures vary by dragon color
```

## Limb Strategy
```yaml
enabled: partial
notes: "Dragons can do limb damage with physical attacks but it's not primary focus"
```

## Bashing (PvE)
```yaml
attack_command: "BREATHE <element> AT <target>" or "CLAW <target>"
attack_skill: Dragoncraft
battlerage_abilities:
  - varies_by_color: "Color-specific battlerage abilities"
  - breathe: "Breath weapon"
  - claw: "Physical damage"
```

## Fighting Against This Class
```yaml
priority_cures:
  - ablaze: "APPLY MENDING - red dragon fire"
  - freezing: "APPLY CALORIC - silver dragon ice"
  - drowning: "EAT PEAR - blue dragon water"
  - sensitivity: "Reduces their high damage"
  - fear: "COMPOSE - from roar"

dangerous_abilities:
  - breath_weapon: "High burst damage (element varies)"
  - physical_attacks: "High base damage"
  - flight: "Aerial advantage"
  - roar: "Fear effect"

avoid:
  - "Taking full breath weapon"
  - "Fighting grounded vs flying dragon"
  - "Ignoring element-specific afflictions"
  - "Low health (high burst potential)"

recommended_strategy: |
  Track which dragon color for element-specific cures.
  Red: Keep mending ready for ablaze.
  Silver: Keep caloric ready for freezing.
  Blue: Keep pear ready for drowning.
  Green: Prioritize affliction cures.
  Gold: Watch for burst lightning damage.
  Black: Cure acid/corrosion effects.
  Dragons are end-game and very powerful - be prepared.
```

## Implementation Notes
```
Triggers to watch for:
- "breathes * at you" - breath weapon by element
- "bites you" - bite attack
- "claws at you" - claw attack
- "tail swipes" - tail attack
- "roars" - fear effect
- "takes flight" - aerial mode

GMCP considerations:
- Track gmcp.Char.Afflictions for afflictions
- Element-specific afflictions vary
- Flight state may need tracking

Edge cases:
- Dragon color determines breath weapon and battlerage
- End-game class with high power level
- Flight provides aerial advantage
- Breath weapon has charge mechanic
- Scales provide natural armor
- Six different colors with different strategies
```

## Color-Specific Notes
```yaml
red_dragon:
  priority_cure: ablaze
  cure_method: "APPLY MENDING"
  main_threat: "Fire damage and ablaze DoT"

black_dragon:
  priority_cure: corrosion
  cure_method: "Varies"
  main_threat: "Acid damage over time"

silver_dragon:
  priority_cure: freezing
  cure_method: "APPLY CALORIC"
  main_threat: "Ice damage and control"

gold_dragon:
  priority_cure: sensitivity
  cure_method: "EAT KELP"
  main_threat: "High burst lightning damage"

blue_dragon:
  priority_cure: drowning
  cure_method: "EAT PEAR"
  main_threat: "Drowning execute"

green_dragon:
  priority_cure: afflictions
  cure_method: "Standard affliction cures"
  main_threat: "Affliction stacking like serpent"
```
