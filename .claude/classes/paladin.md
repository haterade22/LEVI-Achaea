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

### Alternative Kill: Damnation (Excision)
```yaml
type: execute
summary: Consign target's soul when head is broken with pyre/guilt/spiritburn components
syntax: "PERFORM DAMNATION <target>"
cooldown: 4.00 seconds equilibrium

prerequisites:
  - Broken head (level 1+, i.e. damagedhead or higher)
  - AND either:
    - Two of: pyre, guilt, spiritburn (MOST COMMON)
    - OR Level 5 burning (less common)

kill_components:
  pyre:
    description: "Separate affliction that blocks curing burning below pyre level"
    applied_by: "PERFORM PYRE <target> (2.5s wrath balance, 5% Holy Wrath)"
    cure: "Cuprum flake (bellwort mineral) - reduces pyre level by 1"
    gmcp_name: "pyre1, pyre2, pyre3"
    source: "PALADIN"
  guilt:
    description: "Blocks Focus ability"
    applied_by: "Priest zeal abilities (NOT Paladin!)"
    cure: "Lobelia/argentum"
    source: "PRIEST ONLY"
  spiritburn:
    description: "Fire damage to spirit"
    applied_by: "Priest zeal abilities (NOT Paladin!)"
    cure: "Ash/calcium"
    source: "PRIEST ONLY"
  burning:
    description: "Fire DoT - level 5 enables Damnation (alternative to pyre/guilt/spiritburn)"
    cure: "Cuprum flake - BUT cannot cure below pyre level!"

solo_vs_group_note: |
  CRITICAL: Paladins can ONLY apply PYRE, not guilt or spiritburn!
  - Solo Paladin: Can only kill via burning level 5 route (head broken + burning 5)
  - Paladin + Priest: Can kill via component route (head broken + pyre + guilt/spiritburn)
  - If fighting solo Paladin, focus on preventing burning from stacking to 5

important_note: |
  PYRE and BURNING are DIFFERENT afflictions!
  - PYRE: A separate stacking affliction (1-3) that BLOCKS curing burning
  - BURNING: Fire damage over time affliction (1-5) from BLADEFIRE
  - If you have PYRE(3), you cannot cure BURNING below level 3
  - Most Damnation kills use pyre + guilt OR pyre + spiritburn (2 of 3)

steps:
  1: "Break target's head via limb damage or weaponmastery head attacks"
  2: "PERFORM PYRE <target> to apply pyre affliction"
  3: "Apply guilt and/or spiritburn via zeal abilities"
  4: "When head broken + 2 components: PERFORM DAMNATION <target>"

detection:
  pyre_applied: "As fire surges about the righteous <Paladin>, a terrible heat fills your chest"
  pyre_increase: "The fires consuming your flesh begin to crackle with greater intensity"
  pyre_high: "Your vision begins to fade with the all-consuming agony"
  guilt_applied: "You are wracked with guilt"
  spiritburn_applied: "Your spirit burns"
  kill_message: "your soul is consigned to damnation"

defense_priority: |
  1. If head is damaged, prioritize healing head IMMEDIATELY
  2. PYRE CURE STRATEGY:
     - Only cure pyre if at level 3 AND waiting to resto but would die if you resto
     - Once pyre is cured to level 1, you can apply resto safely
     - At pyre 1, burning can be cured down to 1 (safe from Damnation)
     - At pyre 3, burning floor is locked at 3 (still in Damnation danger zone)
  3. Track ALL THREE components: pyre, guilt, spiritburn
  4. With head broken + any 1 component, you are ONE HIT from death
  5. Consider shielding/fleeing if head broken + pyre 3
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
  - pyre: "CRITICAL when head is damaged - prevents Damnation kill"
  - guilt: "Blocks Focus ability"
  - damagedhead: "Prevent head break to avoid Damnation setup"

dangerous_abilities:
  - disembowel: "Instant kill if limbs broken and prone"
  - damnation: "Instant kill if head broken + pyre conditions (see below)"
  - impale: "Locks you in place (SnB)"
  - smite: "Light damage can stack"

damnation_kill_conditions:
  required: "Broken head (damagedhead or higher)"
  trigger_a: "Two of: pyre, guilt, spiritburn (group with Priest)"
  trigger_b: "OR burning level 5 (solo Paladin route)"
  defense: |
    SOLO PALADIN:
    1. Paladin can ONLY give PYRE - they need burning level 5 for kill
    2. Prioritize curing head damage before it breaks
    3. If head IS broken, watch burning level closely
    4. Cuprum cures both pyre (level -1) AND burning (but not below pyre level!)
    5. If head broken + burning 3+, consider shielding/fleeing

    GROUP (PALADIN + PRIEST):
    1. Priests give guilt and spiritburn - this enables faster Damnation
    2. Head broken + pyre + guilt/spiritburn = instant death
    3. Prioritize head healing above all else
    4. If head IS broken, pyre becomes CRITICAL priority
    5. With head broken + any 1 component, you are ONE hit from death

avoid:
  - "Letting both legs get broken"
  - "Being prone with broken limbs"
  - "Ignoring limb damage"
  - "Standing in consecrated ground"
  - "Having head broken while pyre stacks (Damnation threat)"
  - "Ignoring pyre - it stacks and enables instant kill"

recommended_strategy: |
  Focus on keeping limbs healthy with restoration/mending.
  Parry legs to slow their prep.
  If they're 2H spec, watch for high damage and passive para cure.
  If they're DWC spec, prioritize curing venoms quickly.
  Watch for eagle attacks adding pressure.

  DAMNATION DEFENSE (SOLO PALADIN):
  - Paladin can ONLY give PYRE - guilt/spiritburn require a Priest!
  - Solo Paladin must use burning level 5 route for Damnation
  - Monitor BOTH pyre AND burning levels in prompt
  - If head takes damage, immediately prioritize head healing
  - Cuprum cures pyre AND burning (but burning can't go below pyre level)
  - Watch for "fire surges" message = pyre applied

  DAMNATION DEFENSE (PALADIN + PRIEST GROUP):
  - Priest provides guilt/spiritburn, enabling fast Damnation
  - Head broken + pyre + guilt/spiritburn = INSTANT DEATH
  - If head IS broken, ALL Damnation components become CRITICAL
  - Consider fleeing/shielding if head broken and any component present
```

## Limb Tracking
```yaml
# Uses lb[target].hits["limb"] format for limb damage tracking
# NOT tLimbs - use Romaen's limb counter format

access_pattern:
  left_leg: 'lb[target].hits["left leg"]'
  right_leg: 'lb[target].hits["right leg"]'
  left_arm: 'lb[target].hits["left arm"]'
  right_arm: 'lb[target].hits["right arm"]'
  head: 'lb[target].hits["head"]'
  torso: 'lb[target].hits["torso"]'

break_levels:
  0-99: "Healthy"
  100-149: "Broken (Level 1) - damaged"
  150-199: "Broken (Level 2) - mangled"
  200+: "Broken (Level 3) - destroyed"

disembowel_check: |
  lb[target].hits["left leg"] >= 100
  AND lb[target].hits["right leg"] >= 100
  AND (lb[target].hits["left arm"] >= 100 OR lb[target].hits["right arm"] >= 100)
  AND tAffs.prone
  → DISEMBOWEL

behead_check: |
  lb[target].hits["head"] >= 200
  → BEHEAD
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
- lb[target].hits["limb"] - enemy limb damage tracking

Edge cases:
- 2H spec cures paralysis passively when attacking
- SnB has shield bash that can give random afflictions
- Eagle companion can be killed/dismissed
- Excision abilities may have devotion requirements
```
