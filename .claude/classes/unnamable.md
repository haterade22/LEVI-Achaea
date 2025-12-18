# Unnamable

## Metadata
- **Type**: Knight
- **Combat Style**: Limb | Affliction (depends on spec)
- **Difficulty**: Hard
- **Lock Affliction**: Weariness (blocks Fitness passive cure)

## Skills
```
Dominion: Chaos-based powers and mutations
Anathema: Curses and entropy manipulation
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

### Alternative Kill: Chaos Mutations + Lock
```yaml
type: hybrid
summary: Use Dominion mutations and Anathema curses to enhance combat

steps:
  1: "Apply chaos mutations for combat bonuses"
  2: "Use Anathema curses for affliction pressure"
  3: "Stack venoms toward lock (DWC) or limbs (DWB/2H)"
  4: "Execute with disembowel or damage through lock"

notes: "Dominion provides unique mutation-based enhancements"
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

# Dominion
mutate:
  skill: Dominion
  balance: eq
  effect: "Apply chaos mutations for combat bonuses"
  syntax: "MUTATE <mutation>"

frenzy:
  skill: Dominion
  balance: eq
  effect: "Enter frenzied state for increased damage"
  syntax: "FRENZY"

# Anathema
curse:
  skill: Anathema
  balance: eq
  effect: "Apply curse afflictions"
  syntax: "CURSE <target> <curse>"

entropy:
  skill: Anathema
  balance: eq
  effect: "Entropy-based damage over time"
  syntax: "ENTROPY <target>"
```

## Defensive Abilities
```yaml
fitness:
  skill: Weaponmastery
  effect: "Passively cures asthma"
  cures: [asthma]
  blocked_by: [weariness]
  trigger: "Automatic when asthma is gained"

mutation_defenses:
  skill: Dominion
  effect: "Various defensive mutations available"
  notes: "Specific mutations provide different benefits"
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
  - curses: "Anathema curses can stack"

dangerous_abilities:
  - disembowel: "Instant kill if limbs broken"
  - impale: "Locks you in place (SnB)"
  - frenzy: "Increased damage output"
  - mutations: "Various combat enhancements"

avoid:
  - "Letting both legs get broken"
  - "Being prone with broken limbs"
  - "Ignoring limb damage"
  - "Letting curse stacks build up"

recommended_strategy: |
  Focus on keeping limbs healthy with restoration/mending.
  Parry legs to slow their prep.
  If they're 2H spec, watch for high damage and passive para cure.
  If they're DWC spec, prioritize curing venoms quickly.
  Watch for frenzy - they'll deal increased damage.
  Track their mutations for active defensive/offensive bonuses.
  Unnamable is considered difficult due to chaos mechanics.
```

## Implementation Notes
```
Triggers to watch for:
- "You have been impaled" - need to writhe
- "Your * is damaged/broken/mangled" - track limb state
- Venom messages for DWC tracking
- Mutation activation messages
- Curse application messages
- "enters a frenzy" - increased damage incoming

GMCP considerations:
- Track gmcp.Char.Vitals for limb percentages if available
- Otherwise parse damage messages
- Track curse afflictions separately

Edge cases:
- 2H spec cures paralysis passively when attacking
- SnB has shield bash that can give random afflictions
- Mutations may have duration/toggle states
- Frenzy state increases damage but may have drawbacks
- Chaos-based abilities can be unpredictable
```
