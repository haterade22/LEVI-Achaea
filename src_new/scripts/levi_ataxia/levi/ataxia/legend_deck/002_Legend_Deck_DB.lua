--[[mudlet
type: script
name: Legend Deck Database
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Ataxia
- Legend Deck
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

--[[
    ============================================================================
    LEGEND DECK DATABASE
    ============================================================================
    Complete card database for Achaea legend deck system.
    Source: LDM v1.07 (Shecks) + updated Hunt/Celestial/Enigma/Champions suits.

    Each card entry:
      name        = display name
      suit        = suit name
      collection  = collection name
      joker       = joker card name for this suit (empty string if IS a joker)
      category    = primary category (combat/travel/utility/bashing/seafaring/style/souls/joker)
      tags        = all applicable tags
      short       = short description
      long        = full description
      max         = max charges
      rate        = recharge rate in hours (per charge)
    ============================================================================
]]--

ldm = ldm or {}

-- Categories and collections
ldm.categories = {"combat", "travel", "bashing", "utility", "souls", "seafaring", "style", "joker"}

ldm.collections = {
    ["Nemesis"]    = {"Tsol'teth", "Islanders", "Betrayed and Betrayers"},
    ["Salvation"]  = {"Seleucarian", "Saviours", "Knights"},
    ["Historical"] = {"Ancients", "Originals", "Animals"},
    ["Renowned"]   = {"Impudent", "Aesthetes", "Intrepid"},
    ["Loveless"]   = {"Lovers", "Estranged", "Scrappers"},
    ["Forests"]    = {"Spiritsoul", "Spiritheart"},
    ["Celestial"]  = {"Moons", "Suns"},
    ["Hunt"]       = {"Huntersoul", "Hunterblood"},
    ["Champions"]  = {"Ancientstaff"},
    ["Enigma"]     = {"Titans"},
}

-- =========================================================================
-- CARD DATABASE
-- =========================================================================

ldm.db = {

    ---------------------------------------------------------------------------
    -- TSOL'TETH (Nemesis)
    ---------------------------------------------------------------------------

    ["Agith'tai"] = {
        name       = "Agith'tai",
        suit       = "Tsol'teth",
        collection = "Nemesis",
        joker      = "Ithin'urai",
        category   = "combat",
        tags       = {"combat"},
        short      = "Reflect Mentals 30s",
        long       = "Grants a defence that lasts 30s which has a chance to give focus\n"..
                     "afflictions delivered to you to the attacker as well.",
        max        = 3,
        rate       = 2,
    },

    ["Agith'maal"] = {
        name       = "Agith'maal",
        suit       = "Tsol'teth",
        collection = "Nemesis",
        joker      = "Ithin'urai",
        category   = "travel",
        tags       = {"travel"},
        short      = "FT to Meropis",
        long       = "Teleports you to before the ruins of Seleucar from anywhere on the Prime\n"..
                     "Material Plane (not on a ship). Blocked by monolith.\n"..
                     "Not functional from outer islands.",
        max        = 2,
        rate       = 1,
    },

    ["Ama-maalier"] = {
        name       = "Ama-maalier",
        suit       = "Tsol'teth",
        collection = "Nemesis",
        joker      = "Ithin'urai",
        category   = "combat",
        tags       = {"combat"},
        short      = "Self-Root 10s",
        long       = "Make yourself immovable for 10 seconds (including by yourself).",
        max        = 3,
        rate       = 1,
    },

    ["Parni"] = {
        name       = "Parni",
        suit       = "Tsol'teth",
        collection = "Nemesis",
        joker      = "Ithin'urai",
        category   = "combat",
        tags       = {"combat"},
        short      = "Hatred Afflict 20s",
        long       = "Give hatred affliction lasting 20 seconds to a target.\n"..
                     "[treat everyone as enemy]",
        max        = 3,
        rate       = 1,
    },

    ["Ithin'urai"] = {
        name       = "Ithin'urai",
        suit       = "Tsol'teth",
        collection = "Nemesis",
        joker      = "",
        category   = "joker",
        tags       = {"joker"},
        short      = "J: Agi Agi Ama Par",
        long       = "Joker for Agith'tai, Agith'maal, Ama-maalier, Parni.\n"..
                     "Regenerates 1 charge every 12 hours.",
        max        = 1,
        rate       = 12,
    },

    ---------------------------------------------------------------------------
    -- SELEUCARIAN (Salvation)
    ---------------------------------------------------------------------------

    ["Severian"] = {
        name       = "Severian",
        suit       = "Seleucarian",
        collection = "Salvation",
        joker      = "Mycale",
        category   = "combat",
        tags       = {"combat"},
        short      = "Steelmind you & allies",
        long       = "Gives the steelmind defence to all mutual allies that stand in your location.",
        max        = 5,
        rate       = 1,
    },

    ["Lucaine"] = {
        name       = "Lucaine",
        suit       = "Seleucarian",
        collection = "Salvation",
        joker      = "Mycale",
        category   = "combat",
        tags       = {"combat", "defence"},
        short      = "Trueblind 20s",
        long       = "Gives you the trueblind affliction for 20 seconds.\n"..
                     "Also gives you significant bleeding on a periodic tick while under such blindness.",
        max        = 3,
        rate       = 1,
    },

    ["Catarin"] = {
        name       = "Catarin",
        suit       = "Seleucarian",
        collection = "Salvation",
        joker      = "Mycale",
        category   = "bashing",
        tags       = {"bashing"},
        short      = "Room Heal",
        long       = "Heal the health of everyone in your location.\n"..
                     "Does not heal yourself, and has a mana cost.",
        max        = 5,
        rate       = 1,
    },

    ["Nicator"] = {
        name       = "Nicator",
        suit       = "Seleucarian",
        collection = "Salvation",
        joker      = "Mycale",
        category   = "bashing",
        tags       = {"bashing", "defence"},
        short      = "Group +30% exp 30m",
        long       = "Grants a 30% experience boost to all groups led by you.\n"..
                     "The defence lasts 30 minutes.",
        max        = 5,
        rate       = 1,
    },

    ["Mycale"] = {
        name       = "Mycale",
        suit       = "Seleucarian",
        collection = "Salvation",
        joker      = "",
        category   = "joker",
        tags       = {"joker"},
        short      = "J: Sev Luc Cat Nic",
        long       = "Joker for Severian, Lucaine, Catarin, Nicator.\n"..
                     "Regenerates 1 charge every 12 hours.",
        max        = 1,
        rate       = 1,
    },

    ---------------------------------------------------------------------------
    -- SAVIOURS (Salvation)
    ---------------------------------------------------------------------------

    ["Yudhishthira"] = {
        name       = "Yudhishthira",
        suit       = "Saviours",
        collection = "Salvation",
        joker      = "Alcibiades",
        category   = "combat",
        tags       = {"combat", "utility"},
        short      = "Melt Icewall 1s bal",
        long       = "Melt an icewall in a direction. 1 second balance.",
        max        = 4,
        rate       = 1,
    },

    ["Matic"] = {
        name       = "Matic",
        suit       = "Saviours",
        collection = "Salvation",
        joker      = "Alcibiades",
        category   = "bashing",
        tags       = {"bashing"},
        short      = "Next hit crit",
        long       = "Your next attack will be guaranteed to be a high end crit.",
        max        = 3,
        rate       = 1,
    },

    ["Ashaxei"] = {
        name       = "Ashaxei",
        suit       = "Saviours",
        collection = "Salvation",
        joker      = "Alcibiades",
        category   = "travel",
        tags       = {"travel", "utility"},
        short      = "FT to ally",
        long       = "Travel to a mutual ally (not on a ship) but on any plane.\n"..
                     "Stopped by monolith on either end.",
        max        = 1,
        rate       = 8,
    },

    ["Sycaerunax"] = {
        name       = "Sycaerunax",
        suit       = "Saviours",
        collection = "Salvation",
        joker      = "Alcibiades",
        category   = "combat",
        tags       = {"utility", "combat", "bashing"},
        short      = "Drag 2nd Wind 10s",
        long       = "On dying via any means, you will be fully restored and fight\n"..
                     "on for another 10 seconds. After that 10 seconds ends, you\n"..
                     "will immediately die and embrace death.",
        max        = 3,
        rate       = 1,
    },

    ["Alcibiades"] = {
        name       = "Alcibiades",
        suit       = "Saviours",
        collection = "Salvation",
        joker      = "",
        category   = "joker",
        tags       = {"joker"},
        short      = "J: Yud Mat Ash Syc",
        long       = "Joker for Yudhishthira, Matic, Ashaxei, Sycaerunax.\n"..
                     "Regenerates 1 charge every 24 hours.",
        max        = 1,
        rate       = 24,
    },

    ---------------------------------------------------------------------------
    -- BETRAYED AND BETRAYERS (Nemesis)
    ---------------------------------------------------------------------------

    ["Slith"] = {
        name       = "Slith",
        suit       = "Betrayed and Betrayers",
        collection = "Nemesis",
        joker      = "Han-silnar",
        category   = "souls",
        tags       = {"souls"},
        short      = "Stun Souls 15s",
        long       = "Stun all souls in room for 15 seconds. A soul stunned in this\n"..
                     "way has a short immunity after being unstunned before they\n"..
                     "may be stunned again.",
        max        = 3,
        rate       = 1,
    },

    ["Pazuzu"] = {
        name       = "Pazuzu",
        suit       = "Betrayed and Betrayers",
        collection = "Nemesis",
        joker      = "Han-silnar",
        category   = "combat",
        tags       = {"combat", "travel"},
        short      = "Prevent FT 1 min",
        long       = "Summon a blood rain with similar effects to a stormfront, preventing\n"..
                     "magical travel into the location from more than one room away.",
        max        = 3,
        rate       = 1,
    },

    ["Enheduanna"] = {
        name       = "Enheduanna",
        suit       = "Betrayed and Betrayers",
        collection = "Nemesis",
        joker      = "Han-silnar",
        category   = "souls",
        tags       = {"souls"},
        short      = "Corpse Mana Burn",
        long       = "Target a corpse, destroying it and dealing massive mana damage\n"..
                     "to the originator of said corpse if they are currently a soul.",
        max        = 5,
        rate       = 1,
    },

    ["Ugrach"] = {
        name       = "Ugrach",
        suit       = "Betrayed and Betrayers",
        collection = "Nemesis",
        joker      = "Han-silnar",
        category   = "souls",
        tags       = {"souls", "utility"},
        short      = "Embrace Death Progress",
        long       = "Determine roughly where someone who has embraced death is in\n"..
                     "the death sequence. Infinite charges.",
        max        = 99,
        rate       = 0,
    },

    ["Han-silnar"] = {
        name       = "Han-silnar",
        suit       = "Betrayed and Betrayers",
        collection = "Nemesis",
        joker      = "",
        category   = "joker",
        tags       = {"joker"},
        short      = "J: Sli Paz Enh Ugr",
        long       = "Joker for Slith, Pazuzu, Enheduanna, Ugrach.\n"..
                     "Regenerates 1 charge every 12 hours.",
        max        = 1,
        rate       = 12,
    },

    ---------------------------------------------------------------------------
    -- ISLANDERS (Nemesis)
    ---------------------------------------------------------------------------

    ["Lordan"] = {
        name       = "Lordan",
        suit       = "Islanders",
        collection = "Nemesis",
        joker      = "Vultubus",
        category   = "seafaring",
        tags       = {"seafaring"},
        short      = "Plunder Bonuses",
        long       = "Draw this card while aboard a ship and your vessel shall gain\n"..
                     "a bonus to both its ability to plunder and its ability to\n"..
                     "resist the plundering of enemy pirates for 20 minutes.",
        max        = 3,
        rate       = 1,
    },

    ["Yuthka"] = {
        name       = "Yuthka",
        suit       = "Islanders",
        collection = "Nemesis",
        joker      = "Vultubus",
        category   = "utility",
        tags       = {"travel", "combat", "utility"},
        short      = "Meteor yourself to target",
        long       = "Turn into a meteor arrow, soaring through the sky to strike down\n"..
                     "your target. You will soar to a room in the sky before falling\n"..
                     "down onto your target, if they are outdoors and in your area.\n"..
                     "If you cannot reach your target, you will fall back to your room.",
        max        = 4,
        rate       = 1,
    },

    ["Arsentar"] = {
        name       = "Arsentar",
        suit       = "Islanders",
        collection = "Nemesis",
        joker      = "Vultubus",
        category   = "combat",
        tags       = {"combat", "souls"},
        short      = "Heal on target death 12s",
        long       = "Draw this card for an unfortunate soul and if that person dies\n"..
                     "in the next 12 seconds, you will gain a large amount of your health back.",
        max        = 2,
        rate       = 1,
    },

    ["Trixy"] = {
        name       = "Trixy",
        suit       = "Islanders",
        collection = "Nemesis",
        joker      = "Vultubus",
        category   = "travel",
        tags       = {"travel"},
        short      = "FT to Mysia",
        long       = "Wager gold on red (Mysia) or black (New Thera) for teleport\n"..
                     "to roulette table. Requires full health and mana, respects hinder.\n"..
                     "No minimum wager, usual maximums apply.",
        max        = 3,
        rate       = 1,
    },

    ["Vultubus"] = {
        name       = "Vultubus",
        suit       = "Islanders",
        collection = "Nemesis",
        joker      = "",
        category   = "joker",
        tags       = {"joker"},
        short      = "J: Lor Yut Ars Trx",
        long       = "Joker for Lordan, Yuthka, Arsentar, Trixy.\n"..
                     "Regenerates 1 charge every 12 hours.",
        max        = 1,
        rate       = 12,
    },

    ---------------------------------------------------------------------------
    -- ANCIENTS (Historical)
    ---------------------------------------------------------------------------

    ["Vellis"] = {
        name       = "Vellis",
        suit       = "Ancients",
        collection = "Historical",
        joker      = "Sheep",
        category   = "combat",
        tags       = {"combat"},
        short      = "Tentacle Tat effect",
        long       = "Drawing this card will pull people down from trees or flying elevation!",
        max        = 4,
        rate       = 1,
    },

    ["BlackBoar"] = {
        name       = "BlackBoar",
        suit       = "Ancients",
        collection = "Historical",
        joker      = "Sheep",
        category   = "bashing",
        tags       = {"bashing", "combat"},
        short      = "Group L3 regen",
        long       = "Draw this card to give everyone in your group (including yourself)\n"..
                     "level 3 health regeneration! Must be the leader. Duration 3-5 minutes.\n"..
                     "Overrides other forms of levelled health regeneration.",
        max        = 2,
        rate       = 1,
    },

    ["Seasone"] = {
        name       = "Seasone",
        suit       = "Ancients",
        collection = "Historical",
        joker      = "Sheep",
        category   = "combat",
        tags       = {"bashing", "combat"},
        short      = "Elixir / Poison",
        long       = "DRAW FOR ELIXIR or FOR POISON. Poison will hit everyone in the room\n"..
                     "with two doses of loki (includes yourself).\n"..
                     "Elixir boosts health elixir effectiveness by 10% for 5 minutes.",
        max        = 3,
        rate       = 1,
    },

    ["Rurin"] = {
        name       = "Rurin",
        suit       = "Ancients",
        collection = "Historical",
        joker      = "Sheep",
        category   = "utility",
        tags       = {"utility"},
        short      = "Restock Denizen Shop",
        long       = "Draw to restock a denizen shop to maximum capacity!\n"..
                     "Only works for shops where you use WARES (not ASK denizen WARES).\n"..
                     "Does not affect the Itinerant Bazaar or commodity shops.",
        max        = 1,
        rate       = 2,
    },

    ["Sheep"] = {
        name       = "Sheep",
        suit       = "Ancients",
        collection = "Historical",
        joker      = "",
        category   = "joker",
        tags       = {"joker"},
        short      = "J: Vel BBr Sea Rur",
        long       = "Joker for Vellis, BlackBoar, Seasone, Rurin.\n"..
                     "Regenerates 1 charge every 12 hours.",
        max        = 1,
        rate       = 12,
    },

    ---------------------------------------------------------------------------
    -- ORIGINALS (Historical)
    ---------------------------------------------------------------------------

    ["Haidion"] = {
        name       = "Haidion",
        suit       = "Originals",
        collection = "Historical",
        joker      = "Harlequin",
        category   = "combat",
        tags       = {"combat", "travel", "utility"},
        short      = "Target Celerity Lock",
        long       = "When drawing this card against a target, their celerity will\n"..
                     "be locked to your own. However fast you move, that person\n"..
                     "also moves at that same speed.",
        max        = 3,
        rate       = 1,
    },

    ["Maran"] = {
        name       = "Maran",
        suit       = "Originals",
        collection = "Historical",
        joker      = "Harlequin",
        category   = "combat",
        tags       = {"bashing", "combat"},
        short      = "5000hp shield",
        long       = "Create a barrier in the location that lasts for 1 minute.\n"..
                     "The barrier has 5000 health and absorbs 25% of all damage\n"..
                     "on anyone in the room. When it runs out of health or the timer\n"..
                     "expires, the barrier disappears. Unblockable damage and\n"..
                     "finishers bypass the barrier.",
        max        = 2,
        rate       = 1,
    },

    ["Covenant"] = {
        name       = "Covenant",
        suit       = "Originals",
        collection = "Historical",
        joker      = "Harlequin",
        category   = "bashing",
        tags       = {"bashing"},
        short      = "Rage Reckless/Charmed",
        long       = "Inflict a special battlerage attack against a target, delivering\n"..
                     "the CHARMED status half of the time and the RECKLESS status the other half.",
        max        = 3,
        rate       = 1,
    },

    ["Aringar"] = {
        name       = "Aringar",
        suit       = "Originals",
        collection = "Historical",
        joker      = "Harlequin",
        category   = "combat",
        tags       = {"combat"},
        short      = "Strip Shield LoS",
        long       = "Draw this card to strip the shield from a target in your line of sight.",
        max        = 4,
        rate       = 1,
    },

    ["Harlequin"] = {
        name       = "Harlequin",
        suit       = "Originals",
        collection = "Historical",
        joker      = "",
        category   = "joker",
        tags       = {"joker"},
        short      = "J: Hai Mar Cov Ari",
        long       = "Joker for Haidion, Maran, Covenant, Aringar.\n"..
                     "Regenerates 1 charge every 12 hours.",
        max        = 1,
        rate       = 1,
    },

    ---------------------------------------------------------------------------
    -- IMPUDENT (Renowned)
    ---------------------------------------------------------------------------

    ["Maklak"] = {
        name       = "Maklak",
        suit       = "Impudent",
        collection = "Renowned",
        joker      = "Hycanthus",
        category   = "combat",
        tags       = {"combat"},
        short      = "LoS Icewall",
        long       = "Summon an icewall in line of sight.\n"..
                     "LDECK DRAW MAKLAK NE 2 places an icewall 2 rooms to the northeast.",
        max        = 4,
        rate       = 1,
    },

    ["Xylthus"] = {
        name       = "Xylthus",
        suit       = "Impudent",
        collection = "Renowned",
        joker      = "Hycanthus",
        category   = "bashing",
        tags       = {"bashing"},
        short      = "Rage Bind (stun)",
        long       = "Bind a denizen in a similar manner to a battlerage stun.",
        max        = 3,
        rate       = 1,
    },

    ["Morimbuul"] = {
        name       = "Morimbuul",
        suit       = "Impudent",
        collection = "Renowned",
        joker      = "Hycanthus",
        category   = "bashing",
        tags       = {"bashing", "combat"},
        short      = "Ignore NPC ropes 5 min",
        long       = "Shrug off denizen ropes or bindings for five minutes.",
        max        = 3,
        rate       = 1,
    },

    ["Zh'risia"] = {
        name       = "Zh'risia",
        suit       = "Impudent",
        collection = "Renowned",
        joker      = "Hycanthus",
        category   = "combat",
        tags       = {"combat"},
        short      = "AOE Blaze",
        long       = "Draw this card and all present will be set ablaze.",
        max        = 3,
        rate       = 1,
    },

    ["Hycanthus"] = {
        name       = "Hycanthus",
        suit       = "Impudent",
        collection = "Renowned",
        joker      = "",
        category   = "joker",
        tags       = {"joker"},
        short      = "J: Mak Xyl Mor Zhr",
        long       = "Joker for Maklak, Xylthus, Morimbuul, Zh'risia.\n"..
                     "Regenerates 1 charge every 12 hours.",
        max        = 1,
        rate       = 12,
    },

    ---------------------------------------------------------------------------
    -- AESTHETES (Renowned)
    ---------------------------------------------------------------------------

    ["Murad"] = {
        name       = "Murad",
        suit       = "Aesthetes",
        collection = "Renowned",
        joker      = "Makesh",
        category   = "style",
        tags       = {"style"},
        short      = "Name forged gear",
        long       = "Use your name as a forging descriptor!",
        max        = 1,
        rate       = 1,
    },

    ["Bakios"] = {
        name       = "Bakios",
        suit       = "Aesthetes",
        collection = "Renowned",
        joker      = "Makesh",
        category   = "utility",
        tags       = {"utility"},
        short      = "Random Effect",
        long       = "Drawing this card will confer a random flask effect upon the user.",
        max        = 3,
        rate       = 1,
    },

    ["Maim"] = {
        name       = "Maim",
        suit       = "Aesthetes",
        collection = "Renowned",
        joker      = "Makesh",
        category   = "travel",
        tags       = {"travel", "combat"},
        short      = "FT to player",
        long       = "Create a miniature sculpture of another player.\n"..
                     "LDECK DRAW MAIM <target>. Sculpture lasts 30 minutes.\n"..
                     "BREAK SCULPTURE to travel to the player depicted.\n"..
                     "Travel is prevented by monolith sigils.",
        max        = 3,
        rate       = 1,
    },

    ["Reinhold"] = {
        name       = "Reinhold",
        suit       = "Aesthetes",
        collection = "Renowned",
        joker      = "Makesh",
        category   = "utility",
        tags       = {"utility"},
        short      = "Random food",
        long       = "Draw this card to produce a random food item from the NDS cooking list!",
        max        = 4,
        rate       = 1,
    },

    ["Makesh"] = {
        name       = "Makesh",
        suit       = "Aesthetes",
        collection = "Renowned",
        joker      = "",
        category   = "joker",
        tags       = {"joker"},
        short      = "J: Mur Bak Mai Rei",
        long       = "Joker for Murad, Bakios, Maim, Reinhold.\n"..
                     "Regenerates 1 charge every 12 hours.",
        max        = 1,
        rate       = 12,
    },

    ---------------------------------------------------------------------------
    -- INTREPID (Renowned)
    ---------------------------------------------------------------------------

    ["Horald"] = {
        name       = "Horald",
        suit       = "Intrepid",
        collection = "Renowned",
        joker      = "Boulder",
        category   = "seafaring",
        tags       = {"seafaring"},
        short      = "Ship fire rate buff",
        long       = "Have a chance to reduce your next ship weapon fire balance by 20%.\n"..
                     "This fades after 3 successful firing reductions.",
        max        = 3,
        rate       = 1,
    },

    ["Icosse"] = {
        name       = "Icosse",
        suit       = "Intrepid",
        collection = "Renowned",
        joker      = "Boulder",
        category   = "combat",
        tags       = {"combat", "bashing"},
        short      = "+1 Reflection",
        long       = "Draw this card to gain a reflection!",
        max        = 3,
        rate       = 1,
    },

    ["Aran'kesh"] = {
        name       = "Aran'kesh",
        suit       = "Intrepid",
        collection = "Renowned",
        joker      = "Boulder",
        category   = "utility",
        tags       = {"utility"},
        short      = "Personal stash",
        long       = "Draw this card to summon a vulture nest.\n"..
                     "The nest can hold up to 10 unique items.\n"..
                     "SHAKE nest to send it away. Nest will never decay.",
        max        = 3,
        rate       = 1,
    },

    ["Vulkuz"] = {
        name       = "Vulkuz",
        suit       = "Intrepid",
        collection = "Renowned",
        joker      = "Boulder",
        category   = "combat",
        tags       = {"combat", "utility"},
        short      = "Random Trap",
        long       = "Place a random trap in the location. Clothesline, horseshoe, or noose.\n"..
                     "This trap will target your enemies. Cannot be dismantled.",
        max        = 2,
        rate       = 1,
    },

    ["Boulder"] = {
        name       = "Boulder",
        suit       = "Intrepid",
        collection = "Renowned",
        joker      = "",
        category   = "joker",
        tags       = {"joker"},
        short      = "J: Hor Ico Ara Vul",
        long       = "Joker for Horald, Icosse, Aran'kesh, Vulkuz.\n"..
                     "Regenerates 1 charge every 12 hours.",
        max        = 1,
        rate       = 12,
    },

    ---------------------------------------------------------------------------
    -- LOVERS (Loveless)
    ---------------------------------------------------------------------------

    ["Rudolpho"] = {
        name       = "Rudolpho",
        suit       = "Lovers",
        collection = "Loveless",
        joker      = "Maros",
        category   = "combat",
        tags       = {"combat", "utility"},
        short      = "Prevent Speech 1 min",
        long       = "Bring about a stuttering effect to the current location for ~1 minute.\n"..
                     "Says, tells, and shouts are affected. Includes raido and wings\n"..
                     "but does NOT prevent Call for Help.",
        max        = 2,
        rate       = 1,
    },

    ["Camilla"] = {
        name       = "Camilla",
        suit       = "Lovers",
        collection = "Loveless",
        joker      = "Maros",
        category   = "utility",
        tags       = {"utility", "bashing"},
        short      = "Mutual Allies Follow",
        long       = "Draw this card and all mutual allies present will immediately begin following you.",
        max        = 4,
        rate       = 1,
    },

    ["Anna"] = {
        name       = "Anna",
        suit       = "Lovers",
        collection = "Loveless",
        joker      = "Maros",
        category   = "utility",
        tags       = {"utility"},
        short      = "Privacy 1 min",
        long       = "Draw this card and your current room becomes private for one minute.",
        max        = 1,
        rate       = 5,
    },

    ["Travian"] = {
        name       = "Travian",
        suit       = "Lovers",
        collection = "Loveless",
        joker      = "Maros",
        category   = "combat",
        tags       = {"combat"},
        short      = "Mutual Lust",
        long       = "Draw this card against a target and both of you will gain\n"..
                     "the lusted status with each other.",
        max        = 3,
        rate       = 1,
    },

    ["Maros"] = {
        name       = "Maros",
        suit       = "Lovers",
        collection = "Loveless",
        joker      = "",
        category   = "joker",
        tags       = {"joker"},
        short      = "J: Rud Cam Ann Tra",
        long       = "Joker for Rudolpho, Camilla, Anna, Travian.\n"..
                     "Regenerates 1 charge every 12 hours.",
        max        = 1,
        rate       = 12,
    },

    ---------------------------------------------------------------------------
    -- ESTRANGED (Loveless)
    ---------------------------------------------------------------------------

    ["Maya"] = {
        name       = "Maya",
        suit       = "Estranged",
        collection = "Loveless",
        joker      = "Sallust",
        category   = "utility",
        tags       = {"utility"},
        short      = "Instant Tattoo",
        long       = "Draw this card and the next tattoo you receive will complete instantly.\n"..
                     "Does not work with starburst tattoos. Must be inked within 1 hour.",
        max        = 3,
        rate       = 1,
    },

    ["Belladona"] = {
        name       = "Belladona",
        suit       = "Estranged",
        collection = "Loveless",
        joker      = "Sallust",
        category   = "utility",
        tags       = {"style", "utility"},
        short      = "Unsend a letter",
        long       = "DRAW <card> <recipient> in a postal office to return any letter\n"..
                     "or parcel you sent, provided the recipient has not yet received it.",
        max        = 2,
        rate       = 1,
    },

    ["Zsarachnor"] = {
        name       = "Zsarachnor",
        suit       = "Estranged",
        collection = "Loveless",
        joker      = "Sallust",
        category   = "combat",
        tags       = {"combat"},
        short      = "Force Enemy 30s",
        long       = "Draw this card against a target while specifying another adventurer.\n"..
                     "The target will consider that person as a personal enemy for 30 seconds.\n"..
                     "Target must be in the room; the person to enemy need not be.",
        max        = 2,
        rate       = 2,
    },

    ["Horror"] = {
        name       = "Horror",
        suit       = "Estranged",
        collection = "Loveless",
        joker      = "Sallust",
        category   = "combat",
        tags       = {"combat", "utility", "style"},
        short      = "No saying your name",
        long       = "Draw against a target and your name will shrink from their lips.\n"..
                     "For one Achaean month, the target cannot speak your name aloud.\n"..
                     "For half an Achaean day, they cannot recall your name telepathically.\n"..
                     "You need not be in the room with the target.",
        max        = 1,
        rate       = 30,
    },

    ["Sallust"] = {
        name       = "Sallust",
        suit       = "Estranged",
        collection = "Loveless",
        joker      = "",
        category   = "joker",
        tags       = {"joker"},
        short      = "J: May Bel Zsa Hor",
        long       = "Joker for Maya, Belladona, Zsarachnor, Horror.\n"..
                     "Regenerates 1 charge every 12 hours.",
        max        = 1,
        rate       = 12,
    },

    ---------------------------------------------------------------------------
    -- ANIMALS (Historical)
    ---------------------------------------------------------------------------

    ["Patches"] = {
        name       = "Patches",
        suit       = "Animals",
        collection = "Historical",
        joker      = "Penelope",
        category   = "combat",
        tags       = {"combat"},
        short      = "No Waterwalking 30s",
        long       = "Inflicts 30 seconds of no waterwalk enchantments or\n"..
                     "water weird defences. Other methods of crossing water function as normal.",
        max        = 2,
        rate       = 1,
    },

    ["Scorn"] = {
        name       = "Scorn",
        suit       = "Animals",
        collection = "Historical",
        joker      = "Penelope",
        category   = "combat",
        tags       = {"combat", "utility", "bashing"},
        short      = "Fullsense (+Adjacent)",
        long       = "DRAW in a direction to be informed of all who stand in the target\n"..
                     "room's area. Shares fullsense limitations. 1 second balance loss.",
        max        = 8,
        rate       = 1,
    },

    ["Grimlath"] = {
        name       = "Grimlath",
        suit       = "Animals",
        collection = "Historical",
        joker      = "Penelope",
        category   = "combat",
        tags       = {"combat", "utility"},
        short      = "Pacing 2 min",
        long       = "DRAW this card and benefit from the PACING defence for two minutes.",
        max        = 5,
        rate       = 1,
    },

    ["Chenubis"] = {
        name       = "Chenubis",
        suit       = "Animals",
        collection = "Historical",
        joker      = "Penelope",
        category   = "travel",
        tags       = {"travel"},
        short      = "FT to Mt Nicator",
        long       = "Teleport to the peak of Mount Nicator.\n"..
                     "Must be on Prime Material Plane and Continent of Sapience.\n"..
                     "Blocked by monolith, 2 second balance cost.",
        max        = 2,
        rate       = 1,
    },

    ["Penelope"] = {
        name       = "Penelope",
        suit       = "Animals",
        collection = "Historical",
        joker      = "",
        category   = "joker",
        tags       = {"joker"},
        short      = "J: Pat Sco Gri Chn",
        long       = "Joker for Patches, Scorn, Grimlath, Chenubis.\n"..
                     "Regenerates 1 charge every 12 hours.",
        max        = 1,
        rate       = 12,
    },

    ---------------------------------------------------------------------------
    -- SCRAPPERS (Loveless) - No joker
    ---------------------------------------------------------------------------

    ["Jovan"] = {
        name       = "Jovan",
        suit       = "Scrappers",
        collection = "Loveless",
        joker      = "",
        category   = "utility",
        tags       = {"utility"},
        short      = "Check Infamous",
        long       = "Draw and be informed of all infamous characters currently in the realms,\n"..
                     "including their level of infamy.",
        max        = 5,
        rate       = 1,
    },

    ["Elma"] = {
        name       = "Elma",
        suit       = "Scrappers",
        collection = "Loveless",
        joker      = "",
        category   = "style",
        tags       = {"style"},
        short      = "Scrapper Treats",
        long       = "LDECK DRAW ELMA <scrapper> and reset the cooldown on that\n"..
                     "scrapper's ability to consume treats.",
        max        = 1,
        rate       = 24,
    },

    ["Wavel"] = {
        name       = "Wavel",
        suit       = "Scrappers",
        collection = "Loveless",
        joker      = "",
        category   = "combat",
        tags       = {"combat", "utility"},
        short      = "Trace person 72s",
        long       = "Draw against a target to persistently locate them.\n"..
                     "Ticks every 8 seconds for 72 seconds (9 times total).\n"..
                     "Passively farsees the target each tick. Same limitations as FARSEE.",
        max        = 4,
        rate       = 1,
    },

    ["Yozhik"] = {
        name       = "Yozhik",
        suit       = "Scrappers",
        collection = "Loveless",
        joker      = "",
        category   = "combat",
        tags       = {"combat"},
        short      = "Thornwall",
        long       = "DRAW in a direction to create a thornwall!\n"..
                     "Deals damage and some bleeding when passed through.\n"..
                     "Respects other wall types and will not stack with them.",
        max        = 3,
        rate       = 1,
    },

    ---------------------------------------------------------------------------
    -- KNIGHTS (Salvation)
    ---------------------------------------------------------------------------

    ["Caerid"] = {
        name       = "Caerid",
        suit       = "Knights",
        collection = "Salvation",
        joker      = "Odysseus",
        category   = "combat",
        tags       = {"combat"},
        short      = "Mutual Numb",
        long       = "Draw at a mutual ally and for 10 seconds, you gain numbness defence.\n"..
                     "When this ends, you take standard numb damage but the ally takes double.",
        max        = 1,
        rate       = 1,
    },

    ["Kemnast"] = {
        name       = "Kemnast",
        suit       = "Knights",
        collection = "Salvation",
        joker      = "Odysseus",
        category   = "combat",
        tags       = {"combat", "souls"},
        short      = "Corpse->Heal",
        long       = "Draw to destroy a player corpse on the ground and regain 30% health and mana.\n"..
                     "No balance cost. Does not work on special corpses.",
        max        = 5,
        rate       = 1,
    },

    ["Davis"] = {
        name       = "Davis",
        suit       = "Knights",
        collection = "Salvation",
        joker      = "Odysseus",
        category   = "bashing",
        tags       = {"combat", "bashing"},
        short      = "Defend a friend",
        long       = "Draw at someone to come to their defence like a knight.\n"..
                     "Shares identical restrictions with the knight ability.",
        max        = 3,
        rate       = 1,
    },

    ["Temelin"] = {
        name       = "Temelin",
        suit       = "Knights",
        collection = "Salvation",
        joker      = "Odysseus",
        category   = "utility",
        tags       = {"utility"},
        short      = "See all burrowed",
        long       = "Draw to sense where everyone is burrowed on your current continent.\n"..
                     "Also informs you of how deep they are.",
        max        = 3,
        rate       = 1,
    },

    ["Odysseus"] = {
        name       = "Odysseus",
        suit       = "Knights",
        collection = "Salvation",
        joker      = "",
        category   = "joker",
        tags       = {"joker"},
        short      = "J: Cae Kem Dav Tem",
        long       = "Joker for Caerid, Kemnast, Davis, Temelin.\n"..
                     "Regenerates 1 charge every 12 hours.",
        max        = 1,
        rate       = 1,
    },

    ---------------------------------------------------------------------------
    -- SPIRITSOUL (Forests)
    ---------------------------------------------------------------------------

    ["Clio"] = {
        name       = "Clio",
        suit       = "Spiritsoul",
        collection = "Forests",
        joker      = "Thalia",
        category   = "travel",
        tags       = {"travel"},
        short      = "FT to Forests (Uni)",
        long       = "Draw to create a map of Sapience's forests.\n"..
                     "Touch the map and specify a forest spirit name to teleport\n"..
                     "to that forest. Similar to Universe tarot.",
        max        = 2,
        rate       = 1,
    },

    ["Erato"] = {
        name       = "Erato",
        suit       = "Spiritsoul",
        collection = "Forests",
        joker      = "Thalia",
        category   = "combat",
        tags       = {"combat"},
        short      = "Throw into Trees",
        long       = "Draw at an adventurer and they will be thrown into the trees\n"..
                     "if there are trees present.",
        max        = 3,
        rate       = 1,
    },

    ["Eupheme"] = {
        name       = "Eupheme",
        suit       = "Spiritsoul",
        collection = "Forests",
        joker      = "Thalia",
        category   = "bashing",
        tags       = {"bashing"},
        short      = "Pacify Denizens",
        long       = "Drawing this card pacifies all non-boss animal denizens in the location.\n"..
                     "Does not prevent aggressive denizens from becoming aggressive again.",
        max        = 3,
        rate       = 1,
    },

    ["Calliope"] = {
        name       = "Calliope",
        suit       = "Spiritsoul",
        collection = "Forests",
        joker      = "Thalia",
        category   = "utility",
        tags       = {"utility"},
        short      = "Endurance Regen (REST)",
        long       = "Drawing bestows SLOTH metamorphosis upon the user.\n"..
                     "Confers use of the REST ability to regenerate endurance.",
        max        = 3,
        rate       = 2,
    },

    ["Thalia"] = {
        name       = "Thalia",
        suit       = "Spiritsoul",
        collection = "Forests",
        joker      = "",
        category   = "joker",
        tags       = {"joker"},
        short      = "J: Cli Era Eup Cal",
        long       = "Joker for Clio, Erato, Eupheme, Calliope.\n"..
                     "Regenerates 1 charge every 12 hours.",
        max        = 1,
        rate       = 12,
    },

    ---------------------------------------------------------------------------
    -- SPIRITHEART (Forests)
    ---------------------------------------------------------------------------

    ["Urania"] = {
        name       = "Urania",
        suit       = "Spiritheart",
        collection = "Forests",
        joker      = "Melpomene",
        category   = "combat",
        tags       = {"combat"},
        short      = "Fog 4 min",
        long       = "Draw to blanket the area in fog for 4 minutes.\n"..
                     "Must be a valid area (no wilderness, ships, mines, etc).",
        max        = 1,
        rate       = 2,
    },

    ["Polyhymnia"] = {
        name       = "Polyhymnia",
        suit       = "Spiritheart",
        collection = "Forests",
        joker      = "Melpomene",
        category   = "combat",
        tags       = {"combat"},
        short      = "Clouds Fear",
        long       = "Draw to force everyone in the clouds area to move in a random direction.\n"..
                     "Affects upper skies and far above the skies locations.\n"..
                     "Blocked by anti-beckon effects on a per person basis.",
        max        = 2,
        rate       = 1,
    },

    ["Euterpe"] = {
        name       = "Euterpe",
        suit       = "Spiritheart",
        collection = "Forests",
        joker      = "Melpomene",
        category   = "combat",
        tags       = {"combat"},
        short      = "Unburrow room",
        long       = "Draw to force anyone burrowed in your location or those adjacent\n"..
                     "to be forced back to ground level from any depth.",
        max        = 3,
        rate       = 1,
    },

    ["Terpsichore"] = {
        name       = "Terpsichore",
        suit       = "Spiritheart",
        collection = "Forests",
        joker      = "Melpomene",
        category   = "combat",
        tags       = {"combat"},
        short      = "Fear all mounts",
        long       = "Drawing invokes fear on all mounts in the location,\n"..
                     "similar to a Bard's MARCH. Affects the user's mount too.",
        max        = 1,
        rate       = 1,
    },

    ["Melpomene"] = {
        name       = "Melpomene",
        suit       = "Spiritheart",
        collection = "Forests",
        joker      = "",
        category   = "joker",
        tags       = {"joker"},
        short      = "J: Ura Pol Eut Ter",
        long       = "Joker for Urania, Polyhymnia, Euterpe, Terpsichore.\n"..
                     "Regenerates 1 charge every 12 hours.",
        max        = 1,
        rate       = 12,
    },

    ---------------------------------------------------------------------------
    -- HUNTERSOUL (Hunt)
    ---------------------------------------------------------------------------

    ["Scorpion"] = {
        name       = "Scorpion",
        suit       = "Huntersoul",
        collection = "Hunt",
        joker      = "Jarbo",
        category   = "combat",
        tags       = {"combat"},
        short      = "LoS firewall",
        long       = "Draw with a direction to put firewalls in that direction's line\n"..
                     "of sight up to 3 rooms away if a wall can be raised.",
        max        = 2,
        rate       = 1,
    },

    ["Alligator"] = {
        name       = "Alligator",
        suit       = "Huntersoul",
        collection = "Hunt",
        joker      = "Jarbo",
        category   = "utility",
        tags       = {"utility"},
        short      = "Delay currents 1min",
        long       = "Draw to significantly reduce the effect of currents upon you\n"..
                     "for 1 minute. Shows on DEFS as alligatorlegend.",
        max        = 3,
        rate       = 1,
    },

    ["Whitewolf"] = {
        name       = "Whitewolf",
        suit       = "Huntersoul",
        collection = "Hunt",
        joker      = "Jarbo",
        category   = "combat",
        tags       = {"combat"},
        short      = "Hit parry cure aff",
        long       = "Draw to grant yourself the wolflegend defence for 40 seconds.\n"..
                     "If you strike someone's parry while you have this defence,\n"..
                     "you will passively cure an affliction. 30s CD.",
        max        = 1,
        rate       = 2,
    },

    ["Bear"] = {
        name       = "Bear",
        suit       = "Huntersoul",
        collection = "Hunt",
        joker      = "Jarbo",
        category   = "utility",
        tags       = {"utility"},
        short      = "Global sense stinkers",
        long       = "Draw to sense everyone afflicted with the stink affliction.\n"..
                     "Works across planes, but not on people in beds and similar no-farsee locations.",
        max        = 5,
        rate       = 1,
    },

    ["Jarbo"] = {
        name       = "Jarbo",
        suit       = "Huntersoul",
        collection = "Hunt",
        joker      = "",
        category   = "joker",
        tags       = {"joker"},
        short      = "J: Sco Ali Wlf Bea",
        long       = "Joker for Scorpion, Alligator, Whitewolf, Bear.\n"..
                     "Regenerates 1 charge every 12 hours.",
        max        = 1,
        rate       = 12,
    },

    ---------------------------------------------------------------------------
    -- HUNTERBLOOD (Hunt)
    ---------------------------------------------------------------------------

    ["Eagle"] = {
        name       = "Eagle",
        suit       = "Hunterblood",
        collection = "Hunt",
        joker      = "Eel",
        category   = "combat",
        tags       = {"combat"},
        short      = "Lightning res while flying",
        long       = "Grants 10% lightning resistance when flying, lasts 1 minute.\n"..
                     "Shows on DEFS as eaglelegend.",
        max        = 3,
        rate       = 1,
    },

    ["Centaur"] = {
        name       = "Centaur",
        suit       = "Hunterblood",
        collection = "Hunt",
        joker      = "Eel",
        category   = "combat",
        tags       = {"combat"},
        short      = "Chaotic tentacle",
        long       = "Draw targeting someone in the sky above you and pull them down\n"..
                     "like a tentacle tattoo. Instead of balance knock it can do one of:\n"..
                     "stun/entangle/balance knock (equal chance).",
        max        = 3,
        rate       = 1,
    },

    ["Leopard"] = {
        name       = "Leopard",
        suit       = "Hunterblood",
        collection = "Hunt",
        joker      = "Eel",
        category   = "combat",
        tags       = {"combat"},
        short      = "Adjacent freeze ground",
        long       = "Draw with a given direction to freeze ground in that adjacent location.",
        max        = 3,
        rate       = 1,
    },

    ["Eel"] = {
        name       = "Eel",
        suit       = "Hunterblood",
        collection = "Hunt",
        joker      = "",
        category   = "joker",
        tags       = {"joker"},
        short      = "J: Eag Cen Leo",
        long       = "Joker for Eagle, Centaur, Leopard.\n"..
                     "Regenerates 1 charge every 12 hours.",
        max        = 1,
        rate       = 12,
    },

    ---------------------------------------------------------------------------
    -- MOONS (Celestial)
    ---------------------------------------------------------------------------

    ["Somnustra"] = {
        name       = "Somnustra",
        suit       = "Moons",
        collection = "Celestial",
        joker      = "Abbadon",
        category   = "utility",
        tags       = {"utility"},
        short      = "Extra wp regen 15min",
        long       = "Draw to bestow a restorative effect upon an outdoors location,\n"..
                     "granting enhanced willpower regen for 15 minutes.",
        max        = 2,
        rate       = 1,
    },

    ["Noxtra"] = {
        name       = "Noxtra",
        suit       = "Moons",
        collection = "Celestial",
        joker      = "Abbadon",
        category   = "combat",
        tags       = {"combat"},
        short      = "Stops flying + duanathar 3min",
        long       = "Draw to prevent all flight in the room for three minutes.\n"..
                     "This includes duanathar.",
        max        = 2,
        rate       = 2,
    },

    ["Lae"] = {
        name       = "Lae",
        suit       = "Moons",
        collection = "Celestial",
        joker      = "Abbadon",
        category   = "utility",
        tags       = {"utility"},
        short      = "+Int, -Con until dawn/dusk",
        long       = "Draw to boost your intelligence at the expense of your constitution,\n"..
                     "until the next dawn or dusk.",
        max        = 1,
        rate       = 3,
    },

    ["Lunastra"] = {
        name       = "Lunastra",
        suit       = "Moons",
        collection = "Celestial",
        joker      = "Abbadon",
        category   = "combat",
        tags       = {"combat"},
        short      = "Move flooding adjacent->here",
        long       = "Draw in a given direction: if that adjacent room is flooded,\n"..
                     "unflood it and bring about a tide to flood yours in its place.",
        max        = 3,
        rate       = 1,
    },

    ["Abbadon"] = {
        name       = "Abbadon",
        suit       = "Moons",
        collection = "Celestial",
        joker      = "",
        category   = "joker",
        tags       = {"joker"},
        short      = "J: Som Nox Lae Lun",
        long       = "Joker for Somnustra, Noxtra, Lae, Lunastra.\n"..
                     "Regenerates 1 charge every 12 hours.",
        max        = 1,
        rate       = 12,
    },

    ---------------------------------------------------------------------------
    -- SUNS (Celestial)
    ---------------------------------------------------------------------------

    ["Gelartha"] = {
        name       = "Gelartha",
        suit       = "Suns",
        collection = "Celestial",
        joker      = "Ethian",
        category   = "utility",
        tags       = {"utility"},
        short      = "Show shrines in area",
        long       = "Draw to call upon the sun of Loramere to reveal all shrines in your local area.",
        max        = 3,
        rate       = 1,
    },

    ["Tel'shaen"] = {
        name       = "Tel'shaen",
        suit       = "Suns",
        collection = "Celestial",
        joker      = "Ethian",
        category   = "utility",
        tags       = {"utility"},
        short      = "Raremineral reroll",
        long       = "Draw to convert an existing rare mineral into a different one at random.\n"..
                     "Can only be done once per item, and only on edible minerals.",
        max        = 1,
        rate       = 3,
    },

    ["Telar"] = {
        name       = "Telar",
        suit       = "Suns",
        collection = "Celestial",
        joker      = "Ethian",
        category   = "utility",
        tags       = {"utility"},
        short      = "Max XP bonus in area",
        long       = "Draw to restore all native, alive, non-sentient denizens in the area\n"..
                     "to their maximum long-lived state. Does not work on spawner denizens or bosses.\n"..
                     "Provides max 'alive for a long time' XP bonus to affected denizens.",
        max        = 2,
        rate       = 1,
    },

    ["Mother"] = {
        name       = "Mother",
        suit       = "Suns",
        collection = "Celestial",
        joker      = "Ethian",
        category   = "utility",
        tags       = {"utility"},
        short      = "Keep defs post burst",
        long       = "Draw to call upon the life-giver of Elemental Earth. When a starburst\n"..
                     "already blesses you, Mother will allow you to keep many of your\n"..
                     "defences when you next perish.",
        max        = 2,
        rate       = 2,
    },

    ["Ethian"] = {
        name       = "Ethian",
        suit       = "Suns",
        collection = "Celestial",
        joker      = "",
        category   = "joker",
        tags       = {"joker"},
        short      = "J: Tel Gel Tlr Mot",
        long       = "Joker for Tel'shaen, Gelartha, Telar, Mother.\n"..
                     "Regenerates 1 charge every 12 hours.",
        max        = 1,
        rate       = 12,
    },

    ---------------------------------------------------------------------------
    -- TITANS (Enigma)
    ---------------------------------------------------------------------------

    ["Rovalamm"] = {
        name       = "Rovalamm",
        suit       = "Titans",
        collection = "Enigma",
        joker      = "Chellen",
        category   = "travel",
        tags       = {"travel"},
        short      = "Chase to stratosphere",
        long       = "Draw against someone on your continent in the stratosphere\n"..
                     "to be teleported to them. Stopped by monolith on your end, not theirs.",
        max        = 1,
        rate       = 1,
    },

    ["Aigra"] = {
        name       = "Aigra",
        suit       = "Titans",
        collection = "Enigma",
        joker      = "Chellen",
        category   = "utility",
        tags       = {"utility"},
        short      = "Check tanks worldwide",
        long       = "Draw to learn the location of any active tanks in the world,\n"..
                     "including their percentage charge.",
        max        = 3,
        rate       = 1,
    },

    ["Chellen"] = {
        name       = "Chellen",
        suit       = "Titans",
        collection = "Enigma",
        joker      = "",
        category   = "joker",
        tags       = {"joker"},
        short      = "J: Rov Aig",
        long       = "Joker for Rovalamm, Aigra.\n"..
                     "Regenerates 1 charge every 12 hours.",
        max        = 1,
        rate       = 12,
    },

    ---------------------------------------------------------------------------
    -- ANCIENTSTAFF (Champions)
    ---------------------------------------------------------------------------

    ["Isildur"] = {
        name       = "Isildur",
        suit       = "Ancientstaff",
        collection = "Champions",
        joker      = "",
        category   = "utility",
        tags       = {"utility"},
        short      = "Double renown for target",
        long       = "Double renown for target.",
        max        = 1,
        rate       = 24,
    },

    ["Shakti"] = {
        name       = "Shakti",
        suit       = "Ancientstaff",
        collection = "Champions",
        joker      = "",
        category   = "combat",
        tags       = {"combat"},
        short      = "Destroy stonewall",
        long       = "Destroy any stonewall.",
        max        = 1,
        rate       = 1,
    },

    ["Roncli"] = {
        name       = "Roncli",
        suit       = "Ancientstaff",
        collection = "Champions",
        joker      = "",
        category   = "utility",
        tags       = {"utility"},
        short      = "Learn mobtypes for area",
        long       = "Learn mobtypes for area.",
        max        = 1,
        rate       = 1,
    },

    ["Reiye"] = {
        name       = "Reiye",
        suit       = "Ancientstaff",
        collection = "Champions",
        joker      = "",
        category   = "combat",
        tags       = {"combat"},
        short      = "Chameleon bypassed QW",
        long       = "Chameleon bypassed quick-wits.",
        max        = 1,
        rate       = 1,
    },

    ["Jaizsur"] = {
        name       = "Jaizsur",
        suit       = "Ancientstaff",
        collection = "Champions",
        joker      = "",
        category   = "combat",
        tags       = {"combat"},
        short      = "Self and target fly",
        long       = "Self and target fly.",
        max        = 1,
        rate       = 1,
    },
}

-- =========================================================================
-- REVERSE LOOKUP TABLES
-- =========================================================================

-- Build suit -> cards lookup
ldm.suitCards = {}
for key, card in pairs(ldm.db) do
    if not ldm.suitCards[card.suit] then
        ldm.suitCards[card.suit] = {}
    end
    table.insert(ldm.suitCards[card.suit], key)
end

-- Build collection -> suits lookup (for display ordering)
ldm.collectionSuits = ldm.collections
