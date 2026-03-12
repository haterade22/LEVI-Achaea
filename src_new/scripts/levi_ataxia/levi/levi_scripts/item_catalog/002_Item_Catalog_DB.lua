--[[mudlet
type: script
name: Item Catalog Database
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- Item Catalog
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

--[[
    ============================================================================
    ITEM CATALOG DATABASE
    ============================================================================
    Knowledge base mapping item names to types, categories, powers, and effects.
    Sources: docs/artefacts-reference.md, docs/my-artefacts.md, in-game HELP files.

    Two lookup tables:
      itemCatalog.kb          — keyed by normalized item name (lowercase, no articles)
      itemCatalog.talismanKB  — keyed by talisman keyword (from TALISMAN LIST)

    Categories:
      combat_offense, combat_defense, combat_stats, class_specific,
      utility, travel, crafting, shop_of_wonders, housing, promo, paragons
    ============================================================================
]]--

itemCatalog = itemCatalog or {}

-- =============================================================================
-- ARTEFACT / ITEM KNOWLEDGE BASE
-- =============================================================================
-- Keyed by normalized name: lowercase, "a "/"an "/"the " stripped.
-- Fields: type, category, power, effect, credits (optional), tier (optional)

itemCatalog.kb = {

  -- =========================================================================
  -- OFFENSIVE ARTEFACTS
  -- =========================================================================

  -- Hand-to-Hand (hand_to_hand)
  ["brass knuckles"]                    = { type="artefact", category="combat_offense", power="hand_to_hand", tier=1, credits=350,  effect="+15% Tekura punch damage, +10% Maul damage" },
  ["silver knuckles"]                   = { type="artefact", category="combat_offense", power="hand_to_hand", tier=2, credits=800,  effect="+25% Tekura punch damage, +15% Maul damage" },
  ["spiked knuckles"]                   = { type="artefact", category="combat_offense", power="hand_to_hand", tier=3, credits=1600, effect="+35% Tekura punch damage, +20% Maul damage" },

  -- Tekura Accuracy (tekura_accuracy)
  ["leather armband of the fist"]       = { type="artefact", category="combat_offense", power="tekura_accuracy", tier=1, credits=250,  effect="+10% Tekura punch/kick accuracy" },
  ["iron armband of the fist"]          = { type="artefact", category="combat_offense", power="tekura_accuracy", tier=2, credits=500,  effect="+15% Tekura punch/kick accuracy" },
  ["steel armband of the fist"]         = { type="artefact", category="combat_offense", power="tekura_accuracy", tier=3, credits=1000, effect="+20% Tekura punch/kick accuracy" },

  -- Magic Damage (magic_damage)
  ["collar of ceylon"]                  = { type="artefact", category="combat_offense", power="magic_damage", tier=1, credits=500,  effect="+10% magical damage" },
  ["collar of diablerie"]               = { type="artefact", category="combat_offense", power="magic_damage", tier=2, credits=1000, effect="+15% magical damage" },
  ["collar of agatheis"]                = { type="artefact", category="combat_offense", power="magic_damage", tier=3, credits=2000, effect="+20% magical damage" },

  -- Weaponmastery Spec (weaponmastery_spec)
  ["insignia of finesse"]               = { type="artefact", category="combat_offense", power="weaponmastery_spec", tier=1, credits=200, effect="Switch weaponmastery spec every 6 hours" },
  ["shining insignia of finesse"]       = { type="artefact", category="combat_offense", power="weaponmastery_spec", tier=2, credits=400, effect="Switch weaponmastery spec every 3 hours" },
  ["peerless insignia of finesse"]      = { type="artefact", category="combat_offense", power="weaponmastery_spec", tier=3, credits=800, effect="Switch weaponmastery spec every 1 hour" },

  -- Fire/Frost Mastery
  ["bracers of flame"]                  = { type="artefact", category="combat_offense", power="fire_mastery", credits=400, effect="FIRELASH, FIREWALL abilities + tinderbox" },
  ["bracers of frost"]                  = { type="artefact", category="combat_offense", power="frost_mastery", credits=400, effect="FREEZE, DEEPFREEZE, ICEWALL abilities" },

  -- Misc Offense
  ["shiny charm"]                       = { type="artefact", category="combat_offense", power="insidious_gaze", credits=350, effect="Gaze attacks ignore reflections" },
  ["vambraces of the berserker"]        = { type="artefact", category="combat_offense", power="battlerage_decay", credits=200, effect="Slower battlerage decay" },

  -- =========================================================================
  -- DEFENSIVE ARTEFACTS
  -- =========================================================================

  ["brooch of the tempest"]             = { type="artefact", category="combat_defense", power="stability", credits=250, effect="Prevents wind blowing you off course when flying" },
  ["prismatic ring"]                    = { type="artefact", category="combat_defense", power="elemental_resistances", credits=500, effect="ACTIVATE <type> RESISTANCE (fire/cold/electric/magic)" },
  ["buckawn's amulet"]                  = { type="artefact", category="combat_defense", power="anti_web", credits=350, effect="Immune to web tattoo attacks and thrown web bombs" },
  ["shadowcloak"]                       = { type="artefact", category="combat_defense", power="shroud", credits=800, effect="Grants SHROUD ability when worn" },
  ["anake's hood"]                      = { type="artefact", category="combat_defense", power="anti_spying", credits=400, effect="Blocks eavesdrop: grove watch, mind listen, puppetry listen" },
  ["talisman of obfuscation"]           = { type="artefact", category="combat_defense", power="conceal_illusions", credits=200, effect="Reduces lifevision effectiveness by 33%" },
  ["ring of the magus"]                 = { type="artefact", category="combat_defense", power="magic_defence", credits=350, effect="~15% magic damage protection" },

  -- =========================================================================
  -- STAT ALTERING & REGEN ARTEFACTS
  -- =========================================================================

  -- Equilibrium Recovery (faster_eq)
  ["circlet of the wise"]               = { type="artefact", category="combat_stats", power="faster_eq", tier=1, credits=500,  effect="7% faster equilibrium recovery" },
  ["aldar diadem"]                      = { type="artefact", category="combat_stats", power="faster_eq", tier=2, credits=1000, effect="15% faster equilibrium recovery" },

  -- Celerity
  ["armband of celerity"]               = { type="artefact", category="combat_stats", power="celerity", credits=500, effect="Extra move/second before 'Don't be hasty'" },

  -- Critical Hit (criticals)
  ["stygian token"]                     = { type="artefact", category="combat_stats", power="criticals", tier=1, credits=500,  effect="+2% critical hit chance" },
  ["stygian coin"]                      = { type="artefact", category="combat_stats", power="criticals", tier=2, credits=1000, effect="+4% critical hit chance" },
  ["stygian pendant"]                   = { type="artefact", category="combat_stats", power="criticals", tier=3, credits=2000, effect="+6% critical hit chance" },

  -- Strength (strength)
  ["ogre gauntlets"]                    = { type="artefact", category="combat_stats", power="strength", tier=1, credits=500,  effect="+1 STR" },
  ["troll gauntlets"]                   = { type="artefact", category="combat_stats", power="strength", tier=2, credits=1000, effect="+2 STR" },
  ["logosian gauntlets"]                = { type="artefact", category="combat_stats", power="strength", tier=3, credits=2000, effect="+3 STR (also falconry glove)" },

  -- Dexterity (dexterity)
  ["buckled boots"]                     = { type="artefact", category="combat_stats", power="dexterity", tier=1, credits=500,  effect="+1 DEX" },
  ["winged boots"]                      = { type="artefact", category="combat_stats", power="dexterity", tier=2, credits=1000, effect="+2 DEX" },
  ["pixie's boots"]                     = { type="artefact", category="combat_stats", power="dexterity", tier=3, credits=2000, effect="+3 DEX" },

  -- Constitution (constitution)
  ["girdle of the titans"]              = { type="artefact", category="combat_stats", power="constitution", tier=1, credits=500,  effect="+1 CON" },
  ["girdle of fortitude"]               = { type="artefact", category="combat_stats", power="constitution", tier=2, credits=1000, effect="+2 CON" },
  ["girdle of aegis"]                   = { type="artefact", category="combat_stats", power="constitution", tier=3, credits=2000, effect="+3 CON" },

  -- Intelligence (intelligence)
  ["sash of insight"]                   = { type="artefact", category="combat_stats", power="intelligence", tier=1, credits=500,  effect="+1 INT" },
  ["sash of acumen"]                    = { type="artefact", category="combat_stats", power="intelligence", tier=2, credits=1000, effect="+2 INT" },
  ["sash of wisdom"]                    = { type="artefact", category="combat_stats", power="intelligence", tier=3, credits=2000, effect="+3 INT" },

  -- Health Sip (health_sip)
  ["mayan ring"]                        = { type="artefact", category="combat_stats", power="health_sip", tier=1, credits=500,  effect="+10% health elixir healing" },
  ["ring of endurance"]                 = { type="artefact", category="combat_stats", power="health_sip", tier=2, credits=1000, effect="+20% health elixir healing" },
  ["logosian ring"]                     = { type="artefact", category="combat_stats", power="health_sip", tier=3, credits=2000, effect="+30% health elixir healing" },

  -- Mana Sip (mana_sip)
  ["ring of socresia"]                  = { type="artefact", category="combat_stats", power="mana_sip", tier=1, credits=500,  effect="+10% mana elixir healing" },
  ["ring of pestilence"]                = { type="artefact", category="combat_stats", power="mana_sip", tier=2, credits=1000, effect="+20% mana elixir healing" },
  ["ring of lunastra"]                  = { type="artefact", category="combat_stats", power="mana_sip", tier=3, credits=2000, effect="+30% mana elixir healing" },

  -- Health Regen (health_regen)
  ["boar tusk"]                         = { type="artefact", category="combat_stats", power="health_regen", tier=1, credits=400,  effect="Level 1 passive health regeneration" },
  ["ivory boar tusk"]                   = { type="artefact", category="combat_stats", power="health_regen", tier=2, credits=800,  effect="Level 2 passive health regeneration" },
  ["suremekh'neina"]                    = { type="artefact", category="combat_stats", power="health_regen", tier=3, credits=1600, effect="Level 3 passive health AND mana regeneration" },

  -- Mana Regen (mana_regen)
  ["crescent moon"]                     = { type="artefact", category="combat_stats", power="mana_regen", tier=1, credits=400,  effect="Level 1 passive mana regeneration" },
  ["half moon"]                         = { type="artefact", category="combat_stats", power="mana_regen", tier=2, credits=800,  effect="Level 2 passive mana regeneration" },

  -- Endurance Regen (endurance_regen)
  ["ring of tenacity"]                  = { type="artefact", category="combat_stats", power="endurance_regen", tier=1, credits=200, effect="Level 1 endurance regeneration" },
  ["band of tenacity"]                  = { type="artefact", category="combat_stats", power="endurance_regen", tier=2, credits=400, effect="Level 2 endurance regeneration" },
  ["circlet of tenacity"]               = { type="artefact", category="combat_stats", power="endurance_regen", tier=3, credits=800, effect="Level 3 endurance regeneration" },

  -- Willpower Regen (willpower_regen)
  ["ring of determination"]             = { type="artefact", category="combat_stats", power="willpower_regen", tier=1, credits=200, effect="Level 1 willpower regeneration" },
  ["circlet of determination"]          = { type="artefact", category="combat_stats", power="willpower_regen", tier=2, credits=400, effect="Level 2 willpower regeneration" },
  ["crown of determination"]            = { type="artefact", category="combat_stats", power="willpower_regen", tier=3, credits=800, effect="Level 3 willpower regeneration" },

  -- Reserves (reserves)
  ["atavian bracelets"]                 = { type="artefact", category="combat_stats", power="reserves", tier=1, credits=400,  effect="+5% max health AND mana" },
  ["mayan bracelets"]                   = { type="artefact", category="combat_stats", power="reserves", tier=2, credits=800,  effect="+10% max health AND mana" },
  ["logosian bracelets"]                = { type="artefact", category="combat_stats", power="reserves", tier=3, credits=1600, effect="+15% max health AND mana" },

  -- Reduced Endurance
  ["sash of eternal battle"]            = { type="artefact", category="combat_stats", power="reduced_endurance", credits=400, effect="33% less endurance drain in combat" },

  -- =========================================================================
  -- MISCELLANEOUS / UTILITY ARTEFACTS
  -- =========================================================================

  ["anklet of dashing"]                 = { type="artefact", category="travel", power="dash", credits=850, effect="DASH ability - instant room movement" },
  ["chitin greaves"]                    = { type="artefact", category="travel", power="leap", credits=350, effect="LEAP ability - jump over obstacles/walls" },
  ["ring of flying"]                    = { type="artefact", category="travel", power="flying", credits=500, effect="Permanent flight without wings" },
  ["flying carpet"]                     = { type="artefact", category="travel", power="entourage", credits=350, effect="Followers can fly with you" },
  ["mithril spurs"]                     = { type="artefact", category="travel", power="quickmount", credits=350, effect="Faster mount balance + vault with no balance loss" },

  -- Rift Expand
  ["prospero's vault"]                  = { type="artefact", category="utility", power="rift_expand", tier=1, credits=500,  effect="2x rift capacity" },
  ["prospero's greater vault"]          = { type="artefact", category="utility", power="rift_expand", tier=2, credits=1000, effect="4x rift capacity (quadruple)" },

  -- Wormholes
  ["vibrating stick"]                   = { type="artefact", category="travel", power="wormholes", tier=1, credits=500, effect="Access to wormhole travel network" },

  -- Utility
  ["oval mask"]                         = { type="artefact", category="utility", power="lifevision", credits=350, effect="See health percentages of everyone in room" },
  ["hood of the sphinx"]                = { type="artefact", category="utility", power="sphinx", credits=400, effect="FULLSENSE (see all adventurers in area) + expanded FARSEE" },
  ["glittering fishscale tunic"]        = { type="artefact", category="utility", power="breathe_underwater", credits=400, effect="Permanent underwater breathing" },
  ["miniature toolkit"]                 = { type="artefact", category="utility", power="trapmaster", credits=500, effect="TRAPS and DISARM abilities" },

  -- Class Switch
  ["stone of the lesser lorewarden"]    = { type="artefact", category="utility", power="class_switch_reduction", tier=1, credits=250, effect="Reduced class switch cooldown" },
  ["stone of lesser lorewarden"]        = { type="artefact", category="utility", power="class_switch_reduction", tier=1, credits=250, effect="Reduced class switch cooldown" },
  ["stone of lorewarden"]               = { type="artefact", category="utility", power="class_switch_reduction", tier=2, credits=500, effect="Further reduced class switch cooldown" },
  ["stone of greater lorewarden"]       = { type="artefact", category="utility", power="class_switch_reduction", tier=3, credits=1000, effect="Class switch cooldown to 1 minute" },

  -- Trait Reset
  ["grimoire of adaptation"]            = { type="artefact", category="utility", power="trait_reset", tier=1, credits=1000, effect="Reset traits once per RL day" },
  ["grimoire of hasty adaptation"]      = { type="artefact", category="utility", power="trait_reset", tier=2, credits=2000, effect="Reset traits once every 2 RL hours" },

  -- =========================================================================
  -- CRAFTING & ECONOMY ARTEFACTS
  -- =========================================================================

  ["phaestean tap"]                     = { type="artefact", category="crafting", power="fluid_expansion", tier=1, credits=250,  effect="2x liquid rift capacity" },
  ["phaestean spigot"]                  = { type="artefact", category="crafting", power="fluid_expansion", tier=2, credits=500,  effect="3x liquid rift capacity" },
  ["phaestean faucet"]                  = { type="artefact", category="crafting", power="fluid_expansion", tier=3, credits=1000, effect="4x liquid rift capacity (quadruple)" },
  ["prospector's journal"]              = { type="artefact", category="crafting", power="mine_capacity", tier=1, credits=250, effect="+1 mine ownership capacity" },
  ["prospector's almanac"]              = { type="artefact", category="crafting", power="mine_capacity", tier=2, credits=500, effect="+2 mine ownership capacity" },
  ["prosperian attractor"]              = { type="artefact", category="crafting", power="gold_attractor", credits=350, effect="Gold from kills goes directly to inventory" },
  ["sand-worn bandolier"]               = { type="artefact", category="crafting", power="jars_capacity", credits=200, effect="+5 jar slots for alchemist" },
  ["wax stick encased in mithril"]      = { type="artefact", category="crafting", power="water_sketch", credits=150, effect="Sketch runes on water surfaces" },

  -- =========================================================================
  -- CLASS-SPECIFIC ARTEFACTS
  -- =========================================================================

  -- Elemental Lord
  ["gaze of the cacharann"]             = { type="artefact", category="class_specific", power="primordial_fury", credits=500, effect="TITAN +5s duration, -30% cooldown" },
  ["morsel of bonemeal"]                = { type="artefact", category="class_specific", power="unyielding_stone", credits=350, effect="+10% POWDERISE limb damage" },
  ["morsel of bonemite"]                = { type="artefact", category="class_specific", power="unyielding_stone", credits=350, effect="+10% POWDERISE limb damage" },
  ["cracked wheel"]                     = { type="artefact", category="class_specific", power="unending_avalanche", credits=350, effect="ROCKSLIDE rubble persists 50% longer" },

  -- Bard
  ["glass rose"]                        = { type="artefact", category="class_specific", power="pure_song", credits=500, effect="2x ARIA duration on targets (including self)" },
  ["moon-and-star insignia"]            = { type="artefact", category="class_specific", power="symphonic_master", credits=500, effect="50% faster eq when PLAY harmonics" },
  ["silver tuning fork"]                = { type="artefact", category="class_specific", power="tuning", credits=200, effect="2x lifetime for Crystalism/Harmonics/Devotion vibrations/rites" },
  ["golden pendulum"]                   = { type="artefact", category="class_specific", power="harmonics_call", credits=250, effect="Reduce time between calling harmonics and arrival" },

  -- Apostate/Infernal
  ["preserved hand"]                    = { type="artefact", category="class_specific", power="grasping_death", credits=200, effect="+50% GRAVEHANDS duration" },
  ["stygian torc"]                      = { type="artefact", category="class_specific", power="pit_frenzy", credits=500, effect="Fiends in pit attack on entry, +50% duration" },
  ["twisted figurine"]                  = { type="artefact", category="class_specific", power="enslavery", credits=350, effect="+1 slave capacity" },

  -- Blademaster
  ["bracers of the phoenix"]            = { type="artefact", category="class_specific", power="shin_drain", credits=400, effect="Slows shin energy decay rate" },
  ["ethereal lightning eagle feather"]   = { type="artefact", category="class_specific", power="enhanced_shin", credits=500, effect="+ANNIHILATE throw chance, +5s HAMSTRING duration" },
  ["ethereal lightning eagle feather cuff"] = { type="artefact", category="class_specific", power="enhanced_shin", credits=500, effect="+ANNIHILATE throw chance, +5s HAMSTRING duration" },

  -- Depthswalker
  ["sorcerer's notebook"]               = { type="artefact", category="class_specific", power="sorcerous_insight", credits=350, effect="Shadow damage shows target afflictions" },

  -- Magi
  ["gem of haematite"]                  = { type="artefact", category="class_specific", power="rapid_resonation", credits=400, effect="50% less eq for crystalism embedding" },
  ["gem of haematite with elemental facets"] = { type="artefact", category="class_specific", power="rapid_resonation", credits=400, effect="50% less eq for crystalism embedding" },

  -- Monk
  ["pink lotus blossom"]                = { type="artefact", category="class_specific", power="monk_switch", credits=250, effect="Switch Tekura/Shikudo free every 12hr" },

  -- Psion/Weaving
  ["bronze hand mirror"]                = { type="artefact", category="class_specific", power="weaving_mastery", tier=1, credits=350,  effect="+10% weaving damage" },
  ["silver hand mirror"]                = { type="artefact", category="class_specific", power="weaving_mastery", tier=2, credits=800,  effect="+15% weaving damage" },
  ["platinum hand mirror"]              = { type="artefact", category="class_specific", power="weaving_mastery", tier=3, credits=1600, effect="+20% weaving damage" },
  ["waterlogged gauntlet"]              = { type="artefact", category="class_specific", power="surging_waves", credits=500, effect="+2 max range on WAVESURGE" },
  ["ephemeral shuttle"]                 = { type="artefact", category="class_specific", power="resilient_miriads", credits=500, effect="+1 hits to disperse miriad" },
  ["psionic flame"]                     = { type="artefact", category="class_specific", power="psionic_projection", credits=500, effect="+2 swaps with projection before vanish" },

  -- Psion/Telepathy
  ["intellect crown"]                   = { type="artefact", category="class_specific", power="faster_mindlock", credits=500, effect="40% faster MINDLOCK time" },
  ["ursine band of mind distension"]    = { type="artefact", category="class_specific", power="mindprint_capacity", tier=1, credits=250, effect="+3 MINDPRINT slots" },
  ["synaptic lock"]                     = { type="artefact", category="class_specific", power="silent_telepathy", credits=350, effect="Target not alerted when mindlock breaks + MIND CLOAK" },

  -- Shaman
  ["onyx skull pendant"]                = { type="artefact", category="class_specific", power="swiftcurse", tier=1, credits=350,  effect="+2 SWIFTCURSE curses, +1s JINX duration" },
  ["obsidian skull pendant"]            = { type="artefact", category="class_specific", power="swiftcurse", tier=2, credits=700,  effect="+4 SWIFTCURSE curses, +2s JINX duration" },
  ["sapphire skull pendant"]            = { type="artefact", category="class_specific", power="swiftcurse", tier=3, credits=1400, effect="+6 SWIFTCURSE curses, +3s JINX duration" },
  ["runic gauntlet"]                    = { type="artefact", category="class_specific", power="totems", credits=350, effect="Faster totem implant/uproot, -50% own uproot, -25% others'" },

  -- Runewarden
  ["rough runestone"]                   = { type="artefact", category="class_specific", power="swift_runes", credits=200, effect="~33% faster rune sketching" },

  -- Alchemist
  ["aludel of pellucid glass"]          = { type="artefact", category="class_specific", power="alchemical_focus", credits=500, effect="3x stacks from sulphur/mercury, less gold transfer failures" },
  ["talisman of greater cultivation"]   = { type="artefact", category="class_specific", power="homunculus_boost", credits=250, effect="Increased homunculus health and speed" },

  -- Sentinel
  ["braided length of weasel offal"]    = { type="artefact", category="class_specific", power="falcon_self_sufficiency", credits=200, effect="Falcon doesn't need feeding" },

  -- Occultist
  ["funereal amphora"]                  = { type="artefact", category="class_specific", power="desert_sorcerer", credits=350, effect="+10% chaos damage, faster instill" },
  ["illusion staff"]                    = { type="artefact", category="class_specific", power="illusion", tier=1, credits=350, effect="500 char limit illusion staff" },
  ["shar'ilian lightspire"]             = { type="artefact", category="class_specific", power="illusion", tier=2, credits=700, effect="1000 char limit, color, area/continent illusions" },
  ["staff of illusion"]                 = { type="artefact", category="class_specific", power="illusion", tier=3, credits=1400, effect="2000 char limit, full features" },

  -- =========================================================================
  -- SHOP OF WONDERS (Mayan Crown items)
  -- =========================================================================

  ["diamond-tipped shovel"]             = { type="artefact", category="shop_of_wonders", power="faster_dig", effect="50% faster DIGging" },
  ["stardust flask"]                    = { type="artefact", category="shop_of_wonders", power="starburst", effect="SHAKE for starburst defence (1/3 Achaean days)" },
  ["hunting wasp"]                      = { type="artefact", category="shop_of_wonders", power="wasp_tracking", effect="Track target for 2min, reports location on move" },
  ["scrying bowl"]                      = { type="artefact", category="shop_of_wonders", power="scrying", effect="SCRY FOR <person> shows location AND area" },
  ["enchanted pebble"]                  = { type="artefact", category="shop_of_wonders", power="continental_portals", effect="Use continental portals (Sea Lion Cove / Rageteeth)" },
  ["miniature enchanted stone circle"]  = { type="artefact", category="shop_of_wonders", power="annwyn_portal", effect="DROP and SKIP for on-demand trip to Annwyn" },
  ["cleverly packed, deconstructed tent"] = { type="artefact", category="shop_of_wonders", power="regen_tent", effect="Assemble for increased wp/end regen" },
  ["cleverly packed tent"]              = { type="artefact", category="shop_of_wonders", power="regen_tent", effect="Assemble for increased wp/end regen" },
  ["obfuscated crystal vial"]           = { type="artefact", category="shop_of_wonders", power="daily_refill", effect="Refills sips daily, random fluid if empty" },
  ["glazed runic vial"]                 = { type="artefact", category="shop_of_wonders", power="bonus_elixirs", effect="Bonus elixirs (XP, crit, stats) for 12hr, 5 sips" },

  -- =========================================================================
  -- PROMOTIONAL ITEMS
  -- =========================================================================

  ["sartanic vambrace"]                 = { type="promo", category="promo", power="essence_reduction", effect="50% essence reduction for Necromancy" },
  ["token of notoriety"]                = { type="promo", category="promo", power="enemy_ally_slots", effect="+5 enemy/ally list slots" },
  ["ledolian surcoat"]                  = { type="promo", category="promo", power="armour_empower", effect="EMPOWER for +10 armour resistance (10 charges)" },
  ["shimmering crystal clover"]         = { type="promo", category="promo", power="crit_bonus", effect="PULL leaf for 24hr crit bonus" },
  ["logosmas stocking"]                 = { type="promo", category="promo", power="ironbeard_gifts", effect="HANG for Ironbeard gifts during Logosmas" },
  ["bloodstained shard of enamel"]      = { type="promo", category="promo", power="locket_power", effect="Fuse into locket for powers (immortality, rest, satiation, rage storage)" },
  ["wooden box of parts"]               = { type="promo", category="promo", power="talisman_cache", effect="OPEN FOR <setname> for talisman piece" },
  ["unusual hourglass"]                 = { type="promo", category="promo", power="xp_boost", effect="TURN for 1hr double XP" },
  ["sleek baalzadeen lantern"]          = { type="promo", category="promo", power="baalzadeen", effect="Light to summon baalzadeen companion" },
  ["painted lantern"]                   = { type="promo", category="promo", power="painted_lantern", effect="Cosmetic lantern" },
  ["ball of seftonium"]                 = { type="promo", category="promo", power="class_reset", effect="Reset class switch cooldown when eaten" },

  -- Promo weapons/items
  ["logosian battleaxe"]                = { type="promo", category="promo", power="logosian_weapon", effect="Logosian-tier weapon (non-decay, resetting)" },
  ["matsuhama's morningstar"]           = { type="promo", category="promo", power="legendary_weapon", effect="Legendary morningstar" },
  ["soulpiercer"]                       = { type="promo", category="promo", power="legendary_weapon", effect="Legendary rapier" },

  -- Playing cards (promo April 2018)
  ["playing card"]                      = { type="promo", category="promo", power="promo_card", effect="Collectible promo card (April 2018)" },

  -- =========================================================================
  -- SPECIAL ITEMS (Unique / Non-standard)
  -- =========================================================================

  -- Weapons with special properties
  ["agith'maal's ire"]                  = { type="special", category="combat_offense", power="legendary_scythe", effect="Legendary scythe weapon" },
  ["gattan'lier's hunger"]              = { type="special", category="combat_offense", power="legendary_dagger", effect="Legendary dagger weapon" },
  ["crimson-hued daegger"]              = { type="special", category="combat_offense", power="daegger", effect="Crimson daegger weapon" },
  ["hellforge hammer"]                  = { type="special", category="combat_offense", power="hellforge", effect="Hellforge warhammer for Infernal FORGE ability" },
  ["elentari's scourge"]                = { type="special", category="combat_offense", power="legendary_lash", effect="Legendary lash weapon" },
  ["braincrusher flail"]                = { type="special", category="combat_offense", power="braincrusher", effect="Braincrusher flail weapon" },
  ["apocalypse, a blackrock sword of black-hued steel"] = { type="special", category="combat_offense", power="custom_weapon", effect="Custom bastard sword" },
  ["malice, a vicious multi-tonal scimitar"] = { type="special", category="combat_offense", power="custom_weapon", effect="Custom scimitar" },
  ["severance, a vorpal sanguine scimitar"] = { type="special", category="combat_offense", power="custom_weapon", effect="Custom vorpal scimitar" },
  ["valafar, a crimson-tinged hellforged longsword"] = { type="special", category="combat_offense", power="custom_weapon", effect="Custom hellforged longsword" },
  ["thoth's fang"]                      = { type="special", category="combat_offense", power="legendary_dirk", effect="Legendary dirk weapon" },
  ["twisted oaken staff"]               = { type="special", category="combat_offense", power="oaken_staff", effect="Twisted oaken staff" },
  ["primordial staff"]                  = { type="special", category="combat_offense", power="primordial_staff", effect="Primordial staff weapon" },
  ["axe of gaian fury"]                 = { type="special", category="combat_offense", power="gaian_fury", effect="Axe of Gaian Fury" },
  ["blazing flames"]                    = { type="special", category="combat_offense", power="two_arts_sword", effect="Two Arts sword (Blademaster)" },
  ["lupine bow"]                        = { type="special", category="combat_offense", power="lupine_bow", effect="Lupine hunting bow" },

  -- Shields
  ["shield of absorption"]              = { type="artefact", category="combat_defense", power="absorption_shield", effect="Shield of Absorption - absorbs damage" },

  -- Reflections
  ["wand of reflection"]                = { type="artefact", category="combat_defense", power="reflections", credits=350, effect="Grants reflections 1x/hour; absorb attacks" },

  -- Misc utility
  ["writ of higher education"]          = { type="special", category="utility", power="higher_education", effect="Writ of higher education" },
  ["gilded pike"]                       = { type="special", category="utility", power="display_pike", effect="Display pike for impaled heads" },
  ["horn of plenty"]                    = { type="special", category="utility", power="horn_of_plenty", effect="Produces food and drink" },
  ["painter's palette"]                 = { type="special", category="crafting", power="painting", effect="Painter's palette for artwork creation" },
  ["deck of mystical cards"]            = { type="special", category="utility", power="tarot_deck", effect="Tarot card deck for Tarot abilities" },
  ["lavishly bejewelled sceptre"]       = { type="special", category="utility", power="sceptre", effect="Bejewelled sceptre" },

  -- Mounts & companions
  ["black dardanic stallion"]           = { type="special", category="travel", power="mount", effect="Dardanic stallion mount" },
  ["lean grizzly bear"]                 = { type="special", category="utility", power="bear_companion", effect="Grizzly bear companion" },
  ["war elephant"]                      = { type="special", category="travel", power="war_elephant", effect="War elephant mount" },
  ["massive dire wolf"]                 = { type="special", category="utility", power="dire_wolf", effect="Dire wolf companion" },
  ["phantom grizzly bear"]              = { type="special", category="utility", power="phantom_bear", effect="Phantom grizzly bear companion" },
  ["skeletal kitten"]                   = { type="special", category="utility", power="minipet", effect="Skeletal kitten minipet" },

  -- Misc items from inventory
  ["callibian medallion"]               = { type="talisman", category="utility", power="quisalis_mark", effect="Quisalis Mark tracking medallion" },
  ["lasallian lyre"]                    = { type="special", category="utility", power="lyre", effect="Lasallian lyre (city artefact)" },
  ["coiled black steel armband"]        = { type="talisman", category="combat_offense", power="quisalis_armband", effect="Quisalis Mark armband - locate marked targets" },
  ["unbroken talisman of custody"]      = { type="talisman", category="utility", power="custody", effect="Custody talisman - prevents item theft" },
  ["robes of the wanderer"]             = { type="talisman", category="utility", power="wanderer_robes", effect="Wanderer robes - teleport to random locations" },
  ["wreath of lycopod vines"]           = { type="special", category="utility", power="lycopod_wreath", effect="Wreath of lycopod vines" },
  ["shackle of garash"]                 = { type="special", category="combat_offense", power="garash", effect="Shackle of Garash" },
  ["gem of cloaking"]                   = { type="special", category="combat_defense", power="cloaking", effect="Gem of cloaking" },
  ["leadrope inlaid with silver"]       = { type="special", category="utility", power="leadrope", effect="Silver leadrope for leading mounts/NPCs" },
  ["phial of shimmering permanent ink"] = { type="special", category="crafting", power="permanent_ink", effect="Permanent ink for inscriptions" },

  -- Earrings
  ["earring of sinope"]                 = { type="artefact", category="utility", power="sinope_earring", effect="Communication earring" },

  -- Containers
  ["wyrmskin pack"]                     = { type="special", category="utility", power="container", effect="Wyrmskin pack - expanded container" },
  ["dragonskin pack"]                   = { type="talisman", category="utility", power="container", effect="Dragonskin pack - expanded container (Wonders talisman)" },
  ["wyvernskin pack"]                   = { type="special", category="utility", power="container", effect="Wyvernskin pack - expanded container" },

  -- Quivers
  ["moon-bright quiver"]                = { type="special", category="utility", power="quiver", effect="Moon-bright quiver - holds arrows" },
  ["dragonskin quiver"]                 = { type="special", category="utility", power="quiver", effect="Dragonskin quiver - holds arrows" },

  -- Armour
  ["suit of cloth armour"]              = { type="special", category="combat_defense", power="armour", effect="Cloth armour" },

  -- Cane of Quickening
  ["cane of the quickening"]            = { type="promo", category="promo", power="quickening", effect="Cane of the Quickening - utility cane" },

  -- Miscellaneous promo/special
  ["mechanical box"]                    = { type="promo", category="promo", power="mechanical_box", effect="Mechanical puzzle box" },
  ["vodun doll"]                        = { type="special", category="combat_offense", power="vodun_doll", effect="Vodun doll for Shaman CURSE targeting" },
  ["warhorn of heroes"]                 = { type="talisman", category="combat_offense", power="warhorn", effect="Warhorn of heroes - rallying cry" },
  ["cloak of the blood maiden"]         = { type="talisman", category="combat_defense", power="blood_maiden", effect="Shadowcloak + BLOODSHIELD (blocks 1 attack, charges from kills)" },
  ["scintillating pair of cascading wings"] = { type="talisman", category="travel", power="island_wings", effect="Talisman wings - travel to islands" },

  -- Figurines
  ["figurine of the suffering maya"]    = { type="talisman", category="utility", power="maya_figurine", effect="Maya figurine - summon temporary NPC" },
  ["battle figurine"]                   = { type="special", category="utility", power="battle_figurine", effect="Battle figurine for display arena" },

  -- Sigils
  ["monolith sigil"]                    = { type="special", category="combat_defense", power="monolith", effect="Prevents teleportation in/out of room" },
  ["vicarious sigil"]                   = { type="artefact", category="shop_of_wonders", power="vicarious", effect="Change paired artefact ownership 1/year" },
  ["incandescent sigil"]                = { type="special", category="utility", power="incandescent", effect="Prevents item decay in room" },
  ["fist-shaped sigil"]                 = { type="special", category="combat_offense", power="fist_sigil", effect="Prevents fleeing from room" },

  -- Misc
  ["metal whistle"]                     = { type="special", category="utility", power="whistle", effect="Metal whistle - recall mount" },
  ["platinum whistle"]                  = { type="talisman", category="utility", power="platinum_whistle", effect="Platinum whistle - enhanced mount recall (Wonders talisman)" },

  -- =========================================================================
  -- PARAGONS (Armour embrasures)
  -- =========================================================================

  ["fuscous paragon"]                   = { type="artefact", category="paragons", power="blunt_resist", credits=500, effect="~5% blunt resistance" },
  ["vinaceous paragon"]                 = { type="artefact", category="paragons", power="cutting_resist", credits=500, effect="~5% cutting resistance" },
  ["viridescent paragon"]               = { type="artefact", category="paragons", power="poison_resist", credits=500, effect="~7% poison resistance" },
  ["piceous paragon"]                   = { type="artefact", category="paragons", power="asphyx_resist", credits=500, effect="~7% asphyxiation resistance" },
  ["citreous paragon"]                  = { type="artefact", category="paragons", power="magic_resist", credits=450, effect="~7% magic resistance" },
  ["aurous paragon"]                    = { type="artefact", category="paragons", power="psychic_resist", credits=400, effect="~7% psychic resistance" },
  ["cyaneous paragon"]                  = { type="artefact", category="paragons", power="cold_resist", credits=400, effect="~7% cold resistance" },
  ["oleaginous paragon"]                = { type="artefact", category="paragons", power="fire_resist", credits=400, effect="~7% fire resistance" },
  ["caliginous paragon"]                = { type="artefact", category="paragons", power="electric_resist", credits=400, effect="~7% electricity resistance" },
  ["resonate metalliferous paragon"]    = { type="artefact", category="paragons", power="shifting_resist", credits=750, effect="~7.5% shifting resistance" },
  ["nacreous tetrahedral paragon"]      = { type="artefact", category="paragons", power="morph_armour", tier=1, credits=800, effect="MORPHARMOUR (1hr cooldown)" },
  ["nacreous octahedral paragon"]       = { type="artefact", category="paragons", power="morph_armour", tier=2, credits=1200, effect="MORPHARMOUR (20min cooldown)" },
  ["nacreous deltahedral paragon"]      = { type="artefact", category="paragons", power="morph_armour", tier=3, credits=1900, effect="MORPHARMOUR (10min cooldown)" },
  ["aeneaous paragon"]                  = { type="artefact", category="paragons", power="absorption", credits=1000, effect="Shield of Absorption effect" },
  ["prismatic paragon"]                 = { type="artefact", category="paragons", power="auto_prismatic", credits=900, effect="Auto-prismatic barrier when <25% health from denizen" },
  ["auspicious icosagon paragon"]       = { type="artefact", category="paragons", power="crit_boost", credits=1000, effect="20% chance to boost crit level" },
  ["crucious paragon"]                  = { type="artefact", category="paragons", power="crit_multiplier", credits=1000, effect="Boost crit multiplier OR crit fail" },
  ["rufescent paragon"]                 = { type="artefact", category="paragons", power="revenge_dmg", credits=400, effect="Damage boost vs last person who killed you" },
  ["torpous paragon"]                   = { type="artefact", category="paragons", power="sleep_regen", credits=300, effect="2x end/wp regen during sleep/meditation" },
  ["niveous paragon"]                   = { type="artefact", category="paragons", power="end_return", credits=700, effect="5% denizen damage returned as endurance" },
  ["serendipitous paragon"]             = { type="artefact", category="paragons", power="wp_return", credits=400, effect="5% denizen damage returned as willpower" },
  ["cupreous paragon"]                  = { type="artefact", category="paragons", power="armour_storage", credits=250, effect="Armour holds 20 items" },
  ["luteous dodecahedron paragon"]      = { type="artefact", category="paragons", power="armour_stasis", credits=400, effect="20 items + stasis" },
  ["euphonious paragon"]                = { type="artefact", category="paragons", power="denizen_info", credits=500, effect="DISCUSS with denizens for spawn info" },
  ["paragon u-notch pry tool"]          = { type="artefact", category="paragons", power="pry_tool", credits=250, effect="Unlimited pry uses, non-decay" },

  -- Rondels
  ["gilded rondel"]                     = { type="artefact", category="paragons", power="embrasures_2", credits=350, effect="2 embrasures, non-decay, resetting" },
  ["sun and starburst rondel"]          = { type="artefact", category="paragons", power="embrasures_3", credits=850, effect="3 embrasures, non-decay, resetting" },
}

-- =============================================================================
-- TALISMAN KEYWORD KNOWLEDGE BASE
-- =============================================================================
-- Keyed by the keyword from TALISMAN LIST (3rd column).
-- Provides set name and effect description.

itemCatalog.talismanKB = {
  -- Wonders set
  ["dragonskinpack"]     = { set="Wonders",   effect="Expanded container: holds more items than regular packs" },
  ["platinumwhistle"]    = { set="Wonders",   effect="Enhanced mount recall - summon mount from anywhere" },

  -- Conclave set
  ["tophat"]             = { set="Conclave",  effect="Luxurious top hat (cosmetic + minor effect)" },
  ["tempestbrooch"]      = { set="Conclave",  effect="Brooch of the Tempest - prevents wind displacement when flying" },

  -- Marks set
  ["quisalisarmband"]    = { set="Marks",     effect="Quisalis armband - locate and track marked targets" },
  ["quisalismedallion"]  = { set="Marks",     effect="Callibian medallion - Quisalis Mark tracking" },
  ["ivorywarhorn"]       = { set="Marks",     effect="Warhorn of Heroes - rallying cry, group buff" },
  ["quisalislookingglass"] = { set="Marks",   effect="Grandmaster's looking glass - enhanced LOOK at distance" },
  ["quisaliscloak"]      = { set="Marks",     effect="Cloak of the Blood Maiden - Shadowcloak + BLOODSHIELD (blocks 1 attack)" },

  -- Seafaring set
  ["islandwings"]        = { set="Seafaring", effect="Cascading wings - fly to outer islands" },

  -- Death set
  ["deathscall"]         = { set="Death",     effect="Death's Call bugle - summon death-themed companion" },
  ["deathcape"]          = { set="Death",     effect="Sycophantic shoulder cape - death-themed cosmetic + effect" },
  ["vulturetalon"]       = { set="Death",     effect="Vulture's talon - death-themed utility" },
  ["crucible"]           = { set="Death",     effect="Soulfire crucible - soul-based abilities" },

  -- Blackwave set
  ["finalityring"]       = { set="Blackwave", effect="Ring of finality - enhanced final strikes" },
  ["suremekh'neina"]     = { set="Blackwave", effect="Suremekh'neina - L3 passive health AND mana regen" },

  -- Races set
  ["sirensong"]          = { set="Races",     effect="Bottled siren's song - charm/mesmerize effect" },
  ["lodestone"]          = { set="Races",     effect="Dwarven lodestone - locate minerals or navigate underground" },
  ["mayafigurine"]       = { set="Races",     effect="Figurine of the suffering Maya - summon temporary NPC" },
  ["panpipes"]           = { set="Races",     effect="Crystalline panpipes - musical instrument with effects" },

  -- Contender set
  ["contendersfigurine"] = { set="Contender", effect="Battle figurine - display in arena, cosmetic" },

  -- Underworld set
  ["sanityskein"]        = { set="Underworld", effect="Skein of sanity - mental protection or restoration" },
  ["cullingblade"]       = { set="Underworld", effect="The culling blade - enhanced weapon" },
  ["psychesplinter"]     = { set="Underworld", effect="Splinter of shattered psyche - mental attack/defence" },
  ["cryptworm"]          = { set="Underworld", effect="Withered crypt worm - underworld companion" },
  ["custodytalisman"]    = { set="Underworld", effect="Talisman of custody - prevents item theft from you" },

  -- Eldergods set
  ["valnurana"]          = { set="Eldergods", effect="Sachet of soothing herbs - sleep/rest enhancement" },
  ["twilight"]           = { set="Eldergods", effect="Obsidian hound carving - summon hunting hound companion" },
  ["phaestus"]           = { set="Eldergods", effect="Dwarven finishing hammer - enhanced crafting" },
  ["aegis"]              = { set="Eldergods", effect="Declaration of hostility - enhanced enemy tracking" },

  -- Moderngods set
  ["aurora"]             = { set="Moderngods", effect="Tear of Ethian - healing/light abilities" },
  ["deucalion"]          = { set="Moderngods", effect="Tattered swatch of ashen cloth - fire-themed abilities" },
  ["ourania"]            = { set="Moderngods", effect="Comet-etched barb - celestial-themed abilities" },

  -- Wanderer set
  ["wandererrobes"]      = { set="Wanderer",  effect="Robes of the wanderer - teleport to random locations" },
}

-- =============================================================================
-- CATEGORY DISPLAY ORDER & LABELS
-- =============================================================================

itemCatalog.categoryOrder = {
  "combat_stats",
  "combat_offense",
  "combat_defense",
  "class_specific",
  "utility",
  "travel",
  "crafting",
  "shop_of_wonders",
  "paragons",
  "housing",
  "promo",
}

itemCatalog.categoryLabels = {
  combat_stats      = "Combat - Stats & Balance",
  combat_offense    = "Combat - Offensive",
  combat_defense    = "Combat - Defensive",
  class_specific    = "Class-Specific",
  utility           = "Utility",
  travel            = "Travel",
  crafting          = "Crafting & Economy",
  shop_of_wonders   = "Shop of Wonders",
  paragons          = "Paragons & Rondels",
  housing           = "Housing",
  promo             = "Promotional Items",
}
