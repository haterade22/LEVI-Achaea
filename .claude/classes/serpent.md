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
Hypnosis: Mental manipulation through suggestions (including Impulse)
```

---

## CRITICAL: Impulse Mechanics (Updated 2024)

**Impulse is the primary method Serpents use to deliver mental afflictions.**

```yaml
impulse_requirements:
  description: "Impulse SUGGEST only works when ALL conditions are met"
  conditions:
    - "Victim has NO sileris/fangbarrier defense"
    - "Victim HAS asthma affliction"
    - "Victim HAS weariness affliction"

  delivery: |
    Once requirements met, Serpent uses IMPULSE <target> SUGGEST <affliction>
    This delivers mental afflictions like impatience, anorexia instantly.

  note: "SNAP from hypnosis does NOT deliver impatience anymore - use Impulse instead"

impulse_afflictions:
  - impatience: "Blocks focus - critical for true lock"
  - anorexia: "Blocks eating - delivered after slickness applied"
  - confusion: "Random commands"
  - amnesia: "Forgets queued commands"
  - stupidity: "Disrupts equilibrium skills"

counter_impulse:
  - "Maintain sileris/fangbarrier defense"
  - "Cure asthma OR weariness quickly (both are kelp - only one at a time)"
  - "Prioritize asthma cure when both present to break impulse setup"
```

---

## Fratricide Mechanics

```yaml
fratricide:
  venom: "Unknown - likely Hypnosis or special ability"
  cure: "Argentum (pill)"
  effect: |
    When victim has fratricide, impulse-delivered mental afflictions
    will RELAPSE after being cured. This creates a "focus lock" where:
    1. Serpent delivers impatience via impulse
    2. Victim focuses to cure impatience
    3. Fratricide causes impatience to RELAPSE immediately
    4. Victim cannot escape the mental affliction loop

  priority: |
    Must cure fratricide BEFORE approaching lock state.
    If you have asthma + slickness + fratricide, you're in danger.
    Cure fratricide early to prevent impulse relapse loop.
```

---

## Affliction Stacking Strategy
```yaml
concept: |
  Affliction stacking is the technique of applying multiple afflictions
  that share the same cure herb/balance to overwhelm the target's curing.
  Since only ONE affliction per herb can be cured per eat balance, stacking
  2-3 afflictions on the same herb creates a "backlog" that takes multiple
  cures to clear.

kelp_stack:
  description: "Most common and powerful stack - ENABLES IMPULSE"
  afflictions: [asthma, clumsiness, hypochondria, sensitivity, weariness]
  critical_note: |
    Asthma + Weariness together enables Impulse delivery.
    Both are kelp cures - victim can only cure ONE per eat balance.
    This is the foundation of Serpent lock strategy.

ginseng_stack:
  description: "Damage-over-time stack"
  afflictions: [addiction, darkshade, haemophilia, lethargy, scytherus]
  strategy: |
    Stack darkshade + scytherus for heavy DoT pressure.
    Add haemophilia to prevent clotting.

goldenseal_stack:
  description: "Mental affliction stack (delivered via Impulse)"
  afflictions: [dissonance, dizziness, epilepsy, impatience, stupidity]
  strategy: |
    Impatience blocks focus - critical for true lock.
    Delivered via IMPULSE, NOT via venom or SNAP.

bloodroot_stack:
  description: "Critical lock stack"
  afflictions: [paralysis, slickness]
  strategy: |
    Both cured by bloodroot herb.
    Paralysis blocks tree AND all actions.
    Slickness blocks salves (can't cure anorexia).
    When asthma present, can't smoke valerian for slickness.
    PRIORITIZE PARALYSIS when asthma blocks smoking.
```

## Kill Routes

### Primary Kill: Impulse Lock (Modern Serpent)
```yaml
type: affliction
summary: Use Impulse to deliver mental afflictions after establishing kelp stack

prerequisites:
  - Target must have asthma + weariness (enables Impulse)
  - Target must NOT have sileris/fangbarrier defense
  - Apply fratricide to prevent focus escape

attack_sequence_from_combat_log:
  phase_1_kelp_setup:
    - "DST target kalmia vernalius"   # asthma + weariness (BOTH kelp cures)
    - "Flay sileris/rebounding"       # Remove defenses blocking impulse
    - "Target now vulnerable to Impulse"

  phase_2_impulse_delivery:
    - "IMPULSE target SUGGEST impatience"  # Blocks focus
    - "IMPULSE target SUGGEST anorexia"    # Blocks eating (after slickness)
    - "Fratricide applied via hypnosis"    # Causes impulse affs to RELAPSE

  phase_3_lock_completion:
    - "DST target curare gecko"       # paralysis + slickness (BOTH bloodroot)
    - "Target now in true lock"
    - "Continue pressure until death"

actual_combat_example:
  round_1: "Doublestab kalmia vernalius → asthma + weariness"
  round_2: "Flay sileris → removes fangbarrier"
  round_3: "Impulse impatience → victim can't focus"
  round_4: "Doublestab curare gecko → paralysis + slickness"
  round_5: "Impulse anorexia → victim can't eat"
  result: "TRUE LOCK - victim cannot cure anything"

required_afflictions:
  - asthma: "Blocks smoking, enables Impulse (kelp cure)"
  - weariness: "Blocks Fitness, enables Impulse (kelp cure - competes with asthma!)"
  - slickness: "Blocks salves (bloodroot cure)"
  - paralysis: "Blocks tree AND all actions (bloodroot cure - competes with slickness!)"
  - impatience: "Blocks focus (delivered via Impulse, NOT venom)"
  - anorexia: "Blocks eating (delivered via Impulse, NOT venom)"
  - fratricide: "Causes impulse mental affs to RELAPSE (argentum cure)"

cure_competition_insight: |
  KEY: Serpent exploits that bloodroot cures BOTH paralysis AND slickness.
  When asthma present, victim can't smoke valerian for slickness.
  So bloodroot must cure both para and slick - but only one per balance.
  DEFENSE: Prioritize paralysis when asthma blocks smoking!
```

### Alternative Kill: Hypnosis + Impulse Combo
```yaml
type: affliction
summary: Use hypnosis for fratricide setup, impulse for mental delivery

steps:
  1: "HYPNOTISE <target>"
  2: "SUGGEST <target> fratricide"     # Sets up relapse mechanic
  3: "SNAP to trigger fratricide"
  4: "Apply asthma + weariness (kelp stack)"
  5: "IMPULSE <target> SUGGEST impatience"  # Now relapses due to fratricide
  6: "Apply paralysis + slickness"
  7: "IMPULSE <target> SUGGEST anorexia"
  8: "Target locked with relapsing impatience"

key_insight: |
  Modern Serpent does NOT use SNAP for impatience/anorexia delivery.
  SNAP is used for fratricide and other hypnosis-only afflictions.
  IMPULSE is used for mental afflictions (requires asthma + weariness).

hypnosis_only_afflictions:
  - fratricide: "Causes impulse affs to relapse"
  - disrupt: "Disrupts equilibrium"
  - amnesia: "Forgets commands"

impulse_delivered_afflictions:
  - impatience: "Blocks focus"
  - anorexia: "Blocks eating"
  - confusion: "Random commands"
  - stupidity: "Disrupts equilibrium skills"

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

---

## Ekanelia (Venom Bonus Afflictions)

```yaml
ekanelia_overview:
  description: |
    Ekanelia is a Serpent skill that ADDS bonus afflictions to BITE attacks
    when specific conditionals are present on the target.
    IMPORTANT: Only works with BITE, not DOUBLESTAB.

  mechanic: |
    When biting with an Ekanelia-enhanced venom, if the target has ALL
    the required conditional afflictions, the bite delivers BOTH the normal
    venom affliction AND the bonus Ekanelia effect. This makes single bites
    extremely powerful when conditions are met.

  tradeoff: |
    Using BITE instead of DST means serpent only applies one venom base,
    but gains potentially 2-3 afflictions total when Ekanelia triggers.

ekanelia_transformations:
  kalmia:
    conditionals: [clumsiness, weariness]
    normal_effect: asthma
    bonus_effect: slickness
    total: "asthma + slickness from single bite"
    notes: "Powerful - gets both lock afflictions in one attack"

  aconite:
    conditionals: [deadening, dementia]
    normal_effect: stupidity
    bonus_effect: paranoia
    total: "stupidity + paranoia from single bite"
    notes: "Double mental pressure"

  monkshood:
    conditionals: [asthma, masochism, weariness]
    normal_effect: disfigurement
    bonus_effect: impatience
    total: "disfigurement + impatience from single bite"
    notes: "Alternative impatience delivery without Impulse requirement"

  curare:
    conditionals: [hypersomnia, masochism]
    normal_effect: paralysis
    bonus_effect: hypochondria
    consumes: hypersomnia
    total: "paralysis + hypochondria (hypersomnia consumed)"
    notes: "Kelp stack + paralysis in one attack"

  voyria:
    conditionals: [anorexia, impatience, vertigo]
    normal_effect: voyria
    bonus_effect: [confusion, disrupted]
    total: "voyria + confusion + disrupted from single bite"
    notes: "Triple affliction from one bite"

  loki:
    conditionals: [confusion, recklessness]
    normal_effect: random
    bonus_effect: [nausea, paralysis]
    total: "random + nausea + paralysis from single bite"
    notes: "Loki becomes PREDICTABLE - guaranteed para + nausea"

  scytherus:
    conditionals: [addiction, nausea]
    normal_effect: scytherus
    bonus_effect: camus
    bonus_conditionals: [haemophilia]
    enhanced_bonus: "additional camus"
    total: "scytherus + camus damage (enhanced with haemophilia)"
    notes: "Heavy damage output when conditions met"
```

---

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
# CRITICAL: Understanding the modern Serpent lock

impulse_prevention:
  description: "Impulse requires asthma + weariness + no sileris"
  defense:
    - "Maintain sileris/fangbarrier defense"
    - "When asthma + weariness present, BOOST ASTHMA PRIORITY"
    - "Asthma and weariness are BOTH kelp cures - you can only cure one at a time"
    - "Curing asthma breaks the impulse requirement"

bloodroot_competition:
  description: "Paralysis and slickness BOTH cure with bloodroot"
  defense:
    - "When asthma present, you can't smoke valerian for slickness"
    - "So bloodroot must handle BOTH paralysis and slickness"
    - "PRIORITIZE PARALYSIS when asthma blocks smoking"
    - "Paralysis blocks ALL actions including tree; slickness only blocks salves"

fratricide_handling:
  description: "Fratricide causes impulse mental affs to RELAPSE"
  defense:
    - "Cure fratricide EARLY with argentum"
    - "If you have asthma + slickness + fratricide, you're approaching lock"
    - "Boost fratricide priority when asthma + slickness present"

tree_timing:
  description: "Tree is your emergency escape - don't wait until locked"
  defense:
    - "Touch tree when APPROACHING lock, not when LOCKED"
    - "Approaching lock = asthma + slickness + (impatience OR anorexia)"
    - "If paralyzed, you CANNOT tree - cure para first"
    - "Tree before paralysis is applied!"

ekanelia_defense:
  description: |
    Ekanelia STACKS bonus afflictions on BITE attacks when conditionals met.
    A single bite can deliver 2-3 afflictions - extremely dangerous.

  critical_combinations:
    kalmia_setup:
      conditionals: [clumsiness, weariness]
      danger: "Single bite gives asthma + slickness (both lock affs)"
      defense: "Cure clumsiness OR weariness to block"

    monkshood_setup:
      conditionals: [asthma, masochism, weariness]
      danger: "Gets impatience without needing Impulse"
      defense: "Cure masochism - blocks both monkshood and curare"

    loki_trap:
      conditionals: [confusion, recklessness]
      danger: "Loki becomes PREDICTABLE - guaranteed nausea + paralysis"
      defense: "Cure confusion OR recklessness before they bite"

  defense_priorities:
    - "Cure masochism early - blocks 2 Ekanelia transformations"
    - "Don't let clumsiness + weariness stack (enables kalmia→slickness)"
    - "Track conditional combos to predict incoming afflictions"
    - "Ekanelia only works with BITE (not DST) - serpent sacrifices double venom"

priority_cures:
  - asthma: "HIGHEST vs Serpent - blocks impulse AND smoking"
  - weariness: "Blocks Fitness, enables impulse (kelp - competes with asthma)"
  - paralysis: "Blocks tree AND all actions - prioritize over slickness when can't smoke"
  - slickness: "Blocks salves - cure with bloodroot OR smoke valerian (if no asthma)"
  - fratricide: "Cure early to prevent impulse relapse loop"
  - impatience: "Restore focus ability"
  - anorexia: "Restore eating ability"
  - sensitivity: "Reduce incoming damage"

dangerous_abilities:
  - doublestab: "Two venoms per attack - can apply asthma+weariness in one hit"
  - bite_ekanelia: "Single bite delivers 2-3 affs when conditionals met"
  - impulse: "Delivers mental afflictions INSTANTLY when asthma+weariness present"
  - fratricide: "Causes impulse mental affs to RELAPSE after cure"
  - hypnosis: "Sets up fratricide via SUGGEST/SNAP"
  - garrote: "Instant kill from stealth"
  - phase: "Makes them untargetable"
  - flay: "Strips sileris/rebounding - opens you to impulse"

avoid:
  - "Letting asthma + weariness stack (enables impulse)"
  - "Letting paralysis + slickness stack when asthma present"
  - "Waiting too long to tree (tree when APPROACHING lock)"
  - "Ignoring fratricide (causes focus lock via relapse)"
  - "Standing still when they're hidden"
  - "Low health with darkshade/scytherus active"
  - "Letting clumsiness + weariness stack (enables Ekanelia kalmia→slickness)"
  - "Ignoring masochism (enables monkshood and curare Ekanelia bonuses)"

recommended_strategy: |
  MODERN SERPENT DEFENSE PRIORITY:

  1. PREVENT IMPULSE: Cure asthma immediately when weariness present.
     Both are kelp - only one cure per balance. Asthma is higher priority.

  2. FRATRICIDE EARLY: If you get fratricide + asthma + slickness,
     boost fratricide priority. Cure it before impatience is delivered.

  3. TREE EARLY: Touch tree when you have asthma + slickness + (impatience OR anorexia).
     This is "approaching lock" - tree NOW before paralysis locks you out.

  4. PARALYSIS OVER SLICKNESS: When asthma blocks smoking, bloodroot must
     cure both para and slick. Prioritize paralysis - it blocks ALL actions.

  5. MAINTAIN SILERIS: Sileris/fangbarrier blocks impulse entirely.
     Serpent will flay it - re-apply immediately.

  6. KELP STACK AWARENESS: Track your kelp stack. If kelp is depleted
     and you have asthma + weariness, you're in serious danger.

anti_serpent_function: |
  See AntiSerpent() in src_new/scripts/levi_ataxia/levi/levi_scripts/algedonic_defense_1.0/001_Anti_Priorities.lua

  Key triggers (priority order):
  1. approachingLock + tree → TREE (asthma + slickness + mental)
  2. impulseLockThreat + tree → TREE (asthma + weariness + no fangbarrier + mental)
  3. fratricide + impulseEnabled + tree → TREE (stops relapse spiral)
  4. fangbarrier down → Re-apply quicksilver
  5. fratricide + scytherus → Cure fratricide NOW (1200 damage per relapse)
  6. Ekanelia prevention (masochism, kalmia setup, loki setup)
  7. Impulse prevention (asthma cure)
  8. fratricide + impulseEnabled → Cure fratricide
```

## Implementation Notes
```
Triggers to watch for:
- "jabs you with a dirk coated in" - venom application
- "bites you viciously" - bite attack (check for Ekanelia bonus!)
- "begins to weave" - hypnosis starting
- "snaps" - suggestions triggering (fratricide setup)
- "impulse" - mental affliction delivery (CRITICAL)
- "disappears into the shadows" - they hid
- "phases out of existence" - they phased
- "flay" - stripping sileris/rebounding

Ekanelia Detection:
- When serpent uses BITE instead of DST, check for Ekanelia bonus
- Track target conditionals - if clumsiness+weariness, kalmia bite = asthma+slickness
- If masochism present, curare/monkshood bites gain bonus effects
- Bite gives fewer base venoms than DST, but more total affs when Ekanelia procs

GMCP considerations:
- Track gmcp.Char.Afflictions for current affs
- Venom tracking via attack messages
- Hidden state not in GMCP, must use triggers
- Track kelp stack count for curing decisions

Priority Swap Triggers (implemented in 029_Priority_Swaps.lua):
- paraAst: asthma + paralysis + slickness → boost paralysis to prio 1
- astWear: asthma + weariness vs Serpent → boost asthma to prio 3
- fratLock: fratricide + asthma + slickness → boost fratricide to prio 4

AntiSerpent Function (299_Anti_Priorities.lua):
- Tree when: canTree AND approachingLock (asthma + slickness + imp/ano)
- Impulse prevention: boost asthma when asthma + weariness present
- Fratricide handling: boost fratricide when asthma + slickness present
- Para vs slick: prioritize paralysis when asthma blocks smoking

Edge cases:
- Double venom means 2 afflictions per attack
- Hypnosis suggestions fire with 4s delay (SNAP)
- IMPULSE delivers instantly when asthma + weariness + no sileris
- Phase makes them untargetable but they can't attack
- Garrote requires hidden AND behind target
- Paralysis and slickness COMPETE for bloodroot cure
- Asthma and weariness COMPETE for kelp cure
- Ekanelia BITE can deliver 2-3 affs when conditionals met (check tAffs)
- Ekanelia curare CONSUMES hypersomnia when triggered
- Ekanelia loki becomes PREDICTABLE (nausea+para) with confusion+recklessness

Venom cure groupings (same herb):
- Kelp: asthma, clumsiness, hypochondria, sensitivity, weariness
- Ginseng: addiction, darkshade, haemophilia, lethargy, scytherus
- Goldenseal: dissonance, dizziness, epilepsy, impatience, stupidity
- Lobelia: agoraphobia, claustrophobia, loneliness, masochism, recklessness, vertigo
- Bloodroot: paralysis, slickness
- Argentum: fratricide (IMPORTANT - cure early vs Serpent)

DEPRECATED: impSnap swap (Serpents no longer deliver impatience via SNAP)
```
