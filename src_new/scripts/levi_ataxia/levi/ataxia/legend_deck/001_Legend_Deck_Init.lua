--[[mudlet
type: script
name: Legend Deck Init
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
    LEGEND DECK MANAGER - INITIALIZATION
    ============================================================================
    Initializes the ldm namespace, configuration, and backward compatibility
    proxy for ataxiaTables.ldeckcardscount.

    Loads BEFORE 002_Legend_Deck_DB.lua (which populates ldm.db).
    ============================================================================
]]--

ldm = ldm or {}
ldm.version = "2.0"
ldm.enabled = true

-- Live deck state: card -> {charges, max_charges, charge_timer}
-- Populated by ldm.initDeck() from ldm.db defaults, updated by triggers
ldm.deck = ldm.deck or {}

-- Configuration
ldm.config = ldm.config or {
    hide_jokers = true,
    debug = false,
    echoDraws = true,
}

-- Parser state (for ldeck list output)
ldm.state = ldm.state or {
    parsing = false,
    parsedCards = {},
}

-- Favorites (marked with arrow in display)
ldm.favorites = ldm.favorites or {"Bakios", "Polyhymnia"}

-- Cooldown tracking for auto-draw (card -> epoch when available)
ldm.cooldowns = ldm.cooldowns or {}

-- Display colors
ldm.cols = {
    pri       = "<white>",
    sec       = "<blue>",
    combat    = "<red>",
    travel    = "<magenta>",
    utility   = "<white>",
    bashing   = "<yellow>",
    seafaring = "<cyan>",
    style     = "<pink>",
    souls     = "<slate_grey>",
    joker     = "<purple>",
}

-- =============================================================================
-- BACKWARD COMPATIBILITY: ataxiaTables.ldeckcardscount proxy
-- =============================================================================
-- Existing basher code reads: ataxiaTables.ldeckcardscount.Maran > 0
-- Existing triggers write:   ataxiaTables.ldeckcardscount.Matic = matches[3]
-- This proxy routes those reads/writes through ldm.deck.
--
-- Key mapping: old keys (mixed case, no punctuation) -> ldm.db keys
-- =============================================================================

local OLD_KEY_TO_DB = {
    Agithmaal    = "Agith'maal",
    Agithtai     = "Agith'tai",
    Alcibiades   = "Alcibiades",
    Alligator    = "Alligator",
    Amamaalier   = "Ama-maalier",
    Ashaxei      = "Ashaxei",
    Bakios       = "Bakios",
    Bear         = "Bear",
    Belladona    = "Belladona",
    Camilla      = "Camilla",
    Catarin      = "Catarin",
    Centaur      = "Centaur",
    Covenant     = "Covenant",
    Davis        = "Davis",
    Eagle        = "Eagle",
    Elma         = "Elma",
    Enheduanna   = "Enheduanna",
    Hansilnar    = "Han-silnar",
    Horror       = "Horror",
    Jovan        = "Jovan",
    Kemnast      = "Kemnast",
    Leopard      = "Leopard",
    Maran        = "Maran",
    Matic        = "Matic",
    Maya         = "Maya",
    Morimbuul    = "Morimbuul",
    Nicator      = "Nicator",
    Pazuzu       = "Pazuzu",
    Rudolpho     = "Rudolpho",
    SeasoneE     = "Seasone",
    SeasoneP     = "Seasone",
    Severian     = "Severian",
    Slith        = "Slith",
    Sycaerunax   = "Sycaerunax",
    Travian      = "Travian",
    Ugrach       = "Ugrach",
    Urania       = "Urania",
    Vulkuz       = "Vulkuz",
    Wavel        = "Wavel",
    Xylthus      = "Xylthus",
    Yozhik       = "Yozhik",
    Yudhishthira = "Yudhishthira",
    Yuthka       = "Yuthka",
}

ataxiaTables = ataxiaTables or {}
ataxiaTables.ldeckcardscount = setmetatable({}, {
    __index = function(_, key)
        -- Map old key to ldm.db key, or try direct match
        local dbKey = OLD_KEY_TO_DB[key] or key
        if ldm.deck[dbKey] then
            return ldm.deck[dbKey].charges or 0
        end
        return 0
    end,
    __newindex = function(_, key, val)
        local dbKey = OLD_KEY_TO_DB[key] or key
        if ldm.deck[dbKey] then
            ldm.deck[dbKey].charges = tonumber(val) or 0
        end
    end,
})

-- Legacy wrapper: called by old code that expects to reset charge counts
function tracklegenddeckcountreset()
    if ldm.resetCharges then
        ldm.resetCharges()
    end
end

-- =============================================================================
-- DECK INITIALIZATION
-- =============================================================================

--[[
    Initialize ldm.deck from ldm.db defaults.
    Only adds entries for cards not already in ldm.deck (preserves loaded state).
    Called after ldm.db is populated (002) and after ldm.load() (004).
]]--
function ldm.initDeck()
    if not ldm.db then return end
    for key, card in pairs(ldm.db) do
        if not ldm.deck[key] then
            ldm.deck[key] = {
                charges      = card.max or 0,
                max_charges  = card.max or 0,
                charge_timer = 0,
            }
        else
            -- Ensure max_charges stays in sync with db
            ldm.deck[key].max_charges = card.max or ldm.deck[key].max_charges
        end
    end
end

--[[
    Reset all card charges to their max values.
]]--
function ldm.resetCharges()
    if not ldm.db then return end
    for key, card in pairs(ldm.db) do
        ldm.deck[key] = {
            charges      = card.max or 0,
            max_charges  = card.max or 0,
            charge_timer = 0,
        }
    end
end

-- =============================================================================
-- INIT MESSAGE
-- =============================================================================

if Algedonic and Algedonic.Echo then
    Algedonic.Echo("<cyan>Legend Deck Manager v" .. ldm.version .. "<white> initialized.")
else
    cecho("<cyan>Legend Deck Manager v" .. ldm.version .. "<white> initialized.\n")
end
