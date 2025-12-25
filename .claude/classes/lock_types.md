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

## Defensive Notes

### Breaking Locks
1. **Softlock**: Focus → eat bloodroot → eat kelp
2. **Venomlock**: Focus → eat bloodroot (para or slick) → continue curing
3. **Focuslock**: Hope Focus randomly cures anorexia
4. **Truelock**: External help required
5. **Riftlock**: Smoke valerian → mend arms → rift herbs
6. **Sleeplock**: Allies wake you, or Insomnia/Gypsum defences
7. **Aeonlock**: Must cure asthma first, then smoke for aeon

### Prevention Priority
- Keep asthma cured when possible (blocks smoking)
- Don't let slickness + anorexia stick together
- Watch for arm breaks if they're building riftlock
- Maintain Insomnia defence against sleep classes
