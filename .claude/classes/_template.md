# CLASS_NAME

## Metadata
- **Type**: Base Class | Knight | Elemental Lord | Dragon
- **Combat Style**: Affliction | Limb | Hybrid | Damage
- **Difficulty**: Easy | Medium | Hard
- **Lock Affliction**: [affliction needed to complete lock against this class]

## Skills
```
Skill1: Description of what this skill tree provides
Skill2: Description of what this skill tree provides
Skill3: Description of what this skill tree provides
```

## Kill Routes

### Primary Kill: [Name]
```yaml
type: affliction | limb | damage | execute
summary: One sentence description of the kill condition

prerequisites:
  - condition 1
  - condition 2

steps:
  1: "Action to take"
  2: "Next action"
  3: "Final action / kill command"

required_afflictions:
  - affliction1: "why needed"
  - affliction2: "why needed"

required_limbs:  # if limb-based
  - limb: "break level needed"
```

### Alternative Kill: [Name]
```yaml
type: affliction | limb | damage | execute
summary: Backup kill method

steps:
  1: "Action"
  2: "Action"
```

## Offensive Abilities
```yaml
# Key abilities used to attack/afflict
ability_name:
  skill: SkillTree
  balance: bal | eq | both | none
  effect: "What it does"
  afflictions_given: [list]
  damage_type: cutting | blunt | magic | fire | etc
  syntax: "COMMAND SYNTAX"
```

## Defensive Abilities
```yaml
# Key defensive abilities
ability_name:
  skill: SkillTree
  effect: "What it does"
  cures: [afflictions it cures]
  blocks: [what it prevents]
  syntax: "COMMAND SYNTAX"
```

## Passive Cures
```yaml
# Abilities that passively cure (important for lock strategy)
ability_name:
  cures: [affliction]
  blocked_by: [affliction that stops this]
  trigger: "When it activates"
```

## Limb Strategy
```yaml
# If class uses limb damage
enabled: true | false
target_order: [limb1, limb2, limb3]
break_requirements:
  limb: level_needed  # 1, 2, or 3
finisher: "Command that requires broken limbs"
```

## Bashing (PvE)
```yaml
attack_command: "COMMAND"
attack_skill: SkillTree
battlerage_abilities:
  - name: "effect"
```

## Fighting Against This Class
```yaml
priority_cures:
  - affliction: "why prioritize"

dangerous_abilities:
  - ability: "why dangerous"

avoid:
  - "Thing to not do"

recommended_strategy: |
  Multi-line description of how to fight this class.
```

## Implementation Notes
```
Notes for coding offense/defense against this class.
- Trigger patterns to watch for
- GMCP data relevant to this class
- Special edge cases
```
