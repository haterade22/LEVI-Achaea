# Serpent

## Metadata
- **Type**: Base Class
- **Combat Style**: Affliction
- **Difficulty**: Hard
- **Lock Affliction**: Weariness (blocks Fitness passive cure)

## Skills
```
Subterfuge: Stealth, assassination, and utility abilities
Venom: Knowledge and application of toxins
Hypnosis: Mental manipulation through suggestions
```

## Affliction Stacking Strategy
```yaml
concept: |
  Affliction stacking is the technique of applying multiple afflictions
  that share the same cure herb/balance to overwhelm the target's curing.
  Since only ONE affliction per herb can be cured per eat balance, stacking
  2-3 afflictions on the same herb creates a "backlog" that takes multiple
  cures to clear.

kelp_stack:
  description: "Most common and powerful stack"
  afflictions: [asthma, clumsiness, hypochondria, sensitivity, weariness]
  strategy: |
    Apply 2-3 kelp-cured afflictions together.
    Target must cure each one separately on eat balance.
    While they cure one, you reapply another.

ginseng_stack:
  description: "Damage-over-time stack"
  afflictions: [addiction, darkshade, haemophilia, lethargy, scytherus]
  strategy: |
    Stack darkshade + scytherus for heavy DoT pressure.
    Add haemophilia to prevent clotting.

goldenseal_stack:
  description: "Mental affliction stack"
  afflictions: [dissonance, dizziness, epilepsy, impatience, stupidity]
  strategy: |
    Stack impatience (blocks focus) with stupidity.
    Both require goldenseal to cure.

bloodroot_stack:
  description: "Critical lock stack"
  afflictions: [paralysis, slickness]
  strategy: |
    Both cured by bloodroot herb.
    Paralysis blocks tree, slickness blocks salves.
    Very powerful combination.

example_attack_sequence:
  - "DST target kalmia prefarar"     # asthma + sensitivity (both kelp)
  - "DST target clumsiness vernalius" # clumsiness + weariness (both kelp)
  - "Now target has 4 kelp affs, takes 4 eat balances to clear"
```

## Kill Routes

### Primary Kill: True Lock
```yaml
type: affliction
summary: Stack afflictions to achieve true lock, then damage to death

prerequisites:
  - Must apply afflictions faster than target can cure
  - Need weariness to block Fitness (for classes that have it)
  - Use affliction stacking on same-cure herbs for efficiency

steps:
  1: "Stack kelp afflictions: asthma + sensitivity/weariness"
  2: "Apply slickness (blocks applying salves)"
  3: "Apply anorexia (blocks eating herbs)"
  4: "Apply paralysis (blocks tree tattoo)"
  5: "Apply impatience (blocks focus)"
  6: "Maintain kelp stack to keep asthma/weariness stuck"
  7: "Damage to death with envenom attacks"

required_afflictions:
  - asthma: "blocks smoking (kelp cure)"
  - anorexia: "blocks eating"
  - slickness: "blocks applying"
  - paralysis: "blocks tree"
  - impatience: "blocks focus"
  - weariness: "blocks Fitness passive cure (kelp cure - stacks with asthma!)"
```

### Alternative Kill: Hypnosis Suggestion Lock
```yaml
type: affliction
summary: Use hypnosis to force actions and stack afflictions

steps:
  1: "HYPNOTISE <target>"
  2: "Queue suggestions: SUGGEST <target> <suggestion>"
  3: "Common suggestions: disrupt, confusion, impatience, anorexia"
  4: "SNAP to trigger all queued suggestions"
  5: "Continue venom pressure while suggestions fire"

key_suggestions:
  - disrupt: "Disrupts equilibrium"
  - confusion: "Target does random commands"
  - impatience: "Cannot focus"
  - anorexia: "Cannot eat"
  - amnesia: "Forgets commands"

notes: "Takes 4 seconds to SNAP after hypnotizing"
```

### Alternative Kill: Darkshade/Scytherus Damage
```yaml
type: damage
summary: Stack damage-over-time afflictions for passive damage kill

steps:
  1: "Apply darkshade (damage over time)"
  2: "Apply scytherus (damage over time)"
  3: "Apply sensitivity (increases all damage)"
  4: "Continue venom pressure while DoTs tick"
  5: "Target dies to accumulated damage"

required_afflictions:
  - darkshade: "Periodic damage"
  - scytherus: "Periodic damage"
  - sensitivity: "50% more damage taken"
```

### Alternative Kill: Garrote
```yaml
type: execute
summary: Strangle target from behind for execute

prerequisites:
  - Must be hidden (HIDE)
  - Must be behind target
  - Target must not be alert

steps:
  1: "HIDE to enter stealth"
  2: "Position behind target"
  3: "GARROTE <target>"

notes: "Can be blocked by alertness/vigilance defenses"
```

## Offensive Abilities
```yaml
# Subterfuge
bite:
  skill: Subterfuge
  balance: bal
  effect: "Bite with envenomed fangs, applies one venom"
  syntax: "BITE <target> <venom>"
  notes: "Single venom application"

doublestab:
  skill: Subterfuge
  balance: bal
  effect: "Stab twice with dirks, applies two venoms"
  syntax: "DST <target> <venom1> <venom2>"
  notes: "Most common attack, two venoms per balance"

flay:
  skill: Subterfuge
  balance: bal
  effect: "Strip rebounding or shield defense"
  syntax: "FLAY <target>"

garrote:
  skill: Subterfuge
  balance: bal
  effect: "Strangle from stealth for execute"
  syntax: "GARROTE <target>"
  notes: "Requires hidden, behind target"

hide:
  skill: Subterfuge
  balance: eq
  effect: "Enter stealth mode"
  syntax: "HIDE"

phase:
  skill: Subterfuge
  balance: eq
  effect: "Become phased, untargetable"
  syntax: "PHASE"

# Hypnosis
hypnotise:
  skill: Hypnosis
  balance: eq
  effect: "Begin hypnosis on target"
  syntax: "HYPNOTISE <target>"
  notes: "Required before suggestions"

suggest:
  skill: Hypnosis
  balance: eq
  effect: "Queue a suggestion for target"
  syntax: "SUGGEST <target> <suggestion>"

snap:
  skill: Hypnosis
  balance: eq
  effect: "Trigger all queued suggestions"
  syntax: "SNAP"
  notes: "4 second delay after hypnotise"

seal:
  skill: Hypnosis
  balance: eq
  effect: "Lock in a suggestion permanently"
  syntax: "SEAL <target> <suggestion>"
```

## Complete Venom Reference
```yaml
# Venoms are used by Serpents and classes with edged weapons (Knights DWC)
# Listed by combat utility category

# === LOCK AFFLICTIONS (Priority for True Lock) ===
kalmia:
  affliction: asthma
  cure: kelp
  effect: "Contracts lungs, blocks smoking pipes"
  lock_role: "Blocks smoke cures (aeon, slickness alt)"

gecko:
  affliction: slickness
  cure: bloodroot
  effect: "Body coated in slick slime, blocks applying salves"
  lock_role: "Blocks salve cures (anorexia, restoration, mending)"

slike:
  affliction: anorexia
  cure: epidermal
  effect: "Lose all desire for food/drink, blocks eating herbs"
  lock_role: "Blocks herb cures (most afflictions)"

curare:
  affliction: paralysis
  cure: bloodroot
  effect: "Muscles fail to respond, cannot move or act"
  lock_role: "Blocks tree tattoo usage"

xentio:
  affliction: clumsiness
  cure: kelp
  effect: "Become clumsy fool, fumble attacks and actions"
  lock_role: "Often confused with impatience - actually gives clumsiness"
  notes: "For impatience (blocks focus), use different method"

vernalius:
  affliction: weariness
  cure: kelp
  effect: "Strength leaves body, blocks Fitness passive cure"
  lock_role: "Blocks Fitness (asthma auto-cure for most classes)"

# === DAMAGE VENOMS ===
sumac:
  affliction: damage
  cure: none
  effect: "Minor direct damage"

camus:
  affliction: damage
  cure: none
  effect: "Concentrated sumac, more potent damage"

darkshade:
  affliction: darkshade
  cure: ginseng
  effect: "Sun sears flesh when exposed to sunlight (DoT)"
  notes: "Damage over time in outdoor/lit rooms"

scytherus:
  affliction: scytherus
  cure: ginseng
  effect: "Blood turns against when foreign substance introduced"
  notes: "Damage when eating/drinking cures"

voyria:
  affliction: voyria
  cure: immunity_elixir
  effect: "Most deadly venom, rapid damage to death"
  notes: "Only cured by sipping immunity elixir"

# === SENSITIVITY/DAMAGE AMPLIFIERS ===
prefarar:
  affliction: sensitivity
  cure: kelp
  effect: "All nerve endings heightened, 50% more damage taken"
  notes: "Stacks with kelp affs (asthma, weariness)"

# === UTILITY AFFLICTIONS ===
oleander:
  affliction: blindness
  cure: epidermal
  effect: "Visual system fails, eyes no longer function"

colocasia:
  affliction: deafblind
  cure: epidermal
  effect: "Robbed of sight AND hearing simultaneously"

digitalis:
  affliction: shyness
  cure: goldenseal
  effect: "Become shy, fearful, cannot speak or yell"

aconite:
  affliction: stupidity
  cure: goldenseal
  effect: "Brain ceases operating correctly, complete stupor"
  notes: "Disrupts focus attempts, equilibrium skills"

monkshood:
  affliction: disfigurement
  cure: valerian_smoke
  effect: "Horrible facial disfigurement, loyals may turn"

euphorbia:
  affliction: vomiting
  cure: ginseng
  effect: "Digestive upheaval, spasmodic vomiting"
  notes: "Interrupts eating, purges rift items"

larkspur:
  affliction: dizziness
  cure: goldenseal
  effect: "Induces great dizziness"

delphinium:
  affliction: sleep
  cure: none
  effect: "Slows heartrate, induces peaceful sleep"
  notes: "Target must be woken or cannot act"

vardrax:
  affliction: addiction
  cure: ginseng
  effect: "Instills addiction that cannot be sated"
  notes: "Must smoke constantly or suffer withdrawals"

# === LIMB VENOMS ===
epteth:
  affliction: crippled_arms
  cure: restoration
  effect: "Upper limb muscles shrivel, arms become useless"
  notes: "Affects arm limbs"

epseth:
  affliction: crippled_legs
  cure: restoration
  effect: "Leg muscles rot and wither"
  notes: "Affects leg limbs"

# === MENTAL AFFLICTIONS ===
eurypteria:
  affliction: recklessness
  cure: lobelia
  effect: "Believe yourself immortal, run into battle recklessly"
  notes: "Target takes more risks, doesn't flee"

# === SPECIAL VENOMS ===
loki:
  affliction: random
  cure: varies
  effect: "Random effects from sickness to death"
  notes: "Chaotic, unpredictable - not reliable for strategies"

selarnia:
  affliction: disrupt_morph
  cure: none
  effect: "Disrupts concentration of shapechangers"
  notes: "Forces druids/sentinels out of morph forms"

oculus:
  affliction: cure_blindness
  cure: none
  effect: "Forcibly heals those with shut eyes or blindness"
  notes: "Anti-venom, removes enemy's blind defense"

nechamandra:
  affliction: shivering
  cure: caloric
  effect: "Blood runs cold, violent shivering"
  notes: "Freezing effect"

notechis:
  affliction: haemophilia
  cure: ginseng
  effect: "Prevents blood from clotting"
  notes: "Target cannot clot bleeding"

# === VENOM CURE GROUPINGS (for affliction stacking) ===
cure_groups:
  kelp: [asthma, clumsiness, sensitivity, weariness, hypochondria, health_leech]
  ginseng: [addiction, darkshade, haemophilia, lethargy, nausea, scytherus]
  goldenseal: [dizziness, epilepsy, impatience, shyness, stupidity, dissonance]
  lobelia: [agoraphobia, claustrophobia, loneliness, masochism, recklessness, vertigo]
  bloodroot: [paralysis, slickness]
  epidermal: [anorexia, blindness, deafness]
  valerian_smoke: [disfigurement, slickness_alt]
  caloric: [shivering, frozen]
  restoration: [crippled_limbs]
```

## Defensive Abilities
```yaml
scales:
  skill: Subterfuge
  effect: "Damage reduction"
  syntax: "SCALES"

phase:
  skill: Subterfuge
  effect: "Become untargetable (phased)"
  syntax: "PHASE"
  notes: "Cannot attack while phased"

hiding:
  skill: Subterfuge
  effect: "Cannot be targeted if hidden"
  notes: "Broken by various detections"
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
enabled: false
notes: "Serpent is affliction-based, not limb-based"
```

## Bashing (PvE)
```yaml
attack_command: "BATTLERAGE BITE <target>"
attack_skill: Subterfuge
battlerage_abilities:
  - bite: "Basic damage"
  - envenom: "Additional damage"
```

## Fighting Against This Class
```yaml
priority_cures:
  - asthma: "Restore smoking ability"
  - slickness: "Restore salve application"
  - anorexia: "Restore eating ability"
  - paralysis: "Restore tree usage"
  - impatience: "Restore focus ability"
  - sensitivity: "Reduce incoming damage"

dangerous_abilities:
  - doublestab: "Two venoms per attack"
  - hypnosis: "Forces afflictions through suggestions"
  - garrote: "Instant kill from stealth"
  - phase: "Makes them untargetable"

avoid:
  - "Letting lock afflictions stack"
  - "Standing still when they're hidden"
  - "Ignoring hypnosis (will SNAP suggestions)"
  - "Low health with darkshade/scytherus active"

recommended_strategy: |
  Prioritize curing lock afflictions in order: asthma, slickness, anorexia.
  Keep alertness/vigilance up to prevent garrote.
  When hypnotised, move or attack to break it before SNAP.
  Track their venom usage to anticipate next affliction.
  Rebounding/shield helps slow their venom application.
  If sensitivity is up, be extra careful about damage intake.
```

## Implementation Notes
```
Triggers to watch for:
- "jabs you with a dirk coated in" - venom application
- "bites you viciously" - bite attack
- "begins to weave" - hypnosis starting
- "snaps" - suggestions triggering
- "disappears into the shadows" - they hid
- "phases out of existence" - they phased

GMCP considerations:
- Track gmcp.Char.Afflictions for current affs
- Venom tracking via attack messages
- Hidden state not in GMCP, must use triggers

Edge cases:
- Double venom means 2 afflictions per attack
- Hypnosis suggestions fire with 4s delay
- Phase makes them untargetable but they can't attack
- Garrote requires hidden AND behind target
- Some venoms share cure balance (kelp cures)

Venom cure groupings (same herb):
- Kelp: asthma, clumsiness, hypochondria, sensitivity, weariness
- Ginseng: addiction, darkshade, haemophilia, lethargy, scytherus
- Goldenseal: dissonance, dizziness, epilepsy, impatience, stupidity
- Lobelia: agoraphobia, claustrophobia, loneliness, masochism, recklessness, vertigo
- Bloodroot: paralysis, slickness (alt)
```
