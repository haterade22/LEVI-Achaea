# Blademaster

## Metadata
- **Type**: Base Class
- **Combat Style**: Limb | Damage
- **Difficulty**: Hard
- **Lock Affliction**: Weariness (blocks Fitness passive cure)

## Skills
```
TwoArts: Dual wielding techniques with paired blades
Striking: Precise strikes and cutting techniques
Shindo: The Way - mental discipline and perception
```

## Kill Routes

### Primary Kill: Sever (Limb-Based)
```yaml
type: limb
summary: Damage a limb to 200% (level 3), then sever for instant kill

prerequisites:
  - Any limb at 200% damage (level 3 mangled)
  - Target cannot be in rebounding

steps:
  1: "Focus attacks on a single limb"
  2: "Use limb-targeting strikes to build damage"
  3: "Get limb to level 3 (200%)"
  4: "SEVER <limb> when mangled"

required_limbs:
  any_limb: 3  # head, arm, or leg to level 3

notes: "Sever can target head, arms, or legs - choose based on parry"
```

### Alternative Kill: Damage Rush
```yaml
type: damage
summary: High sustained damage through Two Arts techniques

steps:
  1: "Apply sensitivity to increase damage"
  2: "Use high-damage strike combinations"
  3: "Maintain pressure with fast attacks"
  4: "Kill through accumulated damage"

notes: "Blademaster has high damage output with dual blades"
```

### Alternative Kill: Annihilate
```yaml
type: execute
summary: Stack internal bleeding through strikes, then annihilate

steps:
  1: "Apply internal wounds through strikes"
  2: "Stack bleeding effects"
  3: "When internal damage high enough, ANNIHILATE"
  4: "Target dies from internal trauma"

notes: "Requires significant internal damage buildup"
```

## Offensive Abilities
```yaml
# TwoArts
slash:
  skill: TwoArts
  balance: bal
  effect: "Basic slash with one blade"
  damage_type: cutting
  syntax: "SLASH <target>"

draw:
  skill: TwoArts
  balance: bal
  effect: "Quick draw attack"
  syntax: "DRAW <target>"

rend:
  skill: TwoArts
  balance: bal
  effect: "Rending strike, causes bleeding"
  syntax: "REND <target>"

ricochet:
  skill: TwoArts
  balance: bal
  effect: "Bouncing blade strike"
  syntax: "RICOCHET <target>"

# Striking
precision:
  skill: Striking
  balance: bal
  effect: "Precise limb-targeting strike"
  syntax: "STRIKE <target> <limb>"
  limbs: [head, torso, left_arm, right_arm, left_leg, right_leg]

sever:
  skill: Striking
  balance: bal
  effect: "Instant kill when limb is mangled (level 3)"
  syntax: "SEVER <target> <limb>"
  notes: "Main execute - requires level 3 limb"

feint:
  skill: Striking
  balance: bal
  effect: "Feinting attack"
  syntax: "FEINT <target>"

# Shindo
contemplate:
  skill: Shindo
  balance: eq
  effect: "Enter contemplative state"
  syntax: "CONTEMPLATE"

focus_blade:
  skill: Shindo
  balance: eq
  effect: "Focus mind on blade"
  syntax: "FOCUS BLADE"

perceive:
  skill: Shindo
  balance: eq
  effect: "Perceive enemy weaknesses"
  syntax: "PERCEIVE <target>"
```

## Defensive Abilities
```yaml
fitness:
  skill: Striking
  effect: "Passively cures asthma"
  cures: [asthma]
  blocked_by: [weariness]

dodge:
  skill: TwoArts
  effect: "Chance to dodge incoming attacks"
  notes: "Passive dodge chance"

riposte:
  skill: TwoArts
  effect: "Counter-attack when struck"
  notes: "Automatic counter on successful parry"
```

## Passive Cures
```yaml
fitness:
  cures: [asthma]
  blocked_by: [weariness]
  trigger: "Passive, automatic on asthma gain"
```

## Limb Strategy
```yaml
enabled: true
target_order: [head, left_leg, right_leg]  # focus one limb to level 3
break_requirements:
  target_limb: 3  # sever requires level 3
finisher: "SEVER <target> <limb>"
strategy: |
  Pick a limb based on enemy's parry pattern.
  If they parry head, target legs.
  If they parry legs, target head or arms.
  Only need ONE limb to level 3 for sever.
```

## Bashing (PvE)
```yaml
attack_command: "BATTLERAGE SLASH <target>"
attack_skill: TwoArts
battlerage_abilities:
  - slash: "Basic damage"
  - rend: "Bleeding damage"
```

## Fighting Against This Class
```yaml
priority_cures:
  - weariness: "Restores your Fitness if you have it"
  - broken_limbs: "Prevent sever setup"
  - sensitivity: "Reduce their damage output"
  - bleeding: "Clot to prevent bleedout"

dangerous_abilities:
  - sever: "Instant kill when any limb at level 3"
  - precision: "Fast limb damage accumulation"
  - high_damage: "Sustained damage output is strong"

avoid:
  - "Letting any limb get to level 3"
  - "Ignoring bleeding buildup"
  - "Static parrying (they'll switch targets)"
  - "Letting sensitivity stack"

recommended_strategy: |
  Parry dynamically - Blademaster can target any limb.
  Track which limb they're focusing and parry it.
  Keep restoration salve ready for limb damage.
  Clot bleeding regularly.
  Apply weariness to block their Fitness.
  Apply pressure - their defense is dodge-based.
```

## Implementation Notes
```
Triggers to watch for:
- "strikes at your *" - limb being targeted
- "Your * is damaged/broken/mangled" - track limb state
- "severs your *" - sever attempt
- Bleeding messages - track internal damage
- Shindo activation messages

GMCP considerations:
- Track gmcp.Char.Vitals for limb percentages if available
- Otherwise parse damage messages
- Bleeding amount tracking important

Edge cases:
- Sever can target ANY mangled limb (level 3)
- Dodge is passive and can frustrate attacks
- Riposte provides free counter-attacks
- Shindo abilities use equilibrium
- Internal damage buildup for annihilate route
- Fast attack speed - hard to keep up with curing
```
