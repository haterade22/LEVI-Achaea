# Achaea Lock Types Reference

Comprehensive reference for all lock types in Achaea PvP combat.

## Lock Overview

Locks prevent an opponent from curing by blocking all available cure methods simultaneously. The severity and difficulty of escaping increases with each lock type.

---

## Softlock

**The entry-level lock - blocks three cure methods.**

```yaml
afflictions:
  asthma:
    effect: "Prevents smoking pipes"
    cure: "Eating Aurum/Kelp"
  anorexia:
    effect: "Prevents eating herbs"
    cure: "Applying Epidermal or Focusing"
  slickness:
    effect: "Prevents applying salves"
    cure: "Eating Magnesium/Bloodroot or smoking Realgar/Valerian"

escape_route: "Focus to cure anorexia, then eat bloodroot for slickness, then eat kelp for asthma"
vulnerability: "Focus is available to break"
```

---

## Venomlock

**Softlock plus paralysis - blocks tree tattoo escape.**

```yaml
afflictions:
  paralysis:
    effect: "Prevents movement and touching Tree tattoo"
    cure: "Eating Magnesium/Bloodroot"
  asthma:
    effect: "Prevents smoking pipes"
    cure: "Eating Aurum/Kelp"
  anorexia:
    effect: "Prevents eating herbs"
    cure: "Applying Epidermal or Focusing"
  slickness:
    effect: "Prevents applying salves"
    cure: "Eating Magnesium/Bloodroot or smoking Realgar/Valerian"

escape_route: "Focus to cure anorexia, then eat bloodroot (cures para OR slick)"
vulnerability: "Focus is still available"
```

---

## Truelock / Hardlock

**The complete lock - all cure methods blocked.**

```yaml
afflictions:
  paralysis:
    effect: "Prevents Tree tattoo"
    cure: "Eating Magnesium/Bloodroot"
  asthma:
    effect: "Prevents smoking pipes"
    cure: "Eating Aurum/Kelp"
  anorexia:
    effect: "Prevents eating herbs"
    cure: "Applying Epidermal or Focusing"
  slickness:
    effect: "Prevents applying salves"
    cure: "Eating Magnesium/Bloodroot or smoking Realgar/Valerian"
  impatience:
    effect: "Prevents using Focus"
    cure: "Eating Plumbum/Goldenseal"

additional_afflictions:
  - weariness: "Prevents class-specific active/passive cures"
  - stupidity: "Prevents class-specific cures, lowers cure chances"
  - recklessness: "Lowers cure chances"
  - class_specific: "See lock affliction table below"

escape_route: "None without external help (ally curing, divine intervention)"
notes: "Once achieved, target cannot escape without outside assistance"
```

---

## Focuslock

**Alternative to Truelock - uses mental affliction stacking instead of impatience.**

```yaml
afflictions:
  paralysis:
    effect: "Prevents Tree tattoo"
    cure: "Eating Magnesium/Bloodroot"
  asthma:
    effect: "Prevents smoking pipes"
    cure: "Eating Aurum/Kelp"
  anorexia:
    effect: "Prevents eating herbs"
    cure: "Applying Epidermal or Focusing"
  slickness:
    effect: "Prevents applying salves"
    cure: "Eating Magnesium/Bloodroot or smoking Realgar/Valerian"

strategy: |
  Instead of impatience, stack multiple mental afflictions (goldenseal cures).
  When opponent uses Focus, it cures a random mental aff instead of anorexia.

mental_stack_options:
  - stupidity
  - dizziness
  - epilepsy
  - impatience
  - shyness
  - depression

escape_chance: "Low - Focus may randomly cure anorexia, but odds decrease with more mental affs"
```

---

## Riftlock

**Limb-based lock - prevents rifting herbs.**

```yaml
afflictions:
  broken_arms:
    count: 2
    effect: "Prevents out-rifting herbs from rift"
    cure: "Apply mending to arms"
  slickness:
    effect: "Prevents applying salves (can't mend arms)"
    cure: "Eating Magnesium/Bloodroot or smoking Realgar/Valerian"
  asthma:
    effect: "Prevents smoking pipes"
    cure: "Eating Aurum/Kelp"

helper_affliction:
  addiction:
    venom: "Vardrax"
    effect: "Forces opponent to eat whatever is already in their hands"
    synergy: "With broken arms, they can't rift more herbs after eating held ones"

escape_route: "Smoke valerian for slickness, apply mending to arms, rift herbs"
vulnerability: "Requires maintaining broken arms AND slickness"
```

---

## Salvelock

**Enhanced Riftlock - level 2+ breaks prevent Restore.**

```yaml
afflictions:
  mangled_arms:
    count: 2
    level: "Level 2 or higher (mangled)"
    effect: "Prevents out-rifting herbs AND cannot use Restore to heal limbs"
    cure: "Apply mending to arms (requires multiple applications)"
  slickness:
    effect: "Prevents applying salves"
    cure: "Eating Magnesium/Bloodroot or smoking Realgar/Valerian"
  asthma:
    effect: "Prevents smoking pipes"
    cure: "Eating Aurum/Kelp"

helper_affliction:
  addiction:
    venom: "Vardrax"
    effect: "Forces opponent to eat whatever is already in their hands"

notes: |
  Level 2 breaks (mangled) cannot be healed with Restore ability.
  Must apply mending multiple times to heal mangled limbs.
  With slickness, they cannot apply mending at all.
```

---

## Sleeplock

**Timing-based lock - keeps opponent asleep.**

```yaml
mechanic:
  step_1:
    action: "First Sleep/Delphinium"
    effect: "Strips Insomnia affliction (prevents falling asleep)"
  step_2:
    action: "Second Sleep/Delphinium"
    effect: "Strips Gypsum/Kola defence (allows instant waking)"
  step_3:
    action: "Third Sleep/Delphinium"
    effect: "Puts opponent to sleep"

timing: "All three must be applied in very rapid succession"
follow_up: |
  Once asleep, waking takes long enough that you can:
  - Continue afflicting Sleep/Delphinium to keep them asleep
  - Apply other locking afflictions while they're helpless
  - Set up for a kill

counters:
  - "Insomnia defence"
  - "Gypsum/Kola defence"
  - "Allies waking you"
```

---

## Aeonlock

**Time-manipulation lock - severely slows opponent.**

```yaml
afflictions:
  aeon:
    effect: "Allows only one action at a time on a lengthy balance"
    cure: "Smoking Cinnabar/Elm"
  asthma:
    effect: "Prevents curing Aeon by smoking"
    cure: "Eating Aurum/Kelp"

strategy: |
  With Aeon + Asthma, opponent can only eat one herb per lengthy balance.
  Stack additional Aurum/Kelp afflictions to ensure Asthma remains stuck:
  - Clumsiness
  - Sensitivity
  - Weariness
  - Healthleech

result: "Opponent is so slowed they cannot keep up with affliction pressure"
```

---

## Lock Affliction by Class

Different classes need additional afflictions to block their passive cures:

| Lock Affliction | Classes | Blocks |
|----------------|---------|--------|
| Weariness | Blademaster, Druid, Infernal, Monk, Paladin, Unnamable, Runewarden, Sentinel, Serpent, Airlord, Waterlord, Earthlord, Firelord | Various passive cures |
| Voyria | Apostate, Pariah, Bard, Priest | Sip-based healing |
| Stupidity | Alchemist | Transmutation cures |
| Haemophilia | Magi, Sylvan | Blood-based cures |
| Recklessness | Depthswalker | Shadow cures |
| Confusion | Psion | Mental cures |
| Paralysis | Jester, Occultist, Shaman | Already in base lock |

---

## Cure Herb Quick Reference

```yaml
kelp_aurum:
  cures: [asthma, clumsiness, hypochondria, sensitivity, weariness, healthleech, parasite, rebbies]

bloodroot_magnesium:
  cures: [paralysis, slickness, pyramides]

ginseng:
  cures: [addiction, darkshade, haemophilia, lethargy, nausea, scytherus, flushings]

goldenseal_plumbum:
  cures: [dizziness, epilepsy, impatience, shyness, stupidity, depression, shadowmadness, mycalium, sandfever, horror, fulminated]

lobelia:
  cures: [agoraphobia, guilt, spiritburn, tenderskin, claustrophobia, loneliness, masochism, recklessness, vertigo]

ash:
  cures: [confusion, dementia, hallucinations, hypersomnia, paranoia]

bellwort:
  cures: [retribution, timeloop, peace, justice, lovers, generosity, diminished]
```

---

---

## Serpent-Specific Lock Strategy (Updated 2024)

### Modern Serpent Lock Mechanics

Serpents use **Impulse** (not SNAP) to deliver mental afflictions. Understanding this is critical for defense.

```yaml
impulse_requirements:
  - "Victim has NO sileris/fangbarrier defense"
  - "Victim HAS asthma affliction"
  - "Victim HAS weariness affliction"

serpent_lock_progression:
  phase_1_kelp_setup:
    attack: "DST target kalmia vernalius"
    result: "asthma + weariness (both kelp cures)"
    note: "Victim can only cure ONE per eat balance"

  phase_2_defense_strip:
    attack: "Flay sileris"
    result: "Removes fangbarrier, opens victim to Impulse"

  phase_3_impulse_delivery:
    attack: "IMPULSE target SUGGEST impatience"
    result: "Victim cannot focus"
    note: "Instant delivery when requirements met"

  phase_4_bloodroot_competition:
    attack: "DST target curare gecko"
    result: "paralysis + slickness (both bloodroot cures)"
    note: "With asthma, victim can't smoke valerian for slickness"

  phase_5_lock_complete:
    attack: "IMPULSE target SUGGEST anorexia"
    result: "TRUE LOCK achieved"

fratricide_mechanic:
  description: "Fratricide causes impulse mental affs to RELAPSE"
  delivery: "SUGGEST target fratricide via Hypnosis SNAP"
  effect: |
    After victim focuses to cure impatience, fratricide
    causes it to immediately relapse. Creates focus lock.
```

### Cure Competition (Critical)

```yaml
bloodroot_competition:
  cures: [paralysis, slickness]
  problem: |
    When asthma blocks smoking, bloodroot must cure BOTH.
    Only one cure per eat balance.
  defense: "Prioritize PARALYSIS - it blocks ALL actions including tree"

kelp_competition:
  cures: [asthma, weariness]
  problem: |
    Both afflictions enable Impulse.
    Only one cure per eat balance.
  defense: "Prioritize ASTHMA - breaks Impulse requirement AND restores smoking"
```

### Defense Priority vs Serpent

```yaml
priority_order:
  1_prevent_impulse:
    condition: "asthma + weariness present"
    action: "Boost asthma priority (swap: astWear)"
    reason: "Curing asthma breaks Impulse requirement"

  2_fratricide_early:
    condition: "fratricide + asthma + slickness"
    action: "Boost fratricide priority (swap: fratLock)"
    reason: "Prevent impulse mental relapse loop"

  3_tree_early:
    condition: "asthma + slickness + (impatience OR anorexia)"
    action: "Touch tree immediately"
    reason: "This is 'approaching lock' - tree before paralysis"

  4_para_over_slick:
    condition: "asthma + paralysis + slickness"
    action: "Boost paralysis priority (swap: paraAst)"
    reason: "Para blocks ALL actions; can't smoke valerian anyway"

  5_sileris:
    action: "Maintain sileris/fangbarrier"
    reason: "Blocks Impulse entirely"
```

---

## Defensive Notes

### Breaking Locks
1. **Softlock**: Focus → eat bloodroot → eat kelp
2. **Venomlock**: Focus → eat bloodroot (para or slick) → continue curing
3. **Focuslock**: Hope Focus randomly cures anorexia
4. **Truelock**: External help required
5. **Riftlock**: Smoke valerian → mend arms → rift herbs
6. **Sleeplock**: Allies wake you, or Insomnia/Gypsum defences
7. **Aeonlock**: Must cure asthma first, then smoke for aeon
8. **Serpent Lock (Modern)**: See Serpent-specific section above

### Prevention Priority
- Keep asthma cured when possible (blocks smoking AND enables Impulse)
- Don't let slickness + anorexia stick together
- Watch for arm breaks if they're building riftlock
- Maintain Insomnia defence against sleep classes
- **VS SERPENT**: Cure asthma when weariness present (breaks Impulse)
- **VS SERPENT**: Cure fratricide early (prevents mental relapse)
- **VS SERPENT**: Tree when approaching lock (asthma + slickness + impatience/anorexia)
- **VS SERPENT**: Prioritize paralysis over slickness when asthma blocks smoking
