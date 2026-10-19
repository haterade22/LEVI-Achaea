# Magi

## Metadata
- **Type**: Base Class
- **Combat Style**: Affliction | Damage (Hybrid)
- **Difficulty**: Hard
- **Lock Affliction**: Haemophilia (prevents clotting, disrupts cure system)
- **Offense System**: `magi.offense` namespace (`004_Magi_Offense.lua`)
- **Dispatch**: `zz` (salve), `xx` (fire), `vv` (water, which has no branch and runs the fire tree), `cc` (lock) and `sr` (group) each set a mode and call `magi.offense.dispatch()`; `mm <mode>` sets the mode without attacking
- **Players' practice**: Tabethys's core rotation (opener, mudslide, focus lock, water finisher) is curated in its own section below. Since v4.7.421 the `ww` key runs it (mode `waterroute`; see "The water route (ww, v4.7.421)").

**Confidence tags** on text corrected or added on 2026-10-12: **WIKI** = `kb/raw/wiki/*.wiki` (in-game `AB` wins where they differ); **CONFIRMED** = the game's own record (`AFFLICTION SHOW` in `kb/raw/live/affliction_show/`, HELP in `kb/raw/help/`) or a logged line; **PLAYER** = Tabethys (`kb/raw/players/magi-tabethys-2026-10-12.txt`); **UNVERIFIED** = nothing in `kb/` backs it yet. Untagged rows in the older reference tables were not re-checked, and not all of them come from the wiki: on 2026-10-12 the Firelash, Shalestorm, Stormhammer, Magmasphere, Scintilla and Horripilation rows were found to give figures or effects that `kb/raw/wiki` does not (corrected below). Treat any other untagged row as UNVERIFIED.

## Skills

### Elementalism
Elemental magic channelling fire, water, air, and earth. Core offensive skill. Requires opening channels to elemental planes (200 mana each, willpower maintenance cost). Channels can be attacked — protect with Fortification or Binding.

### Crystalism
Vibrational crystal magic using refined crystal shapes embedded in rooms. Provides room control, afflictions, and utility. Requires a Master Crystal (in House/City hall) to refine shapes. Vibrations persist in rooms until dampened or destroyed.

### Artificing
Staff creation and crystal enhancement. The Magi staff is the primary combat weapon — holds up to 4 crystals that modify staffcast behavior. Also includes elemental summoning treaties.

---

## Resonance System

The core combat mechanic. **Certain** Elementalism spells (not all) build resonance with the planes they channel: none, minor, moderate, major (our code counts 0-3). The wiki files ten of them under "Resonant Spells" (Gust, Firelash, Freeze, Geyser, Dehydrate, Fulminate, Bombard, Mudslide, Magma, Transfix; Elementalism.wiki:269) and says the resonant spells "are listed under AB ELEMENTALISM" (:62). AB ELEMENTALISM has not been captured and nothing in `kb/` gives the step, so the step is not CONFIRMED. Tabethys's log of a kill (`kb/raw/logs/2026-10-19_tabethys_magi-group_kalys_o6UKnyyy.txt`) supports **one level per channelled plane per cast** for earth, fire and water (PLAYER: read from their system's echoes of lines it gags; air, the starting levels and any fade are not shown). As a plane grows into a level, "the last target of the spell you cast to cause that increase" suffers that level's effect (WIKI :62): the effect lands on whoever the raising spell hit, which need not be `target`. EMANATION needs major resonance with one plane and clears that plane (WIKI :242). ERODE lowers all resonance a level when it strips a defence, unless MAINTAIN is given (WIKI :74), and SHALESTORM drains earth (WIKI :194).

Two limits, both WIKI (:62): resonance "is fleeting and will fade over time" (how fast is not recorded), and it is "only generated if your spell is targeted against an adventurer who is directly within your location when it resolves", so there is none in PvE and none from a ranged firelash. `RESONANCE VERBOSITY <NONE|LOW|HIGH>` (default low) sets which resonance messages you see. Our resonance triggers (`general/022`) read those lines, so NONE would blind them; which lines each setting shows is UNVERIFIED.

### Resonance Levels & Passive Effects
```yaml
# WIKI (Elementalism.wiki:62). Each effect lands as the plane GROWS into that level.
# "ablaze" and "burning" are one affliction (CONFIRMED: AFFLICTION SHOW ablaze answers "Burning").
air:
  1 (minor): "asthma"
  2 (moderate): "sensitivity"
  3 (major): "healthleech"
  emanation: "paralysis + dizziness + a short stun; asthma instead of dizziness if already dizzy"

earth:
  1 (minor): "breaks a random limb (always an unbroken one)"
  2 (moderate): "a short stun + paralysis"
  3 (major): "cracked ribs (the base affliction only; never adds to the count)"
  emanation: "calcified torso; slain outright if the target has serious internal trauma"

fire:
  1 (minor): "strips temperance and stops it being raised again"
  2 (moderate): "scalded; if already scalded, ablaze + damage"
  3 (major): "blistered; if already blistered, a stack of ablaze"
  emanation: "two stacks of ablaze"

water:
  1 (minor): "frostbite; if already frostbitten, damage"
  2 (moderate): "stuttering + cold damage"
  3 (major): "anorexia"
  emanation: "a level of freeze (or the insulation defence stripped) + disrupted + stuttering"

# Every emanation deals damage (WIKI :242).
# What our emanation triggers record (enamation/001-004; all four fire on this user's wrap since
# v4.7.420): the afflictions above, except the air stun, the earth emanation's calcified torso
# (only 026_Calcify's own torso line records one) and, in V3, the fire emanation's second stack.
# See Trigger Architecture.
# Corrected 2026-10-12: this block had fire one level off (scalded at minor, blistered at
# moderate, "burning +2" at major), water emanation as "hypothermia setup" and earth
# emanation as calcified skull. Our trigger (general/022_Resonance_Afflictions.lua) already
# followed the wiki's fire ladder. Minor fire's temperance strip is most likely
# general/014_Temperance.lua, judged by its wording: its line is uncaptured, and ERODE, the other
# temperance stripper (WIKI :74), has its own line (magi_offense_tracking/015_Erode.lua).
```

### Resonance Budgeting
- EMANATION needs major resonance and **clears** that plane (WIKI :242): the way to spend a capped plane on purpose.
- **A cast at a capped plane is not always waste.** `selectBurningSpell` treats it as waste: its fulminate, its two conditional dehydrates and its magma need `fireWillBurn` (fire 1-2), it emanates fire at 3, and its default dehydrate is reached only below fire 3. P2's meteorite (flaming only at fire 1-2) and `selectFallback`'s magma (fire under 3) avoid it too. The rest of the tree does not: P9's magma (fire and water mode), lock and salve mode's magma and lock mode's fulminate have no fire test, so each goes out at capped fire whenever its other conditions hold (for P9's, an unscalded target). Tabethys casts FULMINATE at fire 3 on purpose, for the fulminated and the asthma (minor air) it brings (PLAYER, see the rotation section). What a cast at major does to that plane (nothing, the major effect again, or only holding off the fade) is not stated anywhere in `kb/` (UNVERIFIED). The rule this page used to state ("Never waste capped resonance" — "if fire==3, emanate fire before casting more fire spells") is the code's choice, not a game rule.
- A spell builds every plane it channels (magma = earth + fire, mudslide = earth + water, dehydrate = fire + water, fulminate = air + fire, freeze = air + water; channels WIKI). Each cast raises each plane it channels by one level: Tabethys's log of a kill (2026-10-19, `kb/raw/logs/2026-10-19_tabethys_magi-group_kalys_o6UKnyyy.txt`) shows it from no resonance, magma then dehydrate twice (PLAYER; see "In play" below).
- ERODE without MAINTAIN drops ALL resonance a level on a successful strip (WIKI :74); our meteorite fallback sends `cast erode at <t> maintain`.

### Resonance from GMCP
`get_resonance()` (`mage/001_Resonance.lua`) fills `magi.resonance = {air, fire, earth, water}` with 0-3 on every `gmcp.Char.Vitals` and again in `dispatch()`. Since v4.7.419 it first sets all four planes to 0. Then, for each `gmcp.Char.Vitals.charstats` entry whose **lowercased** text contains `rair` / `rfire` / `rearth` / `rwater`, it reads the text between the first and second colon (`minor` / `moderate` / `major` = 1 / 2 / 3, anything else 0). When charstats is missing it returns with every plane at 0. Before v4.7.419 the match was case-sensitive, nothing reset a plane whose entry was absent, and a missing charstats threw: a capitalised key would have left every plane at 0, and a vanished entry would have kept its last level for good.
**The key format is UNVERIFIED**: no capture of charstats with resonance up exists in `kb/` or the tests, and the other charstats keys our code reads (`Stance`, `Kai`, `Rage`, ... in `update_stuff/004_ataxia_Vitals_Update.lua`) are capitalised. One captured `gmcp.Char.Vitals.charstats` with resonance up settles it (kb/CONFLICTS.md).

---

## Elementalism Spells (Complete Reference)

### Offensive Spells (Resonance-Building)

| Spell | Elements | EQ | Afflictions / Effects | Notes |
|-------|----------|----|-----------------------|-------|
| **Firelash** | Fire | eq (the wiki gives no figure) | Sets the target ablaze when cast in the room (WIKI :292); our trigger adds a burn on its line (`021_Spell_Outcomes`) | Damage from the room or an adjacent one; melts icewalls. Only the in-room cast builds resonance (WIKI :62) |
| **Freeze** | Air/Water | 3.0s (targeted) | Strips insulation if it is up, then shivering, then frozen: one stage per cast (WIKI :304) | Damage when it lands; a heat vibration can stop it. **No limb requirement** in the wiki or from Tabethys: the "requires shivering + 1 broken limb for frozen" this row used to give is our P10 gate (`countMendingAffs() >= 1`), not a game rule. Hypothermia is a separate spell |
| **Dehydrate** | Fire/Water | 2.3s | Nausea + weariness + dehydrated (45 s, lowers fire resistance, CONFIRMED). Already weary: a stack of burning. Already nauseous: a stack of freeze. Both: burning only (WIKI :328) | `015_Dehydrate.lua` follows this; until v4.7.419 it also recorded frozen on a weary target |
| **Fulminate** | Air/Fire | 2.4s | fulminated; epilepsy if already fulminated; paralysis if both (WIKI :340) | Lightning bolt; damage. **No burning** (our trigger added a burn per hit until v4.7.419) |
| **Bombard** | Air/Earth | 2.4s | clumsiness | Rock barrage. The wiki's syntax is `CAST BOMBARD <target>` with no AT; we send `cast bombard at <target>` (whether the game accepts both is UNVERIFIED) |
| **Mudslide** | Earth/Water | 2.3s | slickness + prone + damage (WIKI :364) | Knockdown; key lock spell. At earth 1 + water 2 its resonance adds a short stun + paralysis (moderate earth) and anorexia (major water): Tabethys's "par, sli, ano, prone" |
| **Magma** | Earth/Fire | 2.3s | scalded (20 s, CONFIRMED) + damage | "Can't re-magma while scalded" is UNVERIFIED (not in the wiki). Our tree skips magma while `st.scalded` is set, except in `selectBurningSpell`'s earth builder (at earth 1) and `selectFallback`'s resonance builder (with shalestorm up, earth and fire under 3). Both run only in fire and water mode, after P9 has found the target scalded, so each casts magma at a scalded target |
| **Transfix** | Air/Fire | 3.0s | stupidity (if moderate+ resonance) | Mesmerization; removes blindness |
| **Gust** | Air | 3.0s | none (knockback) | Directional push or room clear |
| **Geyser** | Earth/Fire/Water | 3.0s | none (disruption) | Removes flying/treed targets |

### Higher-Order Spells

| Spell | Elements | EQ | Requirements | Effects |
|-------|----------|-----|-------------|---------|
| **Hypothermia** | Air/Water | 2.6s | Target frozen | They cannot cure frozen (CONFIRMED: "Prevents curing the freezing affliction."; cured by restoration to the body). Tabethys casts it only when glaciate would not kill |
| **Shalestorm** | Earth | 2.4s | None in the wiki; we cast it at earth ≥ 2 (P13, group mode, `selectFallback`) | Pummels the target periodically: damage and a random limb break if unshielded, else it breaks the shield. Every two pummels lower earth a level, and it stops when earth is gone (WIKI :194) |
| **Firestorm** | Air/Fire | 4.0s | None | Room-wide spreading fire; no caster immunity |
| **Conflagrate** | Fire | 2.35s | Two or more ablaze stacks (WIKI :230); our gate also wants fire ≥2 | Sets conflagrated flag; periodic damage until every ablaze stack is gone |
| **Glaciate** | Air/Water | 3.0s | Target already frozen: the only requirement the wiki states (WIKI :218) | "terrible damage upon those that are already frozen": damage, not an execute; no figure or kill clause is recorded. Our P3 also requires hypothermia and water ≥2 + air ≥2 (see Decision Tree) |
| **Emanation** | Per element | 2.4s | Major resonance with that plane | Clears that plane; effects in the Resonance block above |
| **Convergence** | All four | 2.9s | Moderate resonance in all 4, dissonance stage 4 | Marks target; bypasses shields |
| **Purity** | Water | 3.0s | Major water resonance | Removes resonance; grants affliction immunity |

### Staffcast Abilities (from Elementalism)

| Ability | Elements | EQ | Requirements | Effects |
|---------|----------|-----|-------------|---------|
| **Destroy** | Fire | 3.6s | Conflagrated + target ≤40% HP | **Instant kill**. Enhanced by ashbeast (bypasses starburst) |
| **Stormhammer** | Air/Fire | 6.0s | 1200 mana | A lightning bolt at one, two or three adventurers or denizens (WIKI :132). Picking them from the target's city is our default (`magi.storm.mode`, `005_Stormhammer_Targeting`) |
| **Holocaust** | Fire | 6.0s | 1500 mana | Delayed explosion (10-60s timer); room-wide |
| **Magmasphere** | Earth/Fire | not given | — | Explodes after the 10-60 s you choose: significant damage, and it may break the limbs of anyone in the room (WIKI :168) |

### Defensive Spells

| Spell | Elements | EQ | Effect |
|-------|----------|-----|--------|
| **Reflection** | Air/Fire | 3.0s | Illusion absorbs one attack |
| **Stonefist** | Earth | 4.0s | Prevents staff disarming |
| **Stoneskin** | Earth | 2.0s | Physical damage reduction (blunt > cutting) |
| **Chargeshield** | Air/Earth | 4.0s | Electric damage resistance |
| **Bloodboil** | Fire/Water | 4.0s | Self-affliction cure; potential double cure at Fire/Water major |
| **Diamondskin** | Earth/Fire/Water | 2.0s | Cutting resistance + modest blunt reduction |

### Terrain Spells

| Spell | Elements | EQ | Effect |
|-------|----------|-----|--------|
| **Firewall** | Fire | 3.0s | Directional fire barrier |
| **Icewall** | Water | 3.0s | Directional ice barrier |
| **Fog** | Air/Water | 4.0s | Obscuring fog (reveals hidden) |
| **Hellfumes** | Air/Earth | 4.0s | Choking noxious cloud |
| **Flood** | Water | 4.0s | Water room coverage |
| **Quake** | Earth | 3.2s | Drains water via earthquake |
| **Hailstorm** | Air/Water | 3.5s | Enemy-exclusive hailstone barrage |

### Utility Spells

| Spell | Elements | EQ | Effect |
|-------|----------|-----|--------|
| **Light** | Fire | 3.0s | Reveals hidden targets |
| **Scry** | Water | 1.0s | Locates adventurers |
| **Erode** | All four | 2.5s | Strips defenses (shield, chargeshield, insulation, temperance); decreases resonance unless MAINTAIN |
| **Illusion** | Air/Fire | 2.0s | Creates room illusion (optional LETHAL variant) |
| **Simultaneity** | — | 4.0s | Opens all four channels simultaneously |

---

## Artificing Abilities (Complete Reference)

### Staff & Staffcast
- **Staff**: Primary combat foci. 1000 mana to create, 150 mana per staffcast. 4s EQ. Holds up to 4 crystals
- **Staffcast**: Cast the staff's embedded crystal spell at a target. EQ-based (separate from spell balance)

### Crystal Enhancements (for Staff)

Staff holds up to 4 crystals. **Current loadout: Rapidity, Glacial, Horripilation, Immolation, Scintilla** (5 available, staff holds 4 — swap as needed).

| Crystal | Effect | Notes |
|---------|--------|-------|
| **Scintilla** | "a potent fire spell" (WIKI, Artificing.wiki:49); the wiki says nothing more | Our triggers model two steps: a spark (`010_Scintilla_Spark`, held 4 s, our figure) and an ignition (`011_Scintilla_Ignition`: burning, burns +1). That the spark ignites only on other damage, and that scintilla calcifies (the "calcify pressure" our lock and salve modes cast it for), are this dossier's claims (UNVERIFIED); the wiki's only calcified-torso source is EMANATION earth. The 4 s matches the Immolation crystal's ablaze "four seconds after your staffcast" (:104); which crystal prints those two lines is UNVERIFIED |
| **Horripilation** | "a freezing HORRIPILATION spell" (WIKI, Artificing.wiki:60); what it afflicts is not in the wiki | With the Glacial crystal it binds the target in water bonds (WIKI :82). Our lock mode casts it "for waterbond/blistered" (`selectLockSpell`), but the wiki's only blistered source is major fire resonance (Elementalism.wiki:62), so blistered from horripilation is UNVERIFIED |
| **Glacial** | Enhanced horripilation — binds target with water bonds (15-45s depending on freeze) | Pairs with horripilation crystal |
| **Immolation** | Applies ablaze 4s after staffcast | Delayed fire pressure |
| **Rapidity** | Doubles staffcast speed, halves damage | Speed vs damage tradeoff |
| **Lightning** | Electricity spell — damage | Base staff damage crystal (not in current loadout) |
| **Shock** | Pairs with lightning — inflicts stupidity | Mental affliction delivery (not in current loadout) |

### Elemental Treaties & Summons
Pacts with Elemental Plane denizens. Maximum 2 active elementals (1 per plane):

| Elemental | Plane | Ability | Effect |
|-----------|-------|---------|--------|
| **Waterweird** | Water | — | Water travel/current immunity |
| **Djinn** | Air | ELEMENTAL LEVITATE | 100 mana, 3.6s EQ |
| **Sandling** | Earth | ELEMENTAL DESCEND | 250 mana, 4s EQ |
| **Efreeti** | Fire | Passive | Periodic enemy ignition |
| **Stoneback** | Earth | ELEMENTAL BULWARK | Protective ability, 3.6s EQ |
| **Breath** | Air | ELEMENTAL BREATHMELD | Tracking, 1s EQ, 2min cooldown |
| **Mistfiend** | Water | ELEMENTAL CONDENSE | Water control, 300 mana, 4.2s EQ |
| **Ashbeast** | Fire | ELEMENTAL SURGE | Destroys water constructs, 3.6s EQ. **Enhances Destroy (bypasses starburst)** |

### Artefact Abilities (Configurable in System)
These require specific purchased artefacts and are gated behind config toggles:

| Ability | Command | Effect | Config Toggle |
|---------|---------|--------|---------------|
| **Arachnideye Trample** | `arachnideye trample <target>` | Knocks prone + disorientation | `magi.offense.config.useArachnideye` |
| **Webbomb** | `webbomb <target>` | Entangles + grounds (prevents flight escape) | `magi.offense.config.useWebbomb` |

Both are **free actions** (don't consume spell balance) and are prepended to the attack queue when enabled.

---

## Crystalism Abilities (Complete Reference)

### Core Mechanics
- **Refine**: Extract crystal shapes from Master Crystal (50 mana, 1s bal)
- **Fold**: Restore Master Crystal facets using pearls
- **Spin**: Prepare crystals for embedding
- **Embed**: Activate vibration in room (300 mana, 3.1s EQ)
- **Dampen**: Destroy your own vibrations (4s bal)
- **Focus**: Consolidate all vibes to current room (100 mana, 4s EQ)
- **Destabilise**: Destroy vibrations with potent environmental effects (400 mana). Each vibe type has unique destabilization effect

### Combat Vibrations

| Vibration | Shape(s) | Effect | Lessons |
|-----------|----------|--------|---------|
| **Dissipate** | Pentagon | Attacks enemy mana pools | 6 |
| **Palpitation** | Cylinder | Heart attack damage | 15 |
| **Tremors** | Disc, Egg | Strips levitation; knocks non-levitating enemies prone | 88 |
| **Oscillate** | Diamond | Periodic amnesia | 555 |
| **Stridulation** | Cylinder, Polyhedron | Destroys enemy equilibrium | 945 |
| **Disorientation** | Spiral | Periodic dizziness | 703 |
| **Forest** | Diamond, Pyramid | Crystal shards causing bleeding | 1152 |
| **Dissonance** | Cylinder, Sphere, Spiral | Damage + periodic defense stripping | 1290 |
| **Plague** | Cube, Pyramid, Spiral | Variety of afflictions | 1394 |
| **Lullaby** | Pyramid | Puts enemies to sleep | 1532 |
| **Retardation** | Disc | Aeon effect to all in room; disables passive vibe effects | 1635 |

### Utility/Defensive Vibrations

| Vibration | Shape(s) | Effect | Lessons |
|-----------|----------|--------|---------|
| **Heat** | Pyramid | Soothing warmth; counters cold effects | 33 |
| **Alarm** | Spiral | Alerts when enemies enter/leave room | 66 |
| **Reverberation** | Disc, Pentagon | Protects vibes from destruction (not Dampen/Retardation) | 133 |
| **Sonicportal** | Sphere, Torus | Opens portal between you and target | 177 |
| **Adduction** | Disc, Polyhedron | Pulls people from adjacent rooms | 222 |
| **Harmony** | Egg, Sphere | Healing vibration (HEALING or RESTORATION mode) | 333 |
| **Creeps** | Torus | Causes shyness/fear in enemies | 377 |
| **Silence** | Egg | Cancels most sound in room | 422 |
| **Revelation** | Cube, Diamond | Reveals concealed adventurers | 466 |
| **Grounding** | Sphere | Roots you; prevents movement | 511 |
| **Energise** | Polyhedron | Drains enemy HP; stored for later (ABSORB ENERGY) | 842 |
| **Gravity** | Egg, Torus | Pulls sky/tree entities down | 1083 |

### Cataclysm (Transcendent)
Requires TWO transcendent Magi spinning all 11 crystal shapes. Enables Elementalism casting through vibration at 3-room radius. Second Magi must IMBUE to complete.

### Default PvP Vibe Set
`mm vibes` calls `magi.offense.setupVibes()`, which only **sets** the wanted list to these eight and prints a reminder to type `evibe`. It embeds nothing, and the offense never checks what is embedded (corrected 2026-10-12: this said "Auto-managed"):
```
dissonance, energise, creeps, palpitation, tremors, disorientation, plague, lullaby
```
**`evibe`** does the embedding: it sends VIBES, drops wanted vibrations already listed in the room (`vibes/003_Vibe_Found`), then queues `embed <vibe>` one at a time, moving on at each embed line (`magiVibes_nextEmbed`, `ataxia/021_Magi_Vibes_Tracking.lua`). `vibe <name>` adds or removes one in the list. `vib` embeds a different fixed five (dissonance, disorientation, creeps, plague, harmony) in one queued line. EMBED costs 300 mana and equilibrium (the wiki gives 3.10 s in the generic row and 4.00 s in each vibration's row, Crystalism.wiki:37 and e.g. :117).

---

## Kill Routes

### Primary Kill: Fire/Burn Damage
```yaml
type: damage
summary: Stack burns → conflagrate → stormhammer/destroy finisher
mode: "fire" (xx, or mm fire). vv's water mode runs this same tree

pipeline:
  1: "Magma → scalded (20 s, CONFIRMED). Our tree mostly skips magma while scalded (two builders do not: see the Magma row); that the game refuses it is UNVERIFIED"
  2: >-
    Burn counter (0-5, st.burns). Up: firelash +1 (021_Spell_Outcomes); the fan line +1
    (022_Increase_Burning, our target only since v4.7.420; since v4.7.429 the only count of a
    dehydrate's stack, which 015 no longer adds); moderate fire on a scalded target +1 and major fire on a blistered one +1 (022);
    conflagrate +2 (019); efreeti +1 (025); fire emanation +2 (enamation/001, which fires on this
    user's wrap since v4.7.420 and gives V3 one burning, not two: see Trigger Architecture); each
    firestorm tick +1 while the target is here (004); a flaming meteorite +1
    (024); scintilla ignition +1 (011). Whether the fan line ALSO prints for these other
    sources (each counts its own stack) is not known: kb/CONFLICTS.md #37.
    Down: 025's fires-diminish line -1 (since v4.7.430 the only count of a mending: 391, the
    application line just before it, also took one, so one mending took two); their tree -1 (389).
    Zeroed by a failed conflagrate (020, no target check), a target change, a reset (`mm reset`,
    the `res` alias, login), and whenever V3 shows no burning (selectSpell). Fulminate adds none
    (v4.7.419)
  3: "At burns >= 2 + fire >= 2 → CONFLAGRATE (the wiki needs only two ablaze stacks; fire >= 2 is our gate)"
  4: "Conflagrated + HP < 35% → DESTROY (the wiki: a conflagration and 40% health or less; 35 is our configurable margin)"
  5: "HP <= 25% → STORMHAMMER (up to 3 targets)"

key_spells:
  magma: "Applies scalded (20 s), builds earth+fire resonance"
  dehydrate: "Nausea + weariness; already weary → a burning stack; already nauseous → a freeze stack; both → burning only. Builds fire+water"
  fulminate: "Builds air+fire. Chain: fulminated → epilepsy → paralysis. No burning"
  firelash: "Burns +1, builds fire. Sets the target ablaze when cast in the room"
  conflagrate: "Wiki: two or more ablaze stacks. Our gate: burns >= 2, fire >= 2. Sets conflagrated flag"
  destroy: "Execute. Wiki: conflagration + 40% health or less; we cast it at HP < 35% (configurable)"
  stormhammer: "High damage, up to 3 targets; ours picks them from the target's city by default (magi.storm.mode)"
```

### Alternative Kill: Water/Glaciate (no mode of its own)
```yaml
type: damage
summary: "A frozen target → GLACIATE. The wiki asks only that the target is already frozen (Elementalism.wiki:218)"
mode: >-
  None in code. setMode accepts "water" and vv sets it, but selectSpell branches only for
  lock, salve and group, so water mode runs the fire tree. The offense's header still promises
  "water → freeze → hypothermia → glaciate" (004_Magi_Offense.lua); that is not a branch.

what_the_code_does:   # 004_Magi_Offense.lua, v4.7.419. P3 and P7 are shared (every mode); P10 and P11 run only in fire and water mode
  P7: "frozen (V3 >= 0.5) + not hypothermic (V3) + water >= 2 + air >= 2 → HYPOTHERMIA"
  P3: "frozen AND hypothermic (both V3 >= 0.5) + water >= 2 + air >= 2 → GLACIATE. Before v4.7.419 it read the st.hypothermia latch or V3 hypothermia (so the latch alone sufficed) and never tested frozen"
  freeze: "Only P10 (shivering + countMendingAffs() >= 1: a broken limb, a burn or a calcification) and P11 (calcified torso + frostbite or insulation down) cast it, and only in fire and water mode: lock, salve and group never cast freeze. Outside P11 nothing walks a target from insulation to frozen on purpose"
  no_hp_test: "Glaciate has no health or kill-range test"

what_the_sources_say:
  freeze: "Strips insulation, then shivering, then frozen, one stage per cast (WIKI :304). No limb requirement"
  hypothermia: "On a frozen target, stops them curing frozen; cured by restoration to the body (WIKI :182, CONFIRMED)"
  glaciate: "'terrible damage upon those that are already frozen' (WIKI :218). Damage, not an instant kill. The hypothermia and water/air >= 2 requirements are ours, not the wiki's"
  tabethys: "Emanate water, freeze, freeze, then GLACIATE; HYPOTHERMIA only when glaciate would not kill (PLAYER). See Tabethys's core rotation below"
```

### Alternative Kill: Affliction Lock
```yaml
type: affliction
summary: Use resonance passive effects + mudslide + vibrations for truelock
mode: "lock" (cc, or mm lock)

pipeline:
  1: "Build kelp stack via resonance passives (air: asthma, sensitivity, healthleech, all kelp/aurum). Frostbite is NOT kelp: it is caloric (CONFIRMED)"
  2: "Mudslide at water == 2 + asthma → slickness + prone (P8, shared by every mode; no earth test)"
  3: "Horripilation via staffcast → water bonds with the Glacial crystal (WIKI); blistered from it is UNVERIFIED (see its row)"
  4: "Earth resonance → paralysis (passive at level 2)"
  5: "Embedded vibrations for impatience/stupidity. UNVERIFIED for both: no embedded vibration in the wiki names either (Plague gives 'a variety of afflictions', unnamed), and no Magi ability names impatience. The Magi's named stupidity sources are the Shock crystal with lightning (Artificing.wiki:93), TRANSFIX unblinding at moderate air and fire (Elementalism.wiki:388) and DESTABILISE on Oscillate (Crystalism.wiki:429)"
  6: "Scintilla for calcify pressure (that scintilla calcifies is UNVERIFIED: see its row). A calcified torso does not block restoration: restoration is its only cure, so it keeps their restoration busy (CONFIRMED)"
  7: "Truelock → damage to death"

required_afflictions:
  - asthma: "blocks smoking (air resonance passive at level 1)"
  - anorexia: "blocks eating (water resonance passive at level 3)"
  - slickness: "blocks applying (mudslide, WIKI :364; the wiki names no affliction for horripilation)"
  - paralysis: "blocks tree (earth resonance passive at level 2)"
  - impatience: "blocks focus. No known Magi source (see step 5)"
  - haemophilia: "class lock aff (prevents clotting)"

players_practice: >-
  Tabethys's lock is a FOCUS lock, not a truelock: paralysis + asthma + anorexia + slickness,
  with no impatience. Fulminated makes every successful FOCUS paralyse them again, and vibes
  add focus-curable afflictions so a focus may cure something other than anorexia. The kill
  is the water finisher, not damage to death. See Tabethys's core rotation below.
```

### Salve Pressure
```yaml
type: hybrid
summary: Scalded + earth resonance + calcify for salve-curable affliction overload
mode: "salve" (zz, or mm salve)

strategy:
  - "Scalded slows their salve balance: 'Increases the recovery time of applying salves.' (CONFIRMED). It strips nothing. The fire passive that strips a defence is minor fire, and it strips temperance; insulation (taken to be the caloric defence: the game's DEF list names Insulation and no caloric defence, and our defence table maps caloric to insulation, deffing/004; UNVERIFIED in game text) is stripped by FREEZE, EMANATION water and ERODE (WIKI)"
  - "Earth resonance breaks limbs (salve cures)"
  - "Calcified torso spends their restoration salve: it is cured only by 'Apply Restoration To Body', and if calcification completes first the torso takes extreme damage (CONFIRMED). It blocks nothing"
  - "Cracked ribs from major earth resonance (WIKI :62); earth emanation calcifies the torso (WIKI :242), which enamation/004 does not record: only 026_Calcify's own torso line does (Trigger Architecture)"
  - "Scintilla spark → ignition for more burns (salve pressure)"
```

### Group PvP
```yaml
type: damage
summary: Pure damage output, stormhammer multi-target
mode: "group" (mm group)

strategy:
  - "Stormhammer priority at 50% HP (up to 3 targets, by default from the target's city: magi.storm.mode)"
  - "Emanation fire at cap: two ablaze stacks on the target (WIKI :242). EMANATION takes one target (CAST EMANATION AT <target> FIRE, WIKI :237); it is not an area spell"
  - "Shalestorm: periodic damage and a random limb break on one target, or its shield broken (CAST SHALESTORM AT <target>, WIKI :189-194); not the room"
  - "Scintilla auto-fires when shalestorm active"
```

---

## Tabethys's core rotation (players' practice, 2026-10-12)

**Source:** `kb/raw/players/magi-tabethys-2026-10-12.txt`, Tabethys's advice in their own words, relayed by the user. It is **PLAYER** confidence: how a strong Magi plays, not game text. This section checks each claim against the wiki and the game's records, and says where our offense differs. The user adopted it as its own key in v4.7.421 (`ww`, mode `waterroute`); the other keys are unchanged. "Where our offense differs" below still describes them.

**This dossier credits Tabethys with xMagi**, the reference our offense was built from: "Key insight from Tabethys (xMagi author)" (Shalestorm + Scintilla section) and "Aegoth/Tabethys decision tree" (Reference Files). The record does not agree with itself: `004_Magi_Offense.lua`'s header says "Based on xMagi reference (Aegoth/Tabethys)", and the 2026-03-10 CHANGELOG entry that built the offense says "xMagi decision tree + Tabethys triggers". `xMagi.lua` is no longer at the path in Reference Files (checked 2026-10-12), so who wrote which part cannot be checked. It matters because the offense's glaciate gate, in the tree marked "based on xMagi reference", contradicts Tabethys's own finisher (difference 5 below; kb/CONFLICTS.md).

### What they say
1. **Opener:** MAGMA, DEHYDRATE, DEHYDRATE, FULMINATE: the "core rotation" that most people start with, in their words. They say it afflicts scalded, "usually burns tree", knocks the enemy off herb balance, forces them to choose between fulminated and asthma, blisters them ("so walking away is not so simple"), and sets water to 2 and earth to 1.
2. **The bonk:** then CAST MUDSLIDE, "the biggest of all bonks", for "par, sli, ano, prone".
3. **Vibes:** with vibrations running ("and if you don't then you are a fool") this "has a good chance at landing a focus lock".
4. **Finisher:** emanate water ("stuttering + strips caloric"), freeze ("shivering"), freeze ("frozen, stuttering"), then glaciate, "or hypothermia if they are somehow not in glaciate-kills-them-in-one range".

### The one assumption under the numbers
How many levels one cast adds is not in our data: the wiki only says the resonant spells "are listed under AB ELEMENTALISM" (Elementalism.wiki:62), and AB ELEMENTALISM, the most likely place for the step, has not been captured. The table below assumes **each cast raises every plane it channels by exactly one level, and nothing fades in between**. Tabethys's water 2 and earth 1 come out exactly under that model, and their 2026-10-19 log shows it cast by cast for earth, fire and water (PLAYER, see "In play"); a capture of RESONANCE after each cast would make it CONFIRMED. What each level does is WIKI (the Resonance block above). Two more limits from the same text: resonance "is fleeting and will fade over time" (the opener spends 2.30 + 2.30 + 2.30 + 2.40 = 9.30 s of equilibrium, WIKI, so the levels have to last about that long; the fade rate is not recorded), and only spells "targeted against an adventurer who is directly within your location" build it.

### Resonance after each cast
Levels 0-3 = none, minor, moderate, major; all four planes start at none.

| # | Cast (equilibrium, WIKI) | Channels | Air | Earth | Fire | Water | Resonance effect as a plane grows (WIKI :62) | The spell's own effect (WIKI) |
|---|---|---|---|---|---|---|---|---|
| 1 | MAGMA (2.30 s) | Earth, Fire | 0 | 1 | 1 | 0 | Minor earth: breaks a random unbroken limb. Minor fire: strips temperance and blocks raising it | scalded + damage (:376) |
| 2 | DEHYDRATE (2.30 s) | Fire, Water | 0 | 1 | 2 | 1 | Moderate fire, on a target already scalded: ablaze + damage. Minor water: frostbite | nausea + weariness + dehydrated + damage (:328) |
| 3 | DEHYDRATE (2.30 s) | Fire, Water | 0 | 1 | 3 | 2 | Major fire: blistered. Moderate water: stuttering + cold damage | nausea + weariness again; with both still up, a stack of burning (weariness alone: burning; nausea alone: a stack of freeze) (:328) |
| 4 | FULMINATE (2.40 s) | Air, Fire | 1 | 1 | 3 | 2 | Minor air: asthma. Fire was already major: what a further fire cast does is not recorded (UNVERIFIED) | fulminated + damage; epilepsy if already fulminated, paralysis if both (:340) |
| 5 | MUDSLIDE (2.30 s) | Earth, Water | 1 | 2 | 3 | 3 | Moderate earth: a short stun + paralysis. Major water: anorexia | slickness + prone + damage (:364) |
| 6 | EMANATION AT <t> WATER (2.40 s) | all four; needs major water and clears it | 1 | 2 | 3 | 0 | None assumed: the wiki files EMANATION, GLACIATE and HYPOTHERMIA under "Higher Order Spells", not "Resonant Spells" (:269) (UNVERIFIED) | insulation stripped (a level of freeze if it is already gone) + disrupted + stuttering + damage (:242) |
| 7 | FREEZE (3.00 s) | Air, Water | 2 | 2 | 3 | 1 | Moderate air: sensitivity. Minor water: frostbite | shivering, since insulation is already gone; damage (:304) |
| 8 | FREEZE (3.00 s) | Air, Water | 3 | 2 | 3 | 2 | Major air: healthleech. Moderate water: stuttering + cold damage | frozen + damage (:304) |
| 9 | GLACIATE (3.00 s), or HYPOTHERMIA (2.60 s) | Air, Water | | | | | None assumed (higher order) | glaciate: "terrible damage upon those that are already frozen" (:218). Hypothermia: they can no longer heal their frozen state (:182) |

Fire at 3 from row 5 on is only what the model gives: it has had several casts to fade. After row 8, water is 2 and air 3, so the `water >= 2 and air >= 2` our P3 asks for is met by this sequence anyway.

### What each claim rests on
- **Scalded:** MAGMA gives it (WIKI :376). The game's record (CONFIRMED): "Increases the recovery time of applying salves.", cured only by time, 20 s, NoRandomCure. It slows their SALVE balance, not herbs.
- **The tree** ("usually burns tree"): PLAYER; no game text says it. Under the model the four casts land about a dozen afflictions in about 9 s: scalded, a broken limb, temperance stripped, nausea, weariness, dehydrated, ablaze, frostbite, a burning or freeze stack, blistered, stuttering, fulminated, asthma. Server-side curing can fire the tree at an affliction count or when a curing balance is down (`CURING TREE SCENARIO AFFCOUNT` / `NOBAL`, kb/raw/help/13.7.8), and TOUCH TREE cures one random affliction (kb/afflictions/cure-channels.md). The order is the point: their tree goes on this pile **before** the mudslide's paralysis blocks it. Scalded, dehydrated and blistered are NoRandomCure (CONFIRMED); that the tree cannot take them is our ASSUMED reading (kb/afflictions/database.md). By cast 3 they can also carry two ablaze stacks (moderate fire on a scalded target, then dehydrate on a weary one), which is CONFLAGRATE's requirement; Tabethys mudslides instead.
- **Herb balance** ("knocks the enemy off herb balance"): PLAYER, and right in effect, though no spell strips herb balance directly (WIKI). The opener lands four afflictions cured by eating (CONFIRMED): nausea (ginseng/ferrum), weariness and asthma (kelp/aurum), fulminated (goldenseal/plumbum). EAT cures one per eat (kb/afflictions/cure-channels.md), so their eating balance is busy when the mudslide lands.
- **Fulminated or asthma** ("forces them to choose between fulminated and asthma"): CONFIRMED by the cure records: two different herbs on the one eating balance. If asthma stays, "Asthma makes it impossible to smoke anything or hold your breath.", so the slickness to come can only be eaten off (bloodroot/magnesium), and the mudslide's anorexia then blocks eating. If fulminated stays, "Successful attempts to focus your mind to cure an affliction will cause you to be struck down with paralysis.", and FOCUS is the one cure the focus lock leaves them.
- **Blistered** ("blisters them"): blistered comes only from major fire (WIKI :62); under the model it lands on the second dehydrate. The only game text about movement is its cure line (CONFIRMED): "Your horribly blistered skin has recovered somewhat, your movement no longer so limited." How it limits movement is not recorded; only time cures it, and AFFLICTION SHOW gives no default time.
- **Water 2, earth 1** ("sets your water to 2 and earth to 1"): the table above, under the one-level model.
- **The mudslide, "par, sli, ano, prone":** the spell gives slickness and prone (WIKI :364). The paralysis, with a short stun Tabethys does not mention, is moderate earth as earth grows 1 to 2; the anorexia is major water as water grows 2 to 3 (WIKI :62). **The earth level decides whether the tree is blocked**: at earth 0 the same cast breaks a limb instead, and at earth 2 it gives cracked ribs. The mudslide also takes water to major, which is what EMANATION water needs next.
- **Vibes and the focus lock:** a focus lock is paralysis (blocks the tree), asthma (smoking), anorexia (eating) and slickness (salves), and "In lieu of Impatience, the user afflicts multiple mental afflictions in the hopes that when the opponent uses Focus it cures something other than anorexia" (kb/raw/guides/lock-types.txt; `.claude/classes/lock_types.md`, Focuslock). Anorexia is cured by "Apply Epidermal To Body" or "Focus Mind" (CONFIRMED) and slickness blocks the epidermal, so FOCUS is their only way out. Hostile vibrations feed it focus-curable afflictions: Disorientation "will cause periodic dizziness" and Creeps "will cause shyness" (WIKI, Crystalism.wiki:296, :213); both are cured by goldenseal/plumbum or "Focus Mind" (CONFIRMED). Oscillate "will periodically give amnesia" (:261), but the game's record gives amnesia no cure at all ("Amnesia makes you forget one action that you try to take."), so it may cost them an action but does not compete for FOCUS. The rotation adds stuttering ("Focus Mind" too), and fulminated turns every successful focus into paralysis. How often a vibration fires is not recorded: the texts say only "periodically" (UNVERIFIED). Their "good chance" is a judgement (PLAYER). `kb/afflictions/locks.md` says FOCUS "picks randomly among mentals" (community-guide confidence); no game text in `kb/` says whether FOCUS cures at random or by priority. Do not confuse VIBES FOCUS (Crystalism: calls your vibrations to you) with the FOCUS cure.
- **Emanate water:** `CAST EMANATION AT <target> WATER`, 100 mana, 2.40 s (WIKI :237-242). It needs major water and clears it: "your target will be given a level of freeze (or have the insulation defence stripped), and will be disrupted along with being afflicted with stuttering." Tabethys leaves out disrupted: "Being disrupted will keep you permanently off of equilibrium.", cured only by Concentrate (CONFIRMED). Their "caloric" is the defence the Magi texts call insulation; HELP 13.7.1 calls the caloric salve a "Cure for cold-based afflictions and defence for some cold attacks." That the two are one defence is inferred (UNVERIFIED).
- **Freeze twice:** "you will first strip the insulation defence if the target has it, then cause the target to shiver, and finally freeze him" (WIKI :304). With insulation already gone, the first freeze gives shivering and the second frozen; the second one's stuttering is moderate water as water regrows (the model). Under slickness none of it can be cured: shivering, frozen and frostbite are all "Apply Caloric" (CONFIRMED). A heat vibration in the room can stop a freeze (WIKI :304).
- **Glaciate:** "This higher order spell will inflict terrible damage upon those that are already frozen." (WIKI :218). Frozen is its only stated requirement. It is damage, not an execute: "glaciate-kills-them-in-one range" is Tabethys's (PLAYER), and `kb/` holds no figure: no AB capture, no logged hit, and no trigger of ours records a glaciate (UNVERIFIED).
- **Hypothermia instead:** on a frozen target it removes "their ability to heal their frozen state" (WIKI :182). The game's record: "Prevents curing the freezing affliction.", cured by "Apply Restoration To Body", NoRandomCure (CONFIRMED). Slickness blocks that salve too, so under the lock it holds them frozen until glaciate is in range.

### Where our offense differs (v4.7.419)
This describes `zz`/`xx`/`vv`/`cc`/`sr`, which v4.7.421 left as they were; `ww` runs the route itself (next section).

1. **No mode runs the opener.** `zz` (salve) casts magma, bombard, then staffcast scintilla while earth is 2+ and the torso is not calcified. `xx` (fire) and `vv` (water) cast magma, then bombard (`selectFallback`, since burns are 0 and earth is under 2), then shalestorm, then scintilla (P5). `cc` (lock) opens with staffcast horripilation, then (once `staffcast/002` records the water bonds, which it cannot on this user's wrap) magma, bombard, fulminate up to air 3, and emanation air. `sr` (group) comes closest: magma, dehydrate, dehydrate, then **emanation fire at fire 3**, exactly where Tabethys fulminates. In fire and water mode the fire tree refuses fulminate at fire 3 (`fireWillBurn` in `selectBurningSpell`; Resonance Budgeting above).
2. **`vv`'s water mode runs the fire tree.** `setMode` accepts "water" and `vv` sets it, but `selectSpell` branches only for lock, salve and group.
3. **The mudslide gate has no earth test.** P8 casts mudslide on `asthma >= 0.5 and r.water == 2`. Nothing ensures earth is 1, so whether our mudslide brings the paralysis depends on wherever earth happens to be (shalestorm drains it, WIKI :194). Lock mode also mudslides a clumsy target at earth under 2 with no water test. P8 runs before the mode branches, so changing it changes all five modes.
4. **No focus-lock state.** The offense never reads fulminated, never tests for paralysis + asthma + anorexia + slickness together, and never moves to a finisher when they are up; in fire mode the pick after a bonk is conflagrate once burns reach 2 with fire at 2+. A joint-probability helper exists (`getStateProbabilityV3`, `affliction_tracking_core/007`), but none of the three locks in `getLockStatusV3` (`008_V3_Integration.lua`) is this set.
5. **Hypothermia always precedes glaciate.** P7 lays hypothermia on a frozen target first; P3 then casts glaciate only on a target V3 shows frozen AND hypothermic, with water and air at 2+. Glaciate has no health test. Outside the calcified-torso path (P11) the tree casts freeze only on a target already shivering with a broken limb, a burn or a calcification (P10, `countMendingAffs`), and only in fire and water mode, so it never walks a target from insulation to frozen on purpose, and emanation water is only the seventh choice of `selectBurningSpell`.
6. **Vibes are never checked.** `dispatch` reads no vibration state; `mm vibes` only sets the wanted list, and embedding is manual (`evibe`, `vib`). `magi.auto_focus` (`001_Resonance.lua`) is set and read nowhere.

**If it is adopted** (the user's call): a `selectWaterSpell()` branch on the unused water mode leaves fire, salve, lock and group untouched. Key it on resonance, not a step counter, so it re-derives after a cure: magma if not scalded, dehydrate while water is under 2, fulminate at air 0 whatever fire is; mudslide at water 2 + earth 1 inside the branch (P8 is shared); a focus-lock test through `getStateProbabilityV3({"paralysis", "slickness", "anorexia", "asthma"})` (four separate probabilities overstate a joint state while V3 is branching); then emanation water at water 3, freeze until frozen, and glaciate below a health threshold measured from logs, else hypothermia. P8 and P3 sit above the mode branches, so the branch must run before them or they will cast first.

**Tracking for this route at v4.7.420.** The mudslide's paralysis and anorexia lines (`general/022`) and the water emanation (`enamation/002`) survive this user's 119-124-column wrap since v4.7.419, and the water emanation records stuttering. Since v4.7.420 the fire, air and earth emanations (`enamation/001`, `003`, `004`), which this route does not cast, fire on the wrap too (Trigger Architecture). The mudslide's own line (slickness + prone, `021_Spell_Outcomes`) is still an anchored full line, which fits a 119-column row only for names of up to 13 letters, and no test delivers it. Not tracked: the moderate-earth stun, the target's dehydrated, and any glaciate hit. Fulminated's focus-paralysis trigger (`magi_offense_tracking/007`) matches a wording no capture in `kb/` shows (UNVERIFIED); the only captured line like it is the Shikudo nervestrike's, "Horror overcomes the face of <T> as his body locks in paralysis." (kb/raw/logs, Mystor's logs), which 007 does not match.

### The water route (ww, v4.7.421)
`ww` sets mode `waterroute` and dispatches (`magi_things/007_Water_Route.lua`); `mm waterroute` (or `mm route`) sets the mode without attacking, and bare `mm` then shows the route step, the joint lock and the glaciate setting. `selectSpell` (`mage/004_Magi_Offense.lua`) branches to `selectWaterRouteSpell` after P1 (destroy) and P2 (the meteorite shield strip) and BEFORE P3-P8, because P3, P7 and P8 are steps of this route under other gates and P4-P6 would cast in its place. `vv`'s `water` mode is unchanged and still runs the fire tree.

Every pick is read from live resonance and the target as V3 holds it (`waterRoutePick`), never from a step counter, so a cure or a second press re-derives the step:
1. **Frozen:** glaciate if the target's health is unknown or at most `magi.offense.config.glaciateKillAt` (default 100, i.e. glaciate first, Tabethys's usual finisher); otherwise hypothermia first, then glaciate. Only frozen is required (#31). `mm glaciate N|off` sets it (not saved); `off` always lays hypothermia first. Health is trigger 698's stamp for THIS target, at most 30 s old (`targetHPKnown`/`routeTargetHP`), never `getTargetHP`, because `general/001_Assess` writes `targetHealth` from anyone's glance.
2. **Slick, not frozen (after the bonk):** one re-fulminate per bonk while fulminated is down (`haveAff`) and the lock is not on; emanation water at water 3; else freeze.
3. **Water 3 before any bonk:** emanation water (the opener rebuilds water to 2).
4. **Opener:** magma if not scalded, dehydrate while water < 2, fulminate at air 0 (at any fire level, unlike the fire tree).
5. **Bonk:** mudslide at water 2. At earth other than 1 it is cast anyway and echoes once that it brings no paralysis: nothing in kb/ confirms a way to set earth back to 1.

**The lock is a JOINT probability** (`focusLockProb`, `getStateProbabilityV3({"paralysis","slickness","anorexia"})`): per-affliction tests overstate a branching state. Asthma is left out on purpose (the opener makes them choose between asthma and fulminated); `mm` shows both.

**Known limit:** the one re-fulminate a bonk allows is spent when the round is PICKED, not when the queue runs it, so a press that replaces an unsent re-fulminate round loses it for that bonk (the Counter Incrementing pitfall). The cost is one skipped re-fulminate; the next pick is the emanation or a freeze.

Tests: `src_new/tests/test_magi_water_route.lua` (58), which loads the real affliction API, V3, resonance, the offense and the `ww`/`mm`/`vv`/help alias bodies.

### In play: Tabethys's log of a group kill (2026-10-19)
**Source:** `kb/raw/logs/2026-10-19_tabethys_magi-group_kalys_o6UKnyyy.txt` (PLAYER: their own system's echoes beside game lines; see `kb/raw/logs/README.md`). Tabethys leads Agathon, Ryzant, Valkael and Naxx on the World Tree and kills Kalys, a Serpent. The other three logs the user shared are the same player on Apostate.

| Line | Round (their alias) | Kalys after | What the round gave (their echo + the game line) |
|---|---|---|---|
| :243 | `PVP`: magma | 82% | `Earth: Brokenrightarm`; the game's temperance strip (minor fire) |
| :335 | `PVP`: dehydrate | 80% | the game's fan line; `Fire: Scalded > Burning`, `Water: Frostbite` |
| :420 | `PVP`: dehydrate | 44% | the game's fan line; `Fire: Blistered`, `Water: Stuttering` |
| :547 | `STMPVP`: stormhammer | 51% (after a heartwood vial) | lightning; allies keep hitting |
| :732 | `STMPVP`: stormhammer | slain | "You have slain Kalys." |

What it shows, and what we changed (v4.7.429-430):
- **Resonance grows one level per channelled plane per cast**, for earth, fire and water (was `kb/CONFLICTS.md` #26; PLAYER, from their echoes).
- **A weary dehydrate's stack prints one fan line** (:422). Our `general/015_Dehydrate` counted that stack and `022_Increase_Burning` counted it again; 015 no longer counts it. The FIRST dehydrate (:335-338) is not settled: it printed the fan line AND their `Fire: Scalded > Burning` (from a line they gag, almost certainly moderate fire's "should burn"), so either one stack printed two lines or Kalys was weary from something their tracker missed (#37).
- **A mending prints two lines for one stack** (:412-413): the application, then "The fires consuming Kalys diminish somewhat." `391` and `025` each took a burn; since v4.7.430 only `025` does.
- **Group stormhammer at about 50%** finished a Serpent with allies hitting; `sr` already casts it at 50%.
- **Hidden is hittable.** Both stormhammers that hit (:547, :732) went at a Kalys the room shows "here, hidden" (:525, :706). Both misses ("You cannot see that being here.", :482, :683) came after he had LEFT (the scry at :490 finds him elsewhere). Whether gmcp `Room.Players` lists a hidden player is unknown (#38).
- **What not to copy:** the two stormhammers at a target that had left (the first after a hand swap), and their auto-queue replacing the manual finisher.

Found on the same path and fixed in v4.7.429:
- `magi.storm.selectTargets` (`mage/005`) puts our target in slot 1 whenever gmcp lists it, enemied or not, matching the name in any case (v4.7.430); with nobody else to hit it casts at our target even when gmcp does not list it, and lets the game decide (v4.7.430), so the kill round is never empty. `fire()` sends the full round (`magi.offense.buildRound`: stand, staff and shield, the cast, assess).
- `698_Assess` and `703_HYENA_SCENT` called `magi_setDestroy`, which nothing in `src_new` defines (only the retired `levi_test_project`): every Magi assess threw.
- `ataxia_Players_Update` (`update_stuff/001`): a player leaving whom `ataxia.playersHere` did not hold removed the LAST name, often our target (v4.7.430).
- `general/001_Assess` and `014_Temperance` record only our target.

**Copied from their display** (`mm echo [on|off]`, default on, not saved): `You: <Spell> -> <Target>` once per round queued (`magi.offense.castEcho`, `mage/004`; the same round pressed again within 2 s prints nothing, and it prints when the round is queued, not when it lands); `<Plane>: <Stage> -> <Target>` for every resonance that lands on our target (`resoEcho`, from the 13 call sites in the 12 branches of `022_Resonance_Afflictions` and from `014_Temperance`), and `Fire: Burning N/5` on the fan line (`022_Increase_Burning`); and a stage word on the Magi prompt, `Target: Burns 2 [burn 2/5]` (`stageWord`). Since v4.7.430 the word is NAMED FROM THE SPELL `pickSpell` picks, the side-effect-free half of `selectSpell`, so it cannot disagree with the round (v4.7.429 re-implemented the tests and drifted: in group mode it said "storm" over a P7 hypothermia). Words: destroy, shield, storm, glaciate, hypothermia, bonk (mudslide), calcify (scintilla), emanate <plane>, conflagrate, freeze, shalestorm, scald (magma on an unscalded target), burn N/5, build, or the water route's step. The prompt's burn count is `liveBurns()`, the count the next round reads (no burning in V3 reads 0). Tests: `src_new/tests/test_magi_tabethys.lua` (26).

### Open questions (kb/CONFLICTS.md)
- **The fan line (#37):** does it print beside moderate fire's "should burn" on a scalded target (then that stack counts twice), on a dehydrate at a target that is NOT weary (then every such dehydrate counts a phantom burn), and for the other burn sources (firelash, meteorite, firestorm, major fire, efreeti, fire emanation)?
- **A hidden player in gmcp (#38):** does `Room.Players` list one? Stormhammer orders its targets from that list.
- **Resonance per cast, CONFIRMED:** capture RESONANCE after each cast of the opener (the 2026-10-19 log supports one level a cast; air is unseen).
- **Glaciate's kill range:** capture AB ELEMENTALISM GLACIATE, and log glaciate hits with the target's health before and after.
- **Vibe interval:** log a disorientation or creeps vibration's affliction lines with timestamps.
- **Resonance keys in GMCP:** capture one `gmcp.Char.Vitals.charstats` with resonance up.
- **The xMagi glaciate gate:** recover `xMagi.lua` or ask Tabethys what xMagi gated glaciate on.

---

## Meteorite Shield Breaking

When target has shield up, select meteorite variant based on resonance state to build missing resonance while stripping (`magi.offense.selectMeteorite()`, P2). METEORITE is not in `kb/` (no wiki entry, no AB capture), so what each variant builds or gives is UNVERIFIED; the strings below are what the code sends.
```lua
-- Priority: build missing resonance while stripping shield
if fireWillBurn then "cast meteorite at <t> flaming 4"                 -- fire 1-2
elseif earth < 3 or st.calcifiedTorso then "cast meteorite at <t> pure 4"
elseif water < 3 then "cast meteorite at <t> frozen 4"
else "cast erode at <t> maintain"                                       -- MAINTAIN keeps resonance (WIKI :74)
```

---

## Shalestorm + Scintilla Automation

**Key insight from Tabethys (xMagi author)** (this dossier's attribution; who wrote xMagi is recorded three ways, see Tabethys's core rotation. The claim is in neither `kb/raw/players/magi-tabethys-2026-10-12.txt` nor the wiki, so it is UNVERIFIED: see the Scintilla row): Scintilla creates a spark that only ignites when the target takes OTHER damage. Shalestorm provides constant automatic damage → guarantees spark ignition. This makes scintilla essentially "free" calcify pressure whenever shalestorm is running.

**Implementation**: When shalestorm is active, the system auto-casts `staffcast scintilla` in ALL modes (not just lock/salve). This fires at priority 5 in selectSpell(), after shield strip but before emanations.

**Conditions**:
- `st.shalestorm` — shalestorm must be running (guarantees ignition)
- `not st.calcifiedTorso` — don't waste if already calcified
- `not st.scintillaSpark` — don't re-cast if spark is already pending (4s timer)
- `r.earth >= 2` — need moderate+ earth resonance
- `burns < 5`, and not `burns >= 2 and fire >= 2` — so the burning path at P12 can conflagrate instead

**Scintilla mechanics**:
- Phase 1: `staffcast scintilla at <target>` → applies spark (4s timer)
- Phase 2: If target takes ANY damage during spark window → ignition → burning + burns++
- Shalestorm's periodic earth damage auto-triggers phase 2

Existing lock mode (earth==3) and salve mode (earth>=2) scintilla branches remain unchanged — they fire even WITHOUT shalestorm.

---

## Configurable Utility Abilities (Artefact-Dependent)

Free-action abilities that can be prepended to the attack queue. Require specific purchased artefacts — **default OFF**.

### Arachnideye Trample
- **Command**: `arachnideye trample <target>`
- **Effect**: Knocks target prone + disorientation
- **Gate**: Only fires when target is NOT already prone
- **Toggle**: `mm arach` or `mm arachnideye`
- **Config**: `magi.offense.config.useArachnideye`

### Webbomb
- **Command**: `webbomb <target>`
- **Effect**: Entangles + grounds target (prevents flight escape)
- **Gate**: Only fires when target is NOT already entangled
- **Toggle**: `mm web` or `mm webbomb`
- **Config**: `magi.offense.config.useWebbomb`

### Implementation in buildRound() (`sendAttack` and the stormhammer both use it since v4.7.429)
```lua
-- Utility prefix is prepended BEFORE stand::wield::spell::assess
-- Example output: "queue addclearfull freestand arachnideye trample Targname::stand::wield staff shield::spell::assess Targname"
if magi.offense.config.useArachnideye and not haveAff("prone") then
  prefix = "arachnideye trample " .. target .. sep
elseif magi.offense.config.useWebbomb and not haveAff("entangled") then
  prefix = "webbomb " .. target .. sep
end
```

---

## Offensive System Architecture

### Namespace
```lua
magi.offense = {
  state = {         -- runtime combat state
    mode = "fire",
    burns = 0,
    conflagrated = false,
    scalded = false,
    scaldedTimer = nil,
    calcifiedTorso = false,
    calcifiedSkull = false,
    shalestorm = false,
    scintillaSpark = false,
    scintillaTimer = nil,
    firestorm = false,
    hypothermia = false,  -- unused: read by nothing since v4.7.419 (P3, P7, status read V3), set by nothing since v4.7.420
    frozen = false,
    shivering = false,
    partyrelay = true,
    debug = false,
  },
  config = {        -- persistent config
    destroyThreshold = 35,
    stormhammerThreshold = 25,
    scaldedDuration = 20,
    useArachnideye = false,
    useWebbomb = false,
  },
}
```
`st.hypothermia` is dead: its only writer, `magi_offense_tracking/005`, dropped it in v4.7.420. It still has a default in `004_Magi_Offense.lua` (`_sd`, :57) and is still cleared by `magi.offense.reset()` (:169), and two comments there still say 005 sets it (the default's own at :57, and P3's at :241-242); all of these go in a later tidy-up.

### Decision Tree Priority (selectSpell)
```
1.  DESTROY — conflagrated + HP < 35% (destroyThreshold)
2.  SHIELD STRIP — meteorite variant selection
3.  GLACIATE — frozen + hypothermia (both V3 >= 0.5) + water>=2 + air>=2. No HP test (before v4.7.419: the st.hypothermia latch OR V3 hypothermia, with no frozen test)
4.  STORMHAMMER — HP <= 25% (stormhammerThreshold)
5.  SHALESTORM+SCINTILLA — shalestorm active + earth>=2 + !calcifiedTorso + !scintillaSpark + burns<5 + not (burns>=2 and fire>=2)
6.  EMANATION EARTH — earth==3 + !calcifiedTorso + (frostbite OR burns>1 OR shivering OR insulation down)
7.  HYPOTHERMIA — frozen + not hypothermic (both V3) + water>=2 + air>=2
8.  MUDSLIDE — asthma>=50% + water==2 (no earth test; Tabethys casts it at earth 1)
    MODE-SPECIFIC: lock / salve / group sub-trees (fire and water continue below)
9.  MAGMA — not scalded
10. FREEZE — shivering + countMendingAffs()>=1 (broken limbs, burns, calcified torso/skull). Our gate, not a game rule
11. CALCIFIED PATH — calcifiedTorso + (frostbite OR insulation down): dehydrate if it will freeze and fire is 1-2, else freeze
12. BURNING PATH — burns > 0 → selectBurningSpell (conflagrate/dehydrate/fulminate/emanation)
13. SHALESTORM — earth>=2, not active; then FALLBACK (selectFallback)
```
P1-P8 run before the mode branches, so they act in every mode: a change to P3, P7 or P8 changes all five modes.

### Mode-Specific Sub-Trees

**Lock Mode** (`selectLockSpell()`):
1. Horripilation for waterbond/blistered (if missing + not calcified + no paralysis/anorexia); fulminate instead at fire 2. Waterbond is recorded only by `staffcast/002`, which cannot match on this user's wrap (Trigger Architecture), so this step repeats there. Sent as `staffcast horripilation <t>` with no AT, unlike the `stc` alias and the basher (`... horripilation at <t>`, the wiki's `STAFF CAST HORRIPILATION AT <target>`); whether the game takes it without AT is UNVERIFIED
2. Magma for scalded (if not scalded)
3. Scintilla at earth==3 + !calcifiedTorso
4. Emanation earth at earth==3 + calcifiedTorso
5. Build earth if earth < 2: bombard, or mudslide on a clumsy target (no water test)
6. Build air (fulminate) if air < 3, at any fire level
7. Emanation air at cap
8. Fallback: dehydrate

**Salve Mode** (`selectSalveSpell()`):
1. Emanation earth at cap
2. Magma for scalded (if not scalded)
3. Scintilla at earth>=2 + !calcifiedTorso
4. Build earth (bombard) if earth < 3
5. Emanation fire at cap
6. Fallback: dehydrate

**Group Mode** (`selectGroupSpell()`):
1. Stormhammer at HP <= 50% (higher threshold for group)
2. Emanation fire at cap
3. Emanation earth at cap
4. Shalestorm (if not active + earth >= 2)
5. Magma (if not scalded)
6. Fallback: dehydrate

**Burning Sub-Tree** (`selectBurningSpell()`):
1. Conflagrate (burns>=2, fire>=2, not conflagrated)
2. Dehydrate for freeze+burn combo ((insulation down OR frostbite) + nauseous, not weary + fire 1-2)
3. Fulminate (air==0, water==2, fire 1-2): refused at fire 3, where Tabethys casts it
4. Dehydrate if weariness present (fire 1-2)
5. Emanation fire at cap
6. Earth building at earth==1: magma at fire 1-2 (no scalded check), else bombard
7. Emanation water at cap (the only emanation water in the offense)
8. Fallback: dehydrate

### Key Files
| File | Purpose |
|------|---------|
| `scripts/.../mage/001_Resonance.lua` | Creates `magi` table; `get_resonance()` reads charstats into `magi.resonance` (zeroes first, any-case key match since v4.7.419; key format UNVERIFIED) |
| `scripts/.../mage/004_Magi_Offense.lua` | Unified offense system (dispatch, decision tree, all modes) |
| `scripts/.../mage/005_Stormhammer_Targeting.lua` | Smart multi-target stormhammer with city filtering. Our target goes in slot 1 when `targetInRoom()` (any case), or alone when nobody else qualifies; `fire()` sends `magi.offense.buildRound` (v4.7.429-430). Self-exclusion compares `person ~= gmcp.Char.Name.name` (v4.7.98 fix — `gmcp.Char.Name` is a `{name, fullname}` object; comparing the whole table never matched, so the caster could be auto-targeted) |
| `triggers/.../general/015_Dehydrate.lua` | Dehydrate landing line: nausea + weariness on a clean target; nausea on a weary one; the next freeze stage (insulation strip, shivering, frozen) on a nauseous one. The burn a weary target takes is counted by the fan line (`022_Increase_Burning`), not here, since v4.7.429. Since v4.7.419 it no longer records frozen on a weary target |
| `triggers/.../general/021_Spell_Outcomes.lua` | Spell success detection (magma, dehydrate cast, fulminate, bombard, firelash, mudslide). Fulminate adds no burn since v4.7.419. Every pattern is an anchored full line; the longest, mudslide (slickness + prone), is 106 columns plus the name, so on a 119-column wrap it matches names of up to 13 letters (18 at 124) |
| `triggers/.../general/021_Freeze.lua` | One freeze stage per line: insulation strip (`nocaloric`), shivering, frozen. With frostbite and insulation, the strip AND the next stage, then frostbite is erased (AFFLICTION SHOW frostbite). No weariness/nausea since v4.7.419. Which spell prints its line is UNVERIFIED (see Trigger Architecture) |
| `triggers/.../general/022_Resonance_Afflictions.lua` | Resonance effects by plane and level (minor fire is most likely `014_Temperance`). Since v4.7.419 the long lines match an opening fragment, and where the name falls past the wrap it is read from the next row (`withName`); the name check stays |
| `triggers/.../general/023_Shalestorm.lua` | Shalestorm state tracking with anti-illusion guard |
| `triggers/.../general/024_Meteorite.lua` | Meteorite shield-break variant detection: erases `shield`; flaming also records burning and burns +1, frozen records frozen. On the `check_wrap` allowlist: its three strike patterns are anchored full lines of 116-122 columns with a one-letter name, so on this user's 119-124 wrap they match only short names (a pure strip, 3 letters at most). Its fourth, the no-wards line, is short and clears `shield` too |
| `triggers/.../general/025_Burns_Tracking.lua` | Efreeti +1 burn; the fires-diminish line -1 (at 0 it erases burning and clears `conflagrated`); the conflagration tick sets `conflagrated`. Its firestorm pattern only echoes in debug: `004_Firestorm_tick` counts firestorm burns. Every source of the counter: fire route, pipeline step 2 |
| `triggers/.../general/026_Calcify.lua` | Calcified torso/skull detection and fade. Its first pattern is the earth emanation's whole line, anchored (why it is on the `check_wrap` allowlist): it cannot match on this user's wrap, and on a screen wide enough for the whole line it relays `<target>: Emanation Earth` beside 004's `<target>: Emanation Earth (calcifying)`, two relays for one cast. Its skull line is also matched by `002_Calcify_Head_Finish`, which erases `calcifiedskull` (and adds 100.01 head damage) where 026 records it; which wins depends on the order Mudlet runs the two |
| `triggers/.../enamation/001-004` | Emanation fire/water/air/earth triggers. Each matches an opening fragment and reads the target's name once the sentence has closed, so all four fire on this user's wrap (water since v4.7.419; fire, air and earth since v4.7.420). What each records: Trigger Architecture |
| `triggers/.../magi_offense_tracking/001, 005-016` | Staffcast lightning/stupidity/freeze, hypothermia (005), plague both legs, fulminated paralysis (007), transfix, scintilla, deepfreeze, erode, party target priority |
| `aliases/.../magi_things/006_Magi_Mode.lua` | `mm` mode-switch + utility toggle alias |
| `tests/test_magi_tabethys.lua` | 26 tests (v4.7.429-430): the stormhammer slot-1 and alone rules, the full round, the name checks, one mending = one burn, the room list, the echoes and the stage word |
| `tests/test_magi_tracking.lua` | 25 tests (v4.7.419, +2 in v4.7.429: dehydrate + fan line = one burn), through the triggers' real patterns. 022's twelve lines and the water emanation (002) are delivered whole and wrapped at 100/119/124 columns, for a 7- and a 12-letter name; 021_Freeze, 015 and the Fire Lord's 493 on one 100-column row (their lines fit); in 021_Spell_Outcomes only fulminate (every width) and firelash (whole). Its magma, bombard, mudslide and dehydrate-cast patterns are untested. Also covered: the P3/P7 order, `mm` status, `get_resonance` |
| `tests/test_magi_emanations.lua` | 13 tests (v4.7.420), through the triggers' real patterns. The fire, air and earth emanation lines, rebuilt from the old patterns (no capture exists), with two staff wordings and a 7- and a 12-letter name, are delivered whole and wrapped at 100/119/124 columns: each fragment matches its own emanation only, on row 1 only; the body records on the closing row, for our target only; a sentence that closes without the name leaves no reader armed; and the old folded patterns match no wrapped row (the bug). Also: what each records, 005's four afflictions without the latch, and a last test through the real V3 (007, 008), 017 and the salve trigger 391, where no burning may outlive two body mendings after a fire emanation. That test fails if 001 gives V3 two burnings |

### Trigger Architecture
- **`general/`**: 001_Assess (target health, read by `getTargetHP()`; our target only since v4.7.429), 014_Temperance (most likely minor fire, by its wording; records `notemperance` for 17 s, a figure with no source; our target only since v4.7.429), 015_Dehydrate, 019/020 Conflagrate, 021_Spell_Outcomes (unified), 021_Freeze, 022_Resonance_Afflictions, 022_Increase_Burning, 023_Shalestorm, 024_Meteorite, 025_Burns_Tracking, 026_Calcify, firestorm (003-005), transfix (009-011). Firestorm's cast line (`005_Firestorm_up`) is an exact-match pattern of 135 columns folded across two YAML lines, so on this user's wrap it never fires: the first tick (`004_Firestorm_tick`) sets `magi.firestorm` instead, and the `firestorm` mark 005 would put on the target is never recorded
- **`magi_offense_tracking/`** (001, 005-016): staffcast and spell outcomes (see Key Files). Resonance afflictions live in `general/022`, emanations in `enamation/`. 005 (our hypothermia line) calls `tarAffed` for hypothermia, frozen, shivering and nocaloric, on our target only (`isTargeted`). V3 takes `frozen` through its own freeze chain (`applyFrozenInteractionV3`, `affliction_tracking_core/007`), one step per application: if it believes a caloric defence up it strips that and records nothing more; otherwise it records shivering when it does not already believe the target shivering (30%), and frozen only when it does. 005 sends frozen BEFORE shivering, so our hypothermia line adds frozen to V3 only on a target V3 already believed shivering and without a caloric defence; anywhere else V3's frozen belief stays as it was (`tAffs.frozen` is set, but P3 and P7 read V3). The offense's own hypothermia (P7) is cast only at frozen >= 0.5, so V3 keeps that frozen. A hypothermia the offense did not choose (typed by hand, say), at a target V3 did not believe frozen, can leave V3 with hypothermia and shivering and no frozen, although the line proves frozen (hypothermia needs a target "already frozen", WIKI :182), and P3 then will not glaciate until a later freeze records frozen. Since v4.7.420 005 no longer sets the `st.hypothermia` latch: nothing has read it since v4.7.419, and it outlived the target's cure, since only a target change or `mm reset` cleared it.
- **`enamation/`** (001-004): emanation triggers, all four of which fire on this user's 119-124-column wrap. Every emanation line is wider than that (about 150-180 columns with an ordinary name), so each trigger matches an opening fragment of 67-84 columns and highlights that row cyan, then joins as many following rows as it needs (`tempLineTrigger(1, 1, ...)`, at most two) until the sentence has closed, and reads the target's name from the joined text. The name check stays (`tgt == target`): every row of our own cast is highlighted, whoever it hit, but only a cast at our target records. Water (002) has worked this way since v4.7.419, and fire (001), air (003) and earth (004) since v4.7.420. Before, those three were full-line patterns folded across two YAML lines, 135-144 columns even with one-letter names, which `tools/check_wrap.py` cannot see (kb/CONFLICTS.md #2), so none of them ever fired on this wrap. In fire, air and earth the name sits mid-sentence, so it is read with the old pattern's tail (fire: `staff to point at (%w+) and unleash a stream of searing flame%.`). Each fragment is the start of the old pattern and each tail its end, so on a wide screen they accept every line the old patterns accepted (fire and earth also a staff described in more than one word), and if the real tail differs from the old pattern nothing records, as before; no emanation line is captured in `kb/raw`, so the fragments and tails are the old patterns' words. Only air's fragment names the staff, as `an? \w+ staff` (one word before "staff", as the old pattern had); fire's and earth's stop before it. On our target each records:
  - **Water (002):** the freeze stage (insulation strip `nocaloric`, shivering, or frozen), disrupted and stuttering.
  - **Fire (001):** two burns on the offense's counter (capped at 5, mirrored to `tburns`), ONE `tarAffed("burning")`, the relay and the `[n/5]` echo. The wiki's two ablaze stacks go to the counter, and V3 is given one, on purpose (next bullet).
  - **Air (003):** paralysis and dizziness, and since v4.7.420 asthma as well when V3 already believed the target dizzy before this cast (`haveAff("dizziness")`, V3 >= 30%), from the wiki's "If they already have dizziness, they will be given asthma instead" (WIKI :242). The relay then reads `(Paralysis + Asthma)`. Dizziness is recorded either way, since a dizzy target keeps it, and a false dizziness belief gives a phantom asthma (002's freeze ladder has the same exposure). The wiki's short stun is not recorded: no duration is given, stun is not in the game's AFFLICTION LIST, and nothing reads a target's stun.
  - **Earth (004):** `magi.calcifying_head = true` and the relay `<target>: Emanation Earth (calcifying)`, no affliction. The wiki's earth emanation calcifies the TORSO (WIKI :242); the flag says head, and nothing reads it (the skull line clears it, in 026 and `002_Calcify_Head_Finish`). A calcified torso is recorded only by `026_Calcify`'s torso pattern, and no capture shows whether the emanation prints that line (UNVERIFIED), so after our earth emanation `st.calcifiedTorso` may stay false for everything that reads it (P5, P6, P10 through `countMendingAffs`, P11, the meteorite pick, the lock and salve branches, and `mm` status). `026_Calcify`'s first pattern is the same earth-emanation line as a whole anchored line (Key Files).
- **Why V3 holds one of the fire emanation's two stacks** (a known gap since v4.7.420, handed to the V3 core). V3 raises its burning level by one per application (`applyAffV3`, `affliction_tracking_core/007`, capped at 5). A body mending cures burning only while that level is 1 or less (`onSalveCureV3`), and sets the level back to 0 only when burning was the one body-salve affliction it could cure; when it cures something else, or cures burning in one branch of several, the level stays. Nothing lowers a higher level: `erAff` leaves it (025's erase when its counter reaches 0 among them), and only a full reset of the tracker (`resetStatesV3`: a target change, the target's death, a disconnect, among others) clears it. A second application would therefore leave a burning that outlives every mending. The price of one: after a single body mending (391) on a target whose only body-salve affliction was the emanation's burning, V3 reads no burning and `selectSpell`'s stale-state check zeroes `st.burns`, while a stack may remain. The rule bites burns from every spell: any two burning applications on one target leave V3 a burning that no mending clears, unless in between a body mending cured the first as the only body-salve affliction it could cure. So a burn already on the target when the emanation lands has the same result. The game's records describe ablaze as cured stack by stack: conflagration ends by "curing all stacks of the ablaze affliction present upon you", and "ablaze may not be cured below the intensity of the pyre's own stacks" (AFFLICTION SHOW conflagration and pyre, CONFIRMED); how many stacks one mending removes is not stated (UNVERIFIED). Recording both stacks waits on V3 counting a mending down one level; `test_magi_emanations.lua`'s last test guards it (kb/CONFLICTS.md, "Ablaze stacks in the tracker").
- **`staffcast/`**: 001 water bonds off; 002 water bonds on, recording `waterbond` for 15-45 s by how cold the target is (the Glacial crystal's durations, WIKI Artificing.wiki:82), though it tests `tAffs.shiving`, a misspelling, so the 35 s shivering case never applies; 005 "Immolation Staff", whose pattern is a scintilla staffcast line, sets `timmolation`, which nothing reads. **002 and 005 are folded full-line patterns, 134 and 127 columns with one-letter names, so on this user's 119-124 wrap they cannot match** (kb/CONFLICTS.md #2). Lock mode's first branch casts horripilation until V3 shows waterbond, blistered, paralysis or anorexia, or `st.calcifiedTorso` is set (fulminate instead at fire 2), so on a wrapping screen `cc` keeps casting horripilation unless one of the others lands.
- **`vibes/`**: vibration listing and the `evibe` embedding chain
- **Uncaptured lines with open questions.** No Magi trigger line of OURS is captured in `kb/raw`; Tabethys's log (`kb/raw/logs/2026-10-19_tabethys_magi-group_kalys_o6UKnyyy.txt`) holds some game lines (the dehydrate, fan, temperance, stormhammer and diminish lines) and gags the resonance ones. Two matter: (1) `021_Freeze`'s `^You rip the heat from (\w+)\.$` is called FREEZE, but the file was "Dehydrate - Frozen" until b48b6603 and `021_Spell_Outcomes`' comment still lists it as a dehydrate outcome; if it is dehydrate's freeze stack, one dehydrate on a nauseous target advances the freeze ladder twice (015 + 021). (2) the fan line: settled for a weary dehydrate in v4.7.429 (one stack, one line, counted once), open for the other sources (#37). Settle (1) by logging one FREEZE and one DEHYDRATE on a nauseous target (kb/CONFLICTS.md #30). Three more since v4.7.420: (3) the fire, air and earth emanation triggers read tails taken from their old patterns (air's, `picking up (%w+) and dashing them violently about before casting them back to the ground%.`, is the longest), which only a capture of each emanation, wrapped, can confirm; (4) whether the earth emanation prints `026_Calcify`'s torso line; (5) 025's fires-diminish line DOES print after a body mending (Tabethys's log :412-413), so since v4.7.430 391 no longer lowers the counter. (3) and (4): kb/CONFLICTS.md, "What the fire, air and earth emanations print"; (5): "Ablaze stacks in the tracker".

### Key Trigger Patterns
- **Burns tracking**: Counter 0-5, `magi.offense.state.burns` + backward-compat `tburns` global. Every trigger that raises, lowers or zeroes it is listed in the fire route's pipeline step 2
- **Fulminate smart chain**: fulminated → epilepsy → paralysis (state-based via `haveAff()`)
- **Scintilla**: Two-phase — spark (4s timer) then ignition (burning + burns++)
- **Scalded**: `ataxia_tarAffTimed("scalded")` (20 s on the shared target clock, `017_Affliction_Management.lua`) plus the offense's own 20 s `st.scalded` timer (`magi.offense.setScalded()`), from the magma line (021_Spell_Outcomes) or moderate fire on an unscalded target (022)
- **Blistered**: `ataxia_tarAffTimed("blistered", 15)` from major fire (022, v4.7.419). The 15 s has no source: AFFLICTION SHOW gives blistered no default time
- **Calcified torso**: Trigger-based clear (026_Calcify fade pattern), not timer-based
- **Erode**: Multiline trigger (015_Erode, `conditonLineDelta: 3`) parses defense name from followup line and erases `shield` regardless. Its name map holds caloric but neither insulation nor temperance (the wiki's ERODE list: shield, chargeshield, insulation, temperance, WIKI :74), and it records no `nocaloric`, the offense's insulation-down flag, for any of them. Which word the strip line prints is UNVERIFIED
- **Freeze**: 021_Freeze.lua — one stage per line (strip, shivering, frozen); frostbite + insulation records the strip and the next stage
- **Long lines**: a pattern must fit on one wrapped row (CLAUDE.md, v4.7.351). 022 and all four emanation triggers match an opening fragment and read a name that falls past the wrap from the following rows with `tempLineTrigger(1, 1, ...)`, at most two more rows (022 and water v4.7.419; fire, air and earth v4.7.420). Where the name sits mid-sentence (fire, air, earth), the rows are joined until the sentence closes and the name is read with the old pattern's tail
- **Emanation triggers**: an opening fragment, the name read from the closed sentence, and the target check kept (`tgt == target`); no staff name is hardcoded (only air's fragment names the staff, as `an? \w+ staff`). What each records, and why the fire emanation gives V3 one burning: Trigger Architecture

### Commands
| Alias | Action |
|-------|--------|
| `zz` | `magi.offense.setMode("salve"); magi.offense.dispatch()` (`152_First_Attack`) |
| `xx` | `magi.offense.setMode("fire"); magi.offense.dispatch()` |
| `vv` | `magi.offense.setMode("water"); magi.offense.dispatch()`. Water has no branch: this runs the fire tree |
| `cc` | `magi.offense.setMode("lock"); magi.offense.dispatch()` |
| `sr` | `magi.offense.setMode("group"); magi.offense.dispatch()` |
| `srr` | Stormhammer direct fire: `magi.storm.selectTargets()` + `magi.storm.fire()`, or a plain `cast stormhammer at <target>` if the storm module is missing (`157_Scytherus`) |
| `mm` | Show full status (mode, resonance, burns, scalded, calcify, shalestorm, hypothermia, frozen, arach, web). Hypothermia and frozen are read from V3, as P3 and P7 read them (v4.7.419; hypothermia used to include the `st.hypothermia` latch, which outlives a cure) |
| `mm fire/water/lock/salve/group` | Set mode (no dispatch) |
| `mm debug` | Toggle debug echo |
| `mm vibes` | Set the wanted vibration list to the default PvP eight. Embeds nothing: use `evibe` |
| `mm reset` | Reset all offense state |
| `mm arach` / `mm arachnideye` | Toggle arachnideye trample prefix |
| `mm web` / `mm webbomb` | Toggle webbomb prefix |
| `mm storm` | Cycle the stormhammer target mode (city / all / priority). In every mode our target goes in slot 1 when gmcp lists it in the room (v4.7.429) |
| `mm echo [on\|off]` | Toggle the compact echoes (`You: <Spell> -> X`, `<Plane>: <Stage> -> X`) and the prompt's stage word (v4.7.429, default on, not saved) |
| `evibe` | Embed the wanted vibrations not already in the room, one at a time |
| `vibe <name>` | Add or remove one vibration in the wanted list |
| `vib` | Embed a fixed five: dissonance, disorientation, creeps, plague, harmony |

### Dispatch Guard Chain
```
1. Class check (gmcp.Char.Status.class == "Magi")
2. Balance + equilibrium gate
3. Aeon check
4. Target validation
5. Update resonance from GMCP
6. Sync firestorm state from legacy global
7. selectSpell() → sendAttack()
```

### sendAttack() Flow
```lua
-- Output format:
-- queue addclearfull freestand [utility_prefix::]stand::wield staff shield::spell::assess target
```

### Backward Compatibility
Old function names still work via wrappers:
- `MagiMain()` → fire mode dispatch
- `MagiLock()` → lock mode dispatch
- `MagiWaterFocus()` → water mode dispatch (runs the fire tree)
- `MagiFireNew()` → fire mode dispatch
- `MagiSalveFocus()` → salve mode dispatch

Legacy globals: `tburns`, `tfirelash`, `timmolation`

### V3 Affliction Tracking Integration
| Helper | Purpose |
|--------|---------|
| `magi.offense.hasAff(aff)` | Routes to `haveAff()` → V3 at 30% threshold |
| `magi.offense.getAffProb(aff)` | Routes to `getAffProbabilityV3()` (0.0-1.0) |
| `magi.offense.hasShield()` | V1 fallback for rebounding+shield (GMCP timing gap) |
| `magi.offense.targetShielded()` | V1 fallback for shield only |

### Target Change Reset
Registered via `registerAnonymousEventHandler("changed target", ...)` (the old ID is killed first, so a reload does not stack handlers). It calls `magi.offense.reset()`: burns, conflagrated, scalded, calcify, shalestorm, scintilla spark, the hypothermia latch (which nothing sets since v4.7.420), frozen and shivering. `mm reset` calls the same function.

---

## Bashing (PvE) — the basher (`ataxiaBasher_magi*`)

The PvE hunting path is **separate** from the `magi.offense` PvP system above. It runs through the shared `ataxiaBasher` engine, dispatched by class. Resonance is only generated against an adventurer in your room (WIKI, Elementalism.wiki:62), so none of the resonance machinery applies to a denizen. Two layers fire each cycle: the **equilibrium attack** (`ataxiaBasher_magiBashing`, `basher/002_Class_Bashing.lua`) and the **battlerage rotation** (`ataxiaBasher_magiBattlerage`, `basher/001_Bashing_Functions.lua`), which use different balances (eq vs Rage) and so fire together.

### Equilibrium attack — `ataxiaBasher_magiBashing()` (`basher/002`)
Priority order (first match wins; all except Bloodboil append the battlerage prefix `brage`):

1. **Bloodboil** (top priority) — `cast bloodboil` when `ataxiaBasher_magiShouldBloodboil()` holds. It's a **main skill** (Elementalism, 75 mana, 4s eq), NOT a battlerage — it takes the eq slot from the staff bash while battlerage (Rage) still fires; `addclearfull`-queued so it self-dedups until eq returns. Two independent reasons, both requiring mana ≥ 75 and not haemophilic (the cast fails under it):
   - **CURE** — 3+ **real** afflictions while **our own** tree tattoo is on balance (`ataxiaTemp.usedTree`). Set on **both** tree-fire lines — "You touch the tree of life tattoo." (`curing_bals/003`, a successful cure) **and** "Your tree of life tattoo glows faintly… leaving you unchanged." (`curing_bals/001`, a cooldown-consuming fire that cured nothing) — and cleared on "You may utilise the tree tattoo again." (`curing_bals/004`). The 001 line is the one SSC actually emits during bashing, so without it latching `usedTree` the whole cure branch was dead (found in review). **Not `tBals.tree`** — that tracks the *target's* tree and is reset to `true` on every denizen target-change/kill. The count skips `incoming_*` predictions and cured-to-0 stacks; blindness/deafness/insomnia are never stored so bashing blind/deaf doesn't inflate it.
   - **HEAL** — with the **Hot Springs boon** (Mnemosyne), Bloodboil also heals **25% max health + 5% willpower** (the boon has its own 30s internal cooldown) — a bashing heal like the Shaman's `invoke regeneration`. Fires purely on **HP% < 60**, with **no client-side cooldown**: a self-managed cd would flip the branch off mid-eq-wait and let the 0.3s `addclearfull` re-queue clobber the pending `cast bloodboil` before it lands (consuming the cd without healing). The HP threshold self-regulates; casts that land while the boon's own cd is up still cure an affliction. Flag `magiHotSprings`, wired 1:1 with the other Mnemosyne boons.
2. **Shielded** → `cast erode at <t>` — Erode is Magi's *free* shield strip (all-four utility spell), which is why the battlerage **never fires Disintegrate** (17 Rage on a shield break is the worse trade — the Monk shatter-over-spk rule). Strip FIRST, then battlerage, so a still-up shield doesn't absorb the BR.
3. **Aspect of Kkractle boon** (Mnemosyne) → `elemental surge` — with this boon, Elemental Surge (normally the ashbeast's water-construct destroyer) becomes an **AoE fire nuke on every denizen in the room** (no target). Flag `magiKkractle` set by the BOONS-list trigger + boon-claim alias, reset each run — wired 1:1 with `bmShatteredStar`. Requires a summoned ashbeast up.
4. **Stormhammer AoE** — `cast stormhammer at <t1> and <t2> and <t3>` when `ataxiaBasher_validTargets() > 2` and `#stormhammerTargets >= 3` (3-target cap).
5. **Single target** → `staff cast horripilation at <t>` (default).

`ataxiaBasher_magiStormPrep()` (stormhammer targeting + GUI) is split out and pre-called once by the autobash loop (`genrunning/004`); `magiBashing` is invoked twice per cycle (that pre-call + the real send), so the prep must NOT run the battlerage — see the double-call note in AGENTS.md.

### Battlerage rotation — `ataxiaBasher_magiBattlerage(sp)` (`basher/001`)
Rage-powered; Magi **owns culling** (excluded from the shared culling check so `reap` fires here, not over the rotation). PvP-inert (`type(target) ~= "number"` early return); respects the ~1s global BR cooldown. Priority:

| # | Ability | Rage | Gate | Cast syntax |
|---|---------|------|------|-------------|
| 1 | **Culling reap** | 36 | `cullingBlade` on, off-cd, not World Tree | `reap <t>` |
| 2 | **Dilation → Aeon** | 35 | in Mnemosyne, target not aeon'd (mitigation — mob attacks slower) | `cast dilation at <t>` |
| 3 | **Firefall** | 25 | target clumsy or recklessness (from ANY source — Magi applies neither) | `cast firefall at <t>` |
| 4 | **Stormbolt → Sensitivity** | 25 | target not already sensitive (+33% dmg taken; sets up Squeeze) | `cast stormbolt at <t>` |
| 5 | **Squeeze** | 36 | off-cd (hits harder while Sensitivity up) | `cast squeeze <t>` |
| 6 | **Dilation surplus** | 35 | outside Mnemosyne, not aeon'd | `cast dilation at <t>` |
| 7 | **Windlash** (filler) | 14 | off-cd — spends leftover Rage so it never idles | `cast windlash at <t>` |

**Cast syntax:** all `cast X at <t>` **except Squeeze** (`cast squeeze <t>`, no "at"). Confirmed vs AB.
**Cooldowns (AB-confirmed):** Windlash 16s, Dilation 35s, Squeeze 23s, Firefall 23s, Stormbolt 27s. Squeeze uses the real shared `battleRage_Timers.large` (trigger 331 tracks "vice-like squeeze"); the rest have no fire-line trigger, so they use reload-safe timestamps `ataxiaTemp.magi*ReadyAt` (Windlash included — without a gate it re-fires a doomed cast every prompt for 16s). Dilation/Stormbolt also gate on their affliction so they skip when it's already up from another source.
**Never fires Disintegrate** (`raze` slot is config-complete but dead — Erode strips shields for free).

### Ashbeast (do-not-kill)
Magi's Artificing fire summon shows in "Denizens Here" as **"a blazing ashbeast"**. It is on the basher `ownDenizens` ignore list (`002_Check_For_Any_Missing_Variables.lua`) so it's never auto-learned or targeted (seeded default + back-filled into old saves).

### Reload-safety
`battleRage_Timers`, `tBals`, and `bashStats` are created only inside `levilogin()`, so a SYSUPDATE/reload that doesn't re-fire login left them nil and crashed the always-live bashing path. All now have load-time idempotent inits at the top of `basher/001` (and `basher/003` for bashStats). See AGENTS.md → "Reload-safety".

### Still needs in-game capture
- **Stormbolt Sensitivity land-line** (apply: `…inciting sensitive nerves across his skin`; fade: `The lightning cracking around <denizen>'s sensitive skin fades away`) — to add the denizen-state capture so the rotation skips Stormbolt when Sensitivity is already up.
- Confirm Dilation prints the existing aeon line (trigger 015) vs a new one.

---

## Fighting Against This Class
```yaml
# Cures are CONFIRMED (AFFLICTION SHOW, kb/raw/live/affliction_show/). Corrected 2026-10-12:
# scalded, ablaze and frostbite were given the wrong cures here.
priority_cures:
  - frozen / shivering / frostbite: "APPLY CALORIC (all three). Frozen is all glaciate needs; frostbite makes the next freeze strip your insulation AND land"
  - hypothermia: "APPLY RESTORATION to the body - until then you cannot cure frozen"
  - burning (ablaze): "APPLY MENDING to the body - two stacks is conflagrate's condition"
  - scalded: "Nothing cures it (time, 20 s). It slows your salve recovery, and while it is up their moderate fire sets you ablaze"
  - blistered: "Nothing cures it (time). It limits your movement"
  - fulminated: "EAT GOLDENSEAL/PLUMBUM - while it is up, every successful FOCUS paralyses you"
  - asthma: "EAT KELP/AURUM - while it is up you cannot smoke, so slickness can only be eaten off"
  - haemophilia: "EAT GINSENG - restore clotting"
  - sensitivity: "EAT KELP - reduce their damage"
  - calcified_torso: "APPLY RESTORATION to the body before it completes, or the torso takes extreme damage"

dangerous_abilities:
  - destroy: "Instant kill when conflagrated + 40% health or less (WIKI)"
  - glaciate: "'terrible damage upon those that are already frozen' (WIKI); frozen is its only stated requirement"
  - mudslide: "At the right resonance one cast gives slickness, prone, a short stun, paralysis and anorexia (Tabethys's 'bonk')"
  - stormhammer: "High damage to up to 3 targets"
  - conflagrate: "Massive burn damage setup (two ablaze stacks)"
  - emanation_earth: "Calcifies your torso; slays you outright if you have serious internal trauma (WIKI)"
  - emanation_water: "Strips insulation (or freezes you a level), disrupts you and gives stuttering (WIKI)"
  - shalestorm: "Persistent earth damage with limb breaks"
  - convergence: "Bypasses shields at dissonance stage 4"

avoid:
  - "Letting burns stack to 2+ (conflagrate threshold)"
  - "Staying frozen: glaciate needs nothing else (their water and air resonance is not a stated requirement)"
  - "Standing in rooms with embedded vibrations"
  - "Letting the common opener (magma, dehydrate, dehydrate, fulminate) run to the mudslide on the fifth cast"
  - "Low health when conflagrated (destroy instant kill)"
  - "Letting shalestorm run unchecked (auto-triggers scintilla sparks for calcify pressure)"

recommended_strategy: |
  Apply caloric for frozen, shivering and frostbite, and mending for burning, as early as you can;
  scalded and blistered only wear off.
  Eat kelp for asthma (frostbite is caloric, not kelp).
  Eat goldenseal for fulminated before you rely on FOCUS: while it is up a successful focus paralyses you.
  Leave rooms with embedded crystals when possible.
  The common opener is four casts (about 9.3 s of equilibrium) before the mudslide, and it keeps your
  eating balance busy (nausea, weariness, fulminated, asthma); break it before the fifth cast.
  Watch for meteorite shield-strip variants (they adapt to resonance state).
  Haemophilia is their class lock aff — cure with ginseng.
  Strip shalestorm if possible — it provides free limb breaks and enables scintilla automation.
```

---

## Reference Files
**None of the four files below is at that path any more (checked 2026-10-12).** The game text for this class is in `kb/raw/wiki/Elementalism.wiki`, `Crystalism.wiki` and `Artificing.wiki` (WIKI), `kb/raw/live/affliction_show/` (CONFIRMED) and `kb/raw/players/magi-tabethys-2026-10-12.txt` (PLAYER).
- `C:\Users\mikew\Downloads\xMagi.lua` — Aegoth/Tabethys decision tree (fully implemented). Its authorship is recorded three ways (see Tabethys's core rotation), and its glaciate gate cannot now be checked
- `C:\Users\mikew\Downloads\magi2.mpackage` — State-tracking triggers (fully implemented)
- `C:\Users\mikew\Downloads\magiaddtriggs.mpackage` — Display-only duplicates (no tracking value)
- `C:\Users\mikew\Downloads\ExpertDiagnoser.mpackage` — Generic target cure tracking system (equivalent to V3)
