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
- **Impulse mechanics**: See [serpent.md](serpent.md#critical-impulse-mechanics-checked-2026-10-12)
- **Fratricide mechanics**: See [serpent.md](serpent.md#fratricide-mechanics)

---

> Moved verbatim from `CLAUDE.md` on 2026-11-13 (`docs/adrs/002-knowledge-delivery-tiers.md`). Until then every session loaded this text. It is not yet reconciled with the other documents of this subject: where they disagree, check the code or the game source, then correct the wrong one.

## Achaea Classes Reference

**Enemy kill paths: `docs/kill-paths.md`.** Cross-class index of what each class is actually
trying to do to you, with a CONFIRMED / WIKI / ASSUMED confidence tag per entry, plus the
worked method for deriving a kill path from a combat log. Per-class dossiers stay in
`.claude/classes/<class>.md`.

**Do not silently promote ASSUMED to CONFIRMED.** The Sentinel entry read "primary kill:
eviscerate" for a long time; the class killed us with SKULLBASH and eviscerate is not in the
current Skirmishing ability list at all.

Achaea has **26 classes** total: 21 base classes + 4 Elemental Lords + Dragon.

Each class has:
- At most 3 class skills with many abilities each
- Unique bashing (hunting) attacks
- Unique battlerage attacks

### Class Progression
1. **Fledgling** - Initial stage, only 2 of 3 skills, capped at Skilled level
2. **Journeyman** - Level 20+, skills capped at Fabled level
3. **Full Member** - After `EMBRACE CLASS` (Level 30 + House rank 2, or Level 50 without house), gains 3rd skill, no learning limits

**Getting a Class**: Visit Certimene in Delos: `ASK CERTIMENE BECOME <class>`

**Changing Class**:
- **Multiclass**: Can have multiple classes (`HELP MULTICLASS`)
- **Quit Class**: Use `QUIT CLASS` to leave (98% lesson refund before full member, 50% after)

### Base Classes (21)

| Class | Description | Skills |
|-------|-------------|--------|
| Alchemist | Enigmatic figures wielding the power of the ether | Alchemy, Physiology, Formulation/Sublimation |
| Apostate | Evil, necromantic daemon summoners | Evileye, Necromancy, Apostasy |
| Bard | Sword, Song, and Story at the disposal of the Virtuoso | Composition, Bladedance, Sagas (or Woe for Cyrene) |
| Blademaster | Masters of the legendary Two Arts | TwoArts, Striking, Shindo |
| Depthswalker | Fearless manipulators of shadow and time | Aeonics, Shadowmancy, Terminus |
| Druid | Forest-loving metamorphs | Groves, Metamorphosis, Reclamation |
| Infernal | Evil warriors employing necromantic methods (Knight) | Malignity, Oppression, Weaponmastery |
| Jester | Happy-go-lucky pranksters and roguish entertainers | Puppetry, Pranks, Tarot |

**JESTER PvE (v4.7.258).** **BADJOKE TAKES NO TARGET** -- AB 681 is `Syntax: BADJOKE`, "Works
on: Adventurers, denizens, and room", 3.00s equilibrium, 100 mana, and it strips rebounding and
shield from everyone who hears it. The basher sent `badjoke <target>` for its entire existence,
so every shield-break was a malformed command; a rejected command is silent here, which is why
nothing surfaced it. Three boons now handled in `ataxiaBasher_jesterBashing`: **Tough Crowd**
(badjoke also deals psychic damage to all denizens, but stuns AND stupefies US -- so it rides
the eq slot at 2+ denizens on a 12s cooldown behind a 300 mana floor, and `jesterJokeSafe`
refuses while escaping / recovering / in lava / already stunned / at or below `escapeAt`, because
stun blocks every action and stupidity EATS QUEUED COMMANDS; a shielded round where the joke is
unsafe falls back to the rage raze); **Elusive Foolery** (keeps the `slippery` defence up -- the
standard keeper shape, and shrugging off webs/ropes matters in the tower because entanglement is
what strands an escape); **Apostatic** (`fling priestess at <target>` -- syntax confirmed in-tree
from the lock-breakers' `fling fool at me`, NOT guessed -- on a deliberately generous 20s
cooldown because whether a fling consumes an INSCRIBED CARD is unconfirmed, and it is appended
rather than replacing the swing because its balance type is unconfirmed too).
**v4.7.385 corrections:** AB 605 says the priestess fling costs 3.00s of BALANCE, the same as bop, so
appending it beside the swing made one of them a refusal every card round. It now REPLACES the swing
and is **off by default** (`ataxiaBasher.jesterPriestess = true` opts in; user: "account for it,
dont use it for now"). **Motley Bop** keeps bopping below 50% with 2+ denizens (the splash beats the
execute bonus). **Seclusion** (hermit = cure all + 200% health, once per ripple): `activate hermit`
rides the holding room's first `down`, and at the panic floor `S._maybeSeclusion` flings it ahead of
Roll Hide, then walks back down on landing. Full table in `.claude/classes/jester.md`.
| Magi | Masters of the four elements and crystalline vibrations | Crystalism, Elementalism, Artificing |
| Monk | Forges mind, body, and spirit into a unified whole | Tekura/Shikudo, Kaido, Telepathy |
| Occultist | Chaos-loving summoners of extra-planar entities | Domination, Tarot, Occultism |
| Paladin | Valorous warriors with eagle companion (Knight) | Excision, Valour, Weaponmastery |
| Pariah | Cheaters of Death and bringers of plagues | Memorium, Pestilence, Charnel |
| Priest | Holy warriors with a fearsome guardian angel | Spirituality, Devotion, Zeal |
| Psion | Weavers of Aldar magic | Weaving, Psionics, Emulation |
| Runewarden | Mystic warriors who employ runic lore (Knight) | Runelore, Discipline, Weaponmastery |
| Sentinel | Metamorphing forest rangers with animal companions | Woodlore, Metamorphosis, Skirmishing |
| Serpent | Masters of venoms and subterfuge (see Ekanelia below) | Subterfuge, Venom, Hypnosis |
| Shaman | Mystical users of Vodun dolls, curses, and bound spirits | Vodun, Curses, Spiritlore |
| Sylvan | Forest-lovers who blend mastery of three elements | Propagation, Groves, Weatherweaving |
| Unnamable | Frenzied mutant warriors for Chaos (Knight) | Dominion, Anathema, Weaponmastery |

### Elemental Lords (4 separate classes)
- Airlord, Earthlord, Firelord, Waterlord

### Dragon (End-Game Class)

**RED DRAGON SCORCH applies INHIBIT (v4.7.266).** AB 2299: `SCORCH <target>`, 18 rage, 25.00s
cooldown, denizens only, "Gives denizen affliction: Inhibit". Trigger
`denizen_attacks_misc_lines/027` records it into the denizen-state model (`BR_AFFS.inhibit`, the
same state Monk Ripplestrike and the Infernal Necrotic Aura proc apply) and announces it on PT
when `ataxia.settings.raid.enabled`. Recording matters twice over: it stops a second inhibit being
spent on a mob that already has one, and inhibit is one of the four PHYSICAL triggers for
Depthswalker's `chrono degenerate` (v4.7.265) -- so a scorching dragon sets up an aeonic cash-in
for a Depthswalker in the party. **Not in any rotation**: `GDRAGON_BR` is Golden-specific, so
there is no red-dragon rotation to add it to and it remains a manual cast.

**THE DRAGON BASH ROUND IS ONE ATTACK (v4.7.434-439, user-directed).** `ataxiaBasher_dragonBashing`
(`basher/002`) sends the FIRST that applies: Krenindalan Storm `breathstorm` (once in each room, v4.7.442) > Spark Extant `incantation` (2+ denizens, v4.7.440) > Draconic Sweep `tailsweep` / Draconic Rampage
`trample` (proc ready, 2+ denizens; `ataxiaBasher_dragonAoePick`, tailsweep first, a held round
replays first) > blast (`bash blast` or Might of Sycaerunax) > incantation (above 5% willpower) >
`wield dirk;jab` > whip > rend (Organ Piercer) > gut. The blast command is `blast;summon <breath>`,
or `summon;blast;summon` when the breath is down -- SUMMON IS OFF-EQUILIBRIUM for this user (a
trait) -- and Might of Sycaerunax drops the trailing summon. Incantation and blast both use
equilibrium, which is why a round never pairs them. The low-willpower jab is read per round; the
prompt no longer rewrites `jabBash`/`dragonIncant` (that latch jabbed forever, v4.7.437). Proc
confirmations: `highlighting/033` (Rampage) and `/072` (Sweep) match the FIRST wrapped row only.
Full detail: `.claude/classes/dragon.md` (`basher_round`, `mnemosyne_boons`).

- Unlocked at level 99
- 6 color variants: Red, Black, Silver, Gold, Blue, Green
- Each color has unique breath weapon and battlerage

### Class Specializations

**Knight Classes** (Infernal, Paladin, Runewarden, Unnamable) - Weaponmastery specs:
- **DWC (Dual Wield Cutting)** - Double venom application, fast attacks
- **DWB (Dual Wield Blunt)** - Double breaks, best limb prep
- **SnB (Sword and Board)** - Impale/stun, shield abilities, damage mitigation
- **2H (Two-Handed)** - Best damage, passive paralysis curing, strip rebounding/shield

**Monk**:
- **Tekura** - Unarmed martial arts (default)
- **Shikudo** - Staff-based combat (requires Trans Tekura to unlock)

**Alchemist**:
- **Formulation** - Default alchemical field
- **Sublimation** - Alternative field using Hashan's Wellspring

**Metamorphosis** (Druid/Sentinel):
- **Druid-exclusive morphs**: Hydra, Wyvern
- **Sentinel-exclusive morphs**: Jaguar, Basilisk

**Bard**:
- **Sagas** - Default third skill
- **Woe** - Exclusive to Cyrene

---
