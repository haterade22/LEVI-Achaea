# Achaea Class Documentation

This directory contains per-class combat documentation for the LEVI-Achaea system.

## Classes (26 Total)

### Base Classes (21)
- [Alchemist](alchemist.md)
- [Apostate](apostate.md)
- [Bard](bard.md)
- [Blademaster](blademaster.md)
- [Depthswalker](depthswalker.md)
- [Druid](druid.md)
- [Infernal](infernal.md) (Knight)
- [Jester](jester.md)
- [Magi](magi.md)
- [Monk](monk.md)
- [Occultist](occultist.md)
- [Paladin](paladin.md) (Knight)
- [Pariah](pariah.md)
- [Priest](priest.md)
- [Psion](psion.md)
- [Runewarden](runewarden.md) (Knight)
- [Sentinel](sentinel.md)
- [Serpent](serpent.md)
- [Shaman](shaman.md)
- [Sylvan](sylvan.md)
- [Unnamable](unnamable.md) (Knight)

### Elemental Lords (4)
- [Airlord](airlord.md)
- [Earthlord](earthlord.md)
- [Firelord](firelord.md)
- [Waterlord](waterlord.md)

### End-Game
- [Dragon](dragon.md)

## Document Structure

Each class document follows this YAML-structured template (see [_template.md](_template.md)):

### Metadata
- **Type**: Base Class | Knight | Elemental Lord | Dragon
- **Combat Style**: Affliction | Limb | Hybrid | Damage
- **Difficulty**: Easy | Medium | Hard
- **Lock Affliction**: Class-specific affliction needed to complete a lock

### Sections
- **Skills**: The 3 class skill trees
- **Specializations**: Sub-classes if applicable (Knight specs, Monk Tekura/Shikudo, etc.)
- **Kill Routes**: Primary and alternative kill methods with step-by-step instructions
- **Offensive Abilities**: Key attacks and their effects (YAML format)
- **Defensive Abilities**: Key defenses (YAML format)
- **Passive Cures**: Abilities that automatically cure afflictions
- **Limb Strategy**: If the class uses limb-based combat
- **Bashing (PvE)**: Attack commands and battlerage abilities
- **Fighting Against This Class**: Priority cures, dangerous abilities, strategy

### Implementation Notes
- Trigger patterns to watch for
- GMCP considerations
- Edge cases

## Class-Specific Lock Afflictions

Different classes need different afflictions to complete a "true lock":

| Lock Aff | Classes |
|----------|---------|
| Weariness | Blademaster, Druid, Infernal, Monk, Paladin, Unnamable, Runewarden, Sentinel, Serpent, Airlord, Waterlord, Earthlord, Firelord |
| Voyria | Apostate, Pariah, Bard, Priest |
| Stupidity | Alchemist |
| Haemophilia | Magi, Sylvan |
| Recklessness | Depthswalker |
| Confusion | Psion |
| Paralysis | Jester, Occultist, Shaman (already in base lock) |

## Combat Concepts

### Lock Types
See **[lock_types.md](lock_types.md)** for comprehensive lock documentation including:
- Softlock, Venomlock, Truelock/Hardlock
- Focuslock (mental affliction stacking)
- Riftlock, Salvelock (limb-based)
- Sleeplock, Aeonlock (timing/control-based)

### Affliction Stacking
Stack multiple afflictions that share the same cure herb to overwhelm curing:
- **Kelp**: asthma, clumsiness, sensitivity, weariness, healthleech, parasite, rebbies
- **Ginseng**: addiction, darkshade, haemophilia, lethargy, nausea, scytherus, flushings
- **Goldenseal**: impatience, stupidity, dizziness, epilepsy, depression, shyness, horror
- **Bloodroot**: paralysis, slickness, pyramides
- **Lobelia**: recklessness, vertigo, masochism, guilt, spiritburn, tenderskin
- **Ash**: confusion, dementia, hallucinations, hypersomnia, paranoia
- **Bellwort**: retribution, timeloop, peace, justice, lovers, generosity, diminished

### True Lock Components
1. **Asthma** - blocks smoking (cured by Kelp)
2. **Anorexia** - blocks eating (cured by applying Epidermal or Focus)
3. **Slickness** - blocks applying (cured by Bloodroot or smoking Valerian)
4. **Paralysis** - blocks tree tattoo (cured by Bloodroot)
5. **Impatience** - blocks focus (cured by Goldenseal)
6. **Class-specific** - blocks passive cures (see table above)

## References
- Lock types reference: See [lock_types.md](lock_types.md)
- **Serpent lock strategy (2024)**: See [lock_types.md](lock_types.md#serpent-specific-lock-strategy-updated-2024)
- Complete venom list: See [serpent.md](serpent.md) - Complete Venom Reference section
- **Impulse mechanics**: See [serpent.md](serpent.md#critical-impulse-mechanics-updated-2024)
- **Fratricide mechanics**: See [serpent.md](serpent.md#fratricide-mechanics)
