# My Artefacts (Personal Inventory)

Quick reference of artefacts I currently own, organized by combat utility. **74 power rows** in the game's
`ARTEFACT POWER LIST OWNED` (pasted 2026-11-13, verbatim in `kb/raw/live/artefact_power_list_owned_2026-11-13.txt`;
Suremekh'neina holds two powers), plus the Shadowcloak and the wand of reflection, which have no power row.
The Aldar Diadem is worn at all times (the user, 2026-11-13).

## What our code reads (v4.7.494)

The package reads the player's OWN list (triggers 802/803, `misc_scripts/033_Artefacts.lua`; `aconfig artefact`
shows it), never this page, because it goes to other players. Each size below is from
`docs/artefacts-reference.md` until `kbcapture artefacts` files the game's `ARTEFACT POWER SHOW` text in
`kb/raw/artefacts/`.

| Power | Ours | Changes code at | Not yet |
|---|---|---|---|
| faster_eq | Aldar Diadem, 2 | `ataxia_eqFactor` / `ataxia_eqSeconds` (033): x0.85, Rain x0.85 more | -- |
| hand_to_hand | spiked knuckles, 3 | `tekura6.classifyHit` (tekura/002) learns the punch from our hits; `tekura.punchDamage` (tekura/001) reads it | -- |
| swiftcurse | sapphire skull pendant, 3 | the stand-in curse count, 10 + 6 (trigger shaman/011, genrunning/004); trigger 012 still gives the game's count | +3 s JINX duration |
| enhanced_shin | eagle feather | -- | HAMSTRING +5 s (Release B, after the capture confirms it) |
| tuning | silver tuning fork | -- | Bard symphony timer x2 (Release B) |
| magic_damage, criticals, weaving_mastery | Collar 3, Stygian pendant 3, mirror 3 | -- | no damage-kill threshold counts them (below) |
| rapid_resonation, symphonic_master, swift_runes, faster_mindlock | haematite, insignia, runestone, Intellect Crown | -- | docs only (`.claude/classes/<class>.md`) |
| the rest | | -- | not modelled (`A.EFFECTS` in 033 names each) |

---

## Combat - Core Stats & Balance

| ID | Name | Power | Lvl | Effect |
|----|------|-------|-----|--------|
| 385702 | Aldar Diadem | faster_eq | 2 | 15% faster equilibrium recovery |
| 582367 | Armband of Celerity | celerity | - | Extra move/second before "Don't be hasty" |
| 239371 | Stygian pendant | criticals | 3 | +6% critical hit chance |
| 286876 | Logosian Gauntlets | strength | 3 | +3 STR (also falconry glove) |
| 472383 | Pixie's Boots | dexterity | 3 | +3 DEX |
| 300800 | Girdle of Aegis | constitution | 3 | +3 CON |
| 473632 | Sash of Wisdom | intelligence | 3 | +3 INT |
| 270681 | Logosian ring | health_sip | 3 | +30% health elixir healing |
| 73932 | ring of Lunastra | mana_sip | 3 | +30% mana elixir healing |
| 281763 | Suremekh'neina | health_regen | 3 | Level 3 passive health regeneration |
| 281763 | Suremekh'neina | mana_regen | 3 | Level 3 passive mana regeneration |
| 42655 | Band of Tenacity | endurance_regen | 2 | Level 2 endurance regeneration |
| 45985 | Circlet of Determination | willpower_regen | 2 | Level 2 willpower regeneration |
| 299421 | Logosian Bracelets | reserves | 3 | +15% max health AND mana |
| 608088 | Sash of Eternal Battle | reduced_endurance | - | 33% less endurance drain in combat |

## Combat - Offensive

| ID | Name | Power | Lvl | Effect |
|----|------|-------|-----|--------|
| 290626 | spiked knuckles | hand_to_hand | 3 | +35% Tekura punch dmg, +20% Maul dmg |
| 264902 | steel armband of the Fist | tekura_accuracy | 3 | +20% Tekura punch/kick accuracy |
| 405405 | peerless insignia of finesse | weaponmastery_spec | 3 | Switch weaponmastery specialization hourly |
| 151113 | Bracers of Flame | fire_mastery | - | FIRELASH, FIREWALL abilities + tinderbox |
| 417868 | Bracers of Frost | frost_mastery | - | FREEZE, DEEPFREEZE, ICEWALL abilities |
| 178446 | Collar of Agatheis | magic_damage | 3 | +20% magical attack damage |
| 630835 | sapphire skull pendant | swiftcurse | 3 | +6 SWIFTCURSE curses, +3s JINX duration |
| 370963 | shiny charm | insidious_gaze | - | Gaze attacks ignore reflections |
| 329803 | vambraces of the Berserker | battlerage_decay | - | Slower battlerage decay |

## Combat - Defensive

| ID | Name | Power | Lvl | Effect |
|----|------|-------|-----|--------|
| 83971 | Brooch of the Tempest | stability | - | Prevents wind blowing you off course when flying |
| 447372 | prismatic ring | elemental_resistances | - | ACTIVATE <type> RESISTANCE (fire/cold/electric/magic) |
| 351860 | buckawn's amulet | anti_web | - | Immune to web tattoo attacks and thrown web bombs |
| 244278 | Shadowcloak | shroud | - | Grants SHROUD ability when worn |
| 578658 | Anake's Hood | anti_spying | - | Blocks eavesdrop: grove watch, mind listen, puppetry listen |
| 395139 | talisman of obfuscation | conceal_illusions | - | Reduces lifevision effectiveness by 33% |
| 417212 | ring of the Magus | magic_defence | - | ~15% magic damage protection |
| 234800 | wand of reflection | reflections | - | Grants reflections 1x/hour; absorb attacks (aggressive actions destroy all) |

---

## Class-Specific Artefacts

### Monk

| ID | Name | Power | Lvl | Effect |
|----|------|-------|-----|--------|
| 440733 | pink lotus blossom | monk_switch | - | Switch Tekura/Shikudo free every 12hr (needs Trans Tekura) |
| 264902 | steel armband of the Fist | tekura_accuracy | 3 | +20% Tekura punch/kick accuracy |
| 290626 | spiked knuckles | hand_to_hand | 3 | +35% Tekura punch dmg, +20% Maul dmg |

### Blademaster

| ID | Name | Power | Lvl | Effect |
|----|------|-------|-----|--------|
| 422142 | Bracers of the Phoenix | shin_drain | - | Slows shin energy decay rate |
| 456282 | ethereal lightning eagle feather | enhanced_shin | - | +ANNIHILATE throw chance, +5s HAMSTRING duration |

### Magi/Elemental

| ID | Name | Power | Lvl | Effect |
|----|------|-------|-----|--------|
| 417212 | ring of the Magus | magic_defence | - | +10% magic damage resistance |
| 442098 | gem of haematite | rapid_resonation | - | 50% less eq for crystalism embedding |
| 442748 | waterlogged gauntlet | surging_waves | - | +2 max range on WAVESURGE |

### Runewarden

| ID | Name | Power | Lvl | Effect |
|----|------|-------|-----|--------|
| 421738 | rough runestone | swift_runes | - | 33% faster rune sketching |
| 421746 | Runic Gauntlet | totems | - | Runewards: sketch faster. Shaman: see Shaman section |

### Bard

| ID | Name | Power | Lvl | Effect |
|----|------|-------|-----|--------|
| 75993 | glass rose | pure_song | - | 2x ARIA duration on targets (including self) |
| 563418 | moon-and-star insignia | symphonic_master | - | 50% faster eq when PLAY harmonics (incl. symphony) |
| 396580 | silver tuning fork | tuning | - | 2x lifetime for Crystalism/Harmonics/Devotion vibrations/rites |

### Psion

| ID | Name | Power | Lvl | Effect |
|----|------|-------|-----|--------|
| 170775 | Intellect Crown | faster_mindlock | - | 40% faster MINDLOCK time |
| 202898 | Ursine Band of Mind Distension | mindprint_capacity | 1 | +3 MINDPRINT slots |
| 91910 | synaptic lock | silent_telepathy | - | Target not alerted when mindlock breaks + MIND CLOAK |

### Occultist

| ID | Name | Power | Lvl | Effect |
|----|------|-------|-----|--------|
| 419287 | funereal amphora | desert_sorcerer | - | +10% chaos damage, faster instill |
| 485994 | Shar'ilian lightspire | illusion | 2 | L2 illusion staff: 1000 char limit, color, area/continent illusions |

### Infernal/Apostate

| ID | Name | Power | Lvl | Effect |
|----|------|-------|-----|--------|
| 332303 | preserved hand | grasping_death | - | +50% GRAVEHANDS duration (not soulspear hands) |

### Depthswalker

| ID | Name | Power | Lvl | Effect |
|----|------|-------|-----|--------|
| 616281 | sorcerer's notebook | sorcerous_insight | - | Shadow damage shows target afflictions |

### Earthlord (Elemental Lord)

| ID | Name | Power | Lvl | Effect |
|----|------|-------|-----|--------|
| 637029 | gaze of the Cacharann | primordial_fury | - | TITAN +5s duration, -30% cooldown |
| 637043 | morsel of bonemeal | unyielding_stone | - | +10% POWDERISE limb damage |
| 637022 | cracked wheel | unending_avalanche | - | ROCKSLIDE rubble persists 50% longer |

### Shaman

| ID | Name | Power | Lvl | Effect |
|----|------|-------|-----|--------|
| 630835 | sapphire skull pendant | swiftcurse | 3 | +6 SWIFTCURSE curses, +3s JINX duration |
| 421746 | Runic Gauntlet | totems | - | Faster totem implant/uproot, -50% own uproot, -25% others' uproot |

### Jester

| ID | Name | Power | Lvl | Effect |
|----|------|-------|-----|--------|
| 264718 | golden cube | jester_props | - | Jester props (added 2026-11-13 from the power list; effect not yet captured) |
| 451118 | Gloves of Serendipity | bomb_duplication | - | Bomb duplication (added 2026-11-13 from the power list; effect not yet captured) |

### Sentinel

| ID | Name | Power | Lvl | Effect |
|----|------|-------|-----|--------|
| 396923 | braided length of weasel offal | falcon_self_sufficiency | - | Falcon doesn't need feeding |

### Weaving (Psion)

| ID | Name | Power | Lvl | Effect |
|----|------|-------|-----|--------|
| 539566 | platinum hand mirror | weaving_mastery | 3 | +20% weaving damage (not unweave ticks) |
| 422392 | ephemeral shuttle | resilient_miriads | - | +1 hits to disperse miriad (via indomitability) |

---

## Utility & Travel

| ID | Name | Power | Lvl | Effect |
|----|------|-------|-----|--------|
| 299122 | Anklet of Dashing | dash | - | DASH ability - instant room movement |
| 236878 | chitin greaves | leap | - | LEAP ability - jump over obstacles/walls |
| 536688 | ring of flying | flying | - | Permanent flight without wings |
| 582366 | flying carpet | entourage | - | Followers can fly with you |
| 338075 | mithril spurs | quickmount | - | Faster mount balance + vault with no balance loss |
| 455735 | Prospero's Greater Vault | rift_expand | 2 | 4x rift capacity (quadruple) |
| 477008 | vibrating stick | wormholes | 1 | Access to wormhole travel network |
| 440716 | oval mask | lifevision | - | See health percentages of everyone in room |
| 503549 | Hood of the Sphinx | sphinx | - | FULLSENSE (see all adventurers in area) + expanded FARSEE |
| 506719 | glittering fishscale tunic | breathe_underwater | - | Permanent underwater breathing |
| 580744 | miniature toolkit | trapmaster | - | TRAPS and DISARM abilities (auto-success if Sentinel/Jester) |
| 212547 | stone of lesser lorewarden | class_switch_reduction | 3 | Class switch cooldown reduced to 1 minute |
| 572302 | quill of inscribing | faster_inscribe | - | Faster tarot inscribing (added 2026-11-13 from the power list) |
| 616781 | painted lantern | faster_commune | - | Faster COMMUNE (added 2026-11-13 from the power list) |

---

## Crafting & Economy

| ID | Name | Power | Lvl | Effect |
|----|------|-------|-----|--------|
| 72918 | Phaestean Faucet | fluid_expansion | 3 | 4x liquid rift capacity (quadruple) |
| 279190 | prospector's almanac | mine_capacity | 2 | +2 mine ownership capacity |
| 560673 | Prosperian attractor | gold_attractor | - | Gold from kills goes directly to inventory |
| 422098 | sand-worn bandolier | jars_capacity | - | +5 jar slots for alchemist |
| 421731 | wax stick encased in mithril | water_sketch | - | Sketch runes on water surfaces |

---

## Shop of Wonders (Mayan Crown Items)

| ID | Name | Effect |
|----|------|--------|
| 408500 | scrying bowl | SCRY FOR <person> shows location AND area |
| 11333 | diamond-tipped shovel | 50% faster DIGging |

---

## The damage-kill thresholds (2026-11-13)

No threshold below counts our artefacts, and none was tuned for them. There are two kinds:
- **A game execute** has a fixed limit that the game sets. No artefact moves it.
- **A damage finisher** fires when our next hit should kill. Its number came with its first script,
  and no commit cites a log for it. Our damage artefacts can move it.

To change a finisher, first measure our own kill hits, as a percent of the target's health. Do not
multiply the number by a reference size.

| Threshold | Code | Kind | Where the number came from | Our artefacts that can move it |
|---|---|---|---|---|
| Magi DESTROY: conflagrated and health under 35% | `mage/004_Magi_Offense.lua`:71, :363 | game execute: a conflagration and 40% health or less (WIKI); 35 leaves a margin for an old ASSESS | the wiki | none |
| Mizik DESTROY: an ashbeast and health 40% or less | `mage/004_Mizik_Bullshit.lua`:37 | game execute, at the wiki's 40% | the wiki | none |
| Magi STORMHAMMER: health 25% or less (solo) | `mage/004_Magi_Offense.lua`:72, :400 | damage finisher (lightning) | commit 31595ff4 (2026-03-10), no log | Collar of Agatheis, Stygian pendant |
| Magi STORMHAMMER: health 50% or less (group) | `mage/004_Magi_Offense.lua`:658 | damage finisher; allies hit too | Tabethys's group log (ANOTHER PLAYER, 2026-10-19): a stormhammer at 51%, then the kill (`.claude/classes/magi.md`, "In play") | the same two; the allies' damage counts for more than ours |
| Mizik STORMHAMMER: health 25% or less | `mage/004_Mizik_Bullshit.lua`:32 | damage finisher | commit 678c1af0 (2025-12-27), no log | Collar of Agatheis, Stygian pendant |
| Apostate CATHARSIS: mana under 50% | `apostate/015_CC_Apostate.lua`:111, :536 | game execute (mana) | `.claude/classes/apostate.md` | none |
| Apostate CORRUPT: the estimate reaches the assessed health | `apostate/015_CC_Apostate.lua`:161-184, :541 | damage estimate: 7 per physical, 8 per mental and 9 per smoke affliction, each times its V3 probability | no source found | not known: no doc says what CORRUPT's damage scales with |
| Infernal DWC damage kill: QUASH + ARC at health 40% or less | `dwc/001_Infernal_DWC_Vivisect.lua`:167, :259, :892; `dwc/002_Infernal_DWC_Vivisect_2L.lua`:165, :245, :851 | damage finisher | commit b1bfd12e (2026-01-20), no log | Stygian pendant; the Logosian Gauntlets if ARC scales with strength (not confirmed) |
| Depthswalker CULL: health 35% or less | `depthswalker/015_CC_Depthswalker.lua`:72, :798 | damage attack ("deals high damage but is somewhat slow", WIKI) | commit c0568335 (2026-02-02), no log | Stygian pendant; the Logosian Gauntlets if scythe damage scales with strength (not confirmed) |
| Depthswalker MUTILATE: health 40% and mana 30% or less | `depthswalker/015_CC_Depthswalker.lua`:73-74, :792-793 | game execute | `.claude/classes/depthswalker.md` | none |

The sizes are reference values from `docs/artefacts-reference.md`, not the game's text:
- The Collar of Agatheis gives +20% magical damage. Which damage types it counts is not confirmed.
- The Stygian pendant gives +6% critical hit chance.
- The Logosian Gauntlets give +3 STR.
- The platinum hand mirror gives +20% weaving damage. No Psion threshold reads health, so it moves none.

---

## Verification Status

### Verified from Official Help Files
- All stat artefacts (STR/DEX/CON/INT L3)
- Health/Mana sip rings (L3), regen artefacts
- Crit pendant (6%), Aldar Diadem (15%), Celerity armband
- Offensive: hand_to_hand, tekura_accuracy, fire/frost_mastery, magic_damage
- Defensive: stability, elemental_resistance, anti_web, shroud, etc.
- Monk, Blademaster, Elemental Lord, Infernal, Shaman, Bard, Magi, Psion/Weaving artefacts

### Still Need Verification
- Runewarden: swift_runes (estimated 33%)
- Psion: faster_mindlock, mindprint_capacity, silent_telepathy
- Occultist: desert_sorcerer
- Sentinel: falcon_self_sufficiency
- Depthswalker: sorcerous_insight

---

## Wishlist (To Acquire)

| Item | Type | Notes |
|------|------|-------|
| cloak of the Blood Maiden | Talisman (Marks set) | Shadowcloak + BLOODSHIELD (blocks 1 attack). Needs 5 kills to charge (PK=2x). Depletes if no kill in 3min. Pieces: cloth, embroidery, lining, hood |
| Olivebranch | Talisman | |
