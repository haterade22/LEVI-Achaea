# Paladin

## Metadata
- **Type**: Knight
- **Combat Style**: Limb | Affliction (depends on spec)
- **Difficulty**: Medium
- **Lock Affliction**: Weariness (blocks Fitness passive cure)

## Skills
```
Excision: Light-based abilities and smiting powers
Valour: Eagle companion abilities and defensive auras
Weaponmastery: Combat with various weapon specializations (DWC, DWB, SnB, 2H)
```

## Specializations (Weaponmastery)
```yaml
DWC (Dual Wield Cutting):
  weapons: [scimitar, scimitar] or [longsword, longsword]
  style: Fast attacks, double venom application
  strength: Speed, venom stacking

DWB (Dual Wield Blunt):
  weapons: [mace, mace] or [flail, flail]
  style: Limb breaking, double breaks per attack
  strength: Best limb prep, breaks through parry

SnB (Sword and Board):
  weapons: [longsword, shield] or [broadsword, shield]
  style: Impale/stun combos, defensive
  strength: Damage mitigation, reliable disembowel

2H (Two-Handed):
  weapons: [bastard sword] or [warhammer]
  style: High damage, strip defenses
  strength: Best damage, passive para cure, strips rebounding/shield
```

## Kill Routes

### Primary Kill: Disembowel (Limb-Based)
```yaml
type: limb
summary: Break both legs and an arm, then disembowel for instant kill

prerequisites:
  - Target must be prone
  - Both legs broken (level 2)
  - One arm broken (level 2)

steps:
  1: "Prep limbs - focus legs first, then arm"
  2: "Knock target prone"
  3: "DISEMBOWEL <target>"

required_limbs:
  left_leg: 2
  right_leg: 2
  left_arm: 2  # or right_arm
```

### Alternative Kill: Behead (Limb-Based)
```yaml
type: limb
summary: Break head to level 3 (mangled), then behead

steps:
  1: "Focus all damage on head"
  2: "Get head to 200% (level 3 mangled)"
  3: "BEHEAD <target>"

required_limbs:
  head: 3
```

### Alternative Kill: Rite of Annihilation (Excision)
```yaml
type: execute
summary: Use Excision abilities to build toward annihilation execute

steps:
  1: "Build devotion through combat"
  2: "Apply righteous afflictions"
  3: "Execute with annihilation when conditions met"

notes: "Requires specific Excision ability setup"
```

## Offensive Abilities
```yaml
# Weaponmastery
slash:
  skill: Weaponmastery
  balance: bal
  effect: "Basic attack with cutting weapon"
  damage_type: cutting
  syntax: "SLASH <target>"

raze:
  skill: Weaponmastery
  balance: bal
  effect: "Strip shield or rebounding"
  syntax: "RAZE <target>"

impale:
  skill: Weaponmastery
  balance: bal
  effect: "Impale target, prevents movement"
  syntax: "IMPALE <target>"
  notes: "SnB spec"

disembowel:
  skill: Weaponmastery
  balance: bal
  effect: "Instant kill if legs and arm broken, target prone"
  syntax: "DISEMBOWEL <target>"

# Excision
smite:
  skill: Excision
  balance: eq
  effect: "Light-based damage attack"
  damage_type: magic
  syntax: "SMITE <target>"

# Valour
eagle:
  skill: Valour
  balance: eq
  effect: "Command eagle companion to attack"
  syntax: "EAGLE ATTACK <target>"
```

## Defensive Abilities
```yaml
fitness:
  skill: Weaponmastery
  effect: "Passively cures asthma"
  cures: [asthma]
  blocked_by: [weariness]
  trigger: "Automatic when asthma is gained"

aura:
  skill: Valour
  effect: "Protective aura reducing damage"
  syntax: "AURA"
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
target_order: [left_leg, right_leg, left_arm]  # for disembowel
break_requirements:
  left_leg: 2
  right_leg: 2
  left_arm: 2
finisher: "DISEMBOWEL <target>"
```

## Bashing (PvE)
```yaml
attack_command: "BATTLERAGE SLASH <target>" or spec-specific
attack_skill: Weaponmastery
battlerage_abilities:
  - slash: "Basic damage"
  - rend: "Additional damage"
```

## Fighting Against This Class
```yaml
priority_cures:
  - paralysis: "Prevents tree, allows them to continue attacking"
  - weariness: "Restores your Fitness if you have it"
  - broken_limbs: "Prevent disembowel setup"

dangerous_abilities:
  - disembowel: "Instant kill if limbs broken"
  - impale: "Locks you in place (SnB)"
  - smite: "Light damage can stack"

avoid:
  - "Letting both legs get broken"
  - "Being prone with broken limbs"
  - "Ignoring limb damage"
  - "Standing in consecrated ground"

recommended_strategy: |
  Focus on keeping limbs healthy with restoration/mending.
  Parry legs to slow their prep.
  If they're 2H spec, watch for high damage and passive para cure.
  If they're DWC spec, prioritize curing venoms quickly.
  Watch for eagle attacks adding pressure.
```

## Implementation Notes
```
Triggers to watch for:
- "You have been impaled" - need to writhe
- "Your * is damaged/broken/mangled" - track limb state
- Venom messages for DWC tracking
- "An eagle dives at you" - eagle attack incoming
- Smite/Excision ability messages

GMCP considerations:
- Track gmcp.Char.Vitals for limb percentages if available
- Otherwise parse damage messages

Edge cases:
- 2H spec cures paralysis passively when attacking
- SnB has shield bash that can give random afflictions
- Eagle companion can be killed/dismissed
- Excision abilities may have devotion requirements
```
