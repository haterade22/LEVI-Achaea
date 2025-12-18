# Priest

## Metadata
- **Type**: Base Class
- **Combat Style**: Affliction | Damage
- **Difficulty**: Medium
- **Lock Affliction**: Voyria (blocks immunity elixir sip)

## Skills
```
Spirituality: Spirit-based healing and abilities
Devotion: Divine devotion powers
Zeal: Holy combat abilities with guardian angel
```

## Kill Routes

### Primary Kill: Angel Kill
```yaml
type: execute
summary: Use guardian angel to execute at low health

prerequisites:
  - Must have guardian angel summoned
  - Target must be at low health threshold

steps:
  1: "Summon guardian angel"
  2: "Apply afflictions to pressure target"
  3: "Use angel attacks for damage"
  4: "When health low enough, ANGEL EXECUTE <target>"

notes: "Angel execute requires specific health threshold"
```

### Alternative Kill: Affliction Lock
```yaml
type: affliction
summary: Use Devotion and Zeal for affliction stacking

steps:
  1: "Apply afflictions through devotion abilities"
  2: "Stack toward true lock"
  3: "Apply voyria to block immunity"
  4: "Use angel for additional pressure"
  5: "Damage to death through lock"

required_afflictions:
  - asthma: "blocks smoking"
  - anorexia: "blocks eating"
  - slickness: "blocks applying"
  - paralysis: "blocks tree"
  - impatience: "blocks focus"
  - voyria: "blocks immunity elixir (class-specific)"
```

### Alternative Kill: Holy Damage
```yaml
type: damage
summary: Use devotion and angel for sustained holy damage

steps:
  1: "Apply sensitivity"
  2: "Use smite and holy damage abilities"
  3: "Command angel attacks"
  4: "Kill through accumulated damage"
```

## Offensive Abilities
```yaml
# Spirituality
healing:
  skill: Spirituality
  balance: eq
  effect: "Heal self or allies"
  syntax: "HEAL <target>"

cleanse:
  skill: Spirituality
  balance: eq
  effect: "Cleanse afflictions"
  syntax: "CLEANSE <target>"

# Devotion
smite:
  skill: Devotion
  balance: eq
  effect: "Holy damage attack"
  damage_type: holy
  syntax: "SMITE <target>"

piety:
  skill: Devotion
  balance: eq
  effect: "Apply piety effects"
  syntax: "PIETY <target>"

damnation:
  skill: Devotion
  balance: eq
  effect: "Mark for damnation"
  syntax: "DAMNATION <target>"

# Zeal
angel_summon:
  skill: Zeal
  balance: eq
  effect: "Summon guardian angel"
  syntax: "ANGEL SUMMON"

angel_attack:
  skill: Zeal
  balance: free
  effect: "Command angel to attack"
  syntax: "ANGEL ATTACK <target>"
  notes: "Angel orders are free balance"

angel_execute:
  skill: Zeal
  balance: eq
  effect: "Angel instant kill at low health"
  syntax: "ANGEL EXECUTE <target>"
  notes: "Requires target at health threshold"

angel_afflict:
  skill: Zeal
  balance: free
  effect: "Angel applies affliction"
  syntax: "ANGEL <affliction> <target>"
```

## Defensive Abilities
```yaml
healing:
  skill: Spirituality
  effect: "Self and ally healing"
  syntax: "HEAL"

angel_cure:
  skill: Zeal
  effect: "Angel can cure afflictions"
  syntax: "ANGEL CURE"

sanctuary:
  skill: Devotion
  effect: "Protective sanctuary"
  syntax: "SANCTUARY"
```

## Passive Cures
```yaml
# Priest has active cure through angel and spirituality
# Voyria blocks their immunity elixir use
```

## Limb Strategy
```yaml
enabled: false
notes: "Priest is affliction/damage-based, not limb-based"
```

## Bashing (PvE)
```yaml
attack_command: "ANGEL ATTACK <target>"
attack_skill: Zeal
battlerage_abilities:
  - angel_attack: "Angel damage"
  - smite: "Holy damage"
```

## Fighting Against This Class
```yaml
priority_cures:
  - asthma: "Restore smoking ability"
  - slickness: "Restore salve application"
  - anorexia: "Restore eating ability"
  - damnation: "Remove damnation mark"
  - voyria: "SIP IMMUNITY to cure"

dangerous_abilities:
  - angel_execute: "Instant kill at low health"
  - angel_attacks: "Free balance attacks"
  - smite: "Holy damage"
  - healing: "They can heal themselves and allies"

avoid:
  - "Getting to low health (angel execute)"
  - "Ignoring angel (can be killed)"
  - "Letting voyria stick"
  - "Fighting in their sanctuary"

recommended_strategy: |
  Keep health above angel execute threshold.
  Kill their angel if it's doing significant damage.
  Don't let voyria stick - need immunity sips.
  Prioritize curing lock afflictions.
  Disrupt their healing if possible.
  Pressure them before they can set up.
```

## Implementation Notes
```
Triggers to watch for:
- "A guardian angel appears" - angel summoned
- "angel attacks you" - angel attack
- "angel executes" - instant kill attempt
- "smites you" - holy damage
- Damnation application messages
- Healing messages

GMCP considerations:
- Track gmcp.Char.Afflictions for afflictions
- Angel presence via room items/messages
- Voyria in afflictions

Edge cases:
- Voyria is their class-specific lock aff
- Angel orders are FREE balance
- Angel execute has health threshold
- Angel can be killed/dismissed
- Healing can be used on allies
- Sanctuary provides room protection
```
