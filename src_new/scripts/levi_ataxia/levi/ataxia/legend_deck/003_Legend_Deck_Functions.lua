--[[mudlet
type: script
name: Legend Deck Functions
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
    LEGEND DECK MANAGER - FUNCTIONS
    ============================================================================
    Display, parsing, query API, joker, and combat display functions.
    ============================================================================
]]--

ldm = ldm or {}

-- =============================================================================
-- CORE HELPERS
-- =============================================================================

function ldm.echo(str)
    cecho("\n" .. ldm.cols.sec .. "[" .. ldm.cols.pri .. "LDM" .. ldm.cols.sec .. "]" .. ldm.cols.pri .. " " .. str .. "<reset>")
end

function ldm.toggle(arg)
    if arg == nil then
        ldm.enabled = not ldm.enabled
    elseif arg == true or arg == "on" then
        ldm.enabled = true
    elseif arg == false or arg == "off" then
        ldm.enabled = false
    end
    ldm.echo("Legend Deck Manager " .. (ldm.enabled and "<green>Enabled" or "<red>Disabled"))
end

function ldm.command(cmd)
    if cmd == nil or cmd == "" then
        ldm.toggle()
    elseif cmd:lower() == "on" then
        ldm.toggle(true)
    elseif cmd:lower() == "off" then
        ldm.toggle(false)
    elseif cmd:lower() == "combat" or cmd:lower() == "c" then
        ldm.printCombat()
    elseif cmd:lower() == "help" or cmd:lower() == "?" then
        ldm.printHelp()
    elseif cmd:lower() == "save" then
        ldm.save()
        ldm.echo("Saved.")
    elseif cmd:lower() == "load" then
        ldm.load()
        ldm.echo("Loaded.")
    elseif cmd:lower() == "reset" then
        ldm.resetCharges()
        ldm.echo("All charges reset to max.")
    elseif cmd:lower() == "refresh" then
        send("ldeck list")
    else
        -- Try as filter for display
        ldm.displayDeck(cmd)
    end
end

function ldm.printHelp()
    cecho("\n<cyan>===== Legend Deck Manager v" .. ldm.version .. " =====<reset>")
    cecho("\n<white>  ldm          <dim_grey>Toggle on/off<reset>")
    cecho("\n<white>  ldm on/off    <dim_grey>Enable/disable<reset>")
    cecho("\n<white>  ldm combat    <dim_grey>Show combat-relevant cards<reset>")
    cecho("\n<white>  ldm <filter>  <dim_grey>Show cards (all/combat/travel/suit/collection)<reset>")
    cecho("\n<white>  ldm refresh   <dim_grey>Send 'ldeck list' to update charges<reset>")
    cecho("\n<white>  ldm save      <dim_grey>Save deck state<reset>")
    cecho("\n<white>  ldm reset     <dim_grey>Reset all charges to max<reset>")
    cecho("\n<white>  ldraw <card>  <dim_grey>Draw joker for card's suit<reset>")
    cecho("\n<white>  ldc           <dim_grey>Quick combat card display<reset>")
    cecho("\n<cyan>====================================<reset>\n")
end

-- =============================================================================
-- QUERY API (for combat scripts)
-- =============================================================================

function ldm.hasCharges(cardKey)
    return ldm.deck[cardKey] and ldm.deck[cardKey].charges and ldm.deck[cardKey].charges > 0
end

function ldm.getCharges(cardKey)
    return ldm.deck[cardKey] and ldm.deck[cardKey].charges or 0
end

function ldm.getMaxCharges(cardKey)
    return ldm.deck[cardKey] and ldm.deck[cardKey].max_charges or 0
end

--[[
    Draw a card. Returns true if charges available, false otherwise.
    Sends the draw command directly.
]]--
function ldm.draw(cardKey, target)
    if not ldm.hasCharges(cardKey) then
        ldm.echo("<red>No charges for " .. cardKey)
        return false
    end
    local cmd = "ldeck draw " .. cardKey
    if target and target ~= "" then
        cmd = cmd .. " " .. target
    end
    send(cmd)
    return true
end

--[[
    Draw a card via Achaea's queue system.
    queueType: "free" (default), "bal", "eq", "eqbal"
]]--
function ldm.drawQueued(cardKey, target, queueType)
    if not ldm.hasCharges(cardKey) then
        ldm.echo("<red>No charges for " .. cardKey)
        return false
    end
    queueType = queueType or "free"
    local cmd = "ldeck draw " .. cardKey
    if target and target ~= "" then
        cmd = cmd .. " " .. target
    end
    send("queue add " .. queueType .. " " .. cmd)
    return true
end

-- =============================================================================
-- DRAW EVENT HANDLER
-- =============================================================================

--[[
    Called when a card draw is confirmed by trigger.
    Decrements charges and saves.
]]--
function ldm.onDraw(cardKey)
    if ldm.deck[cardKey] then
        ldm.deck[cardKey].charges = math.max(0, (ldm.deck[cardKey].charges or 0) - 1)
        if ldm.config.echoDraws then
            local card = ldm.db[cardKey]
            local col = card and ldm.cols[card.category] or ldm.cols.pri
            ldm.echo(col .. cardKey .. ldm.cols.pri .. " drawn. " ..
                     ldm.cols.sec .. "[" .. ldm.cols.pri ..
                     ldm.deck[cardKey].charges .. "/" .. ldm.deck[cardKey].max_charges ..
                     ldm.cols.sec .. "]")
        end
        ldm.save()
    end
end

-- =============================================================================
-- JOKER FUNCTIONS
-- =============================================================================

function ldm.getJoker(cardKey)
    local card = ldm.db[cardKey]
    if not card then return nil end
    if card.category == "joker" then return nil end
    local jokerName = card.joker
    if not jokerName or jokerName == "" then return nil end
    return jokerName
end

function ldm.useJoker(cardKey)
    -- Accept case-insensitive input
    local found = nil
    for key, _ in pairs(ldm.db) do
        if key:lower() == cardKey:lower() then
            found = key
            break
        end
    end
    if not found then
        ldm.echo("<red>Unknown card: " .. cardKey)
        return
    end

    local card = ldm.db[found]
    if card.category == "joker" then
        ldm.echo(found .. " is a Joker! Use this to charge other cards in its suit.")
        return
    end
    if not card.joker or card.joker == "" then
        ldm.echo(found .. " has no joker.")
        return
    end
    if not ldm.hasCharges(card.joker) then
        ldm.echo("<red>No joker charges for " .. card.joker)
        return
    end
    send("ldeck draw " .. card.joker .. " " .. found)
end

-- =============================================================================
-- PARSING (ldeck list output)
-- =============================================================================

function ldm.deckStart()
    ldm.state.parsing = true
    ldm.state.parsedCards = {}
    enableTrigger("LDM List Line")
    enableTrigger("LDM List Stop")
    enableTrigger("LDM Gag Dashes")
    deleteLine()
end

function ldm.deckLine(card, nCharges, nMax, nTimer)
    ldm.state.parsedCards[card] = {
        charges      = tonumber(nCharges) or 0,
        max_charges  = tonumber(nMax) or 0,
        charge_timer = tonumber(nTimer) or 0,
    }
    -- Special case: Ugrach has infinite charges
    if card == "Ugrach" then
        ldm.state.parsedCards[card].max_charges = 99
    end
    if ldm.enabled then deleteLine() end
end

function ldm.deckStop()
    ldm.state.parsing = false
    disableTrigger("LDM List Line")
    disableTrigger("LDM List Stop")
    disableTrigger("LDM Gag Dashes")
    -- Update ldm.deck from parsed data
    for card, data in pairs(ldm.state.parsedCards) do
        ldm.deck[card] = data
    end
    ldm.save()
    if ldm.enabled then
        ldm.displayDeck(ldm.state.displayFilter or "all")
    end
    ldm.state.displayFilter = nil
end

-- =============================================================================
-- DISPLAY FUNCTIONS
-- =============================================================================

function ldm.displayDeck(filter)
    if not ldm.enabled then return end
    filter = filter or "all"

    cecho("\n" .. ldm.cols.sec .. "+" .. string.rep("=", 76) .. "+")
    cecho("\n" .. ldm.cols.sec .. "|" .. ldm.cols.pri .. " Name          " ..
          ldm.cols.sec .. "[" .. ldm.cols.pri .. "Chg/Max|Rate|Jkr" ..
          ldm.cols.sec .. "]  " .. ldm.cols.pri .. "Description" ..
          string.rep(" ", 19) ..
          ldm.cols.combat .. "C " .. ldm.cols.travel .. "T " ..
          ldm.cols.utility .. "U " .. ldm.cols.bashing .. "B " ..
          ldm.cols.seafaring .. "S " .. ldm.cols.style .. "Y " ..
          ldm.cols.sec .. "|")
    cecho("\n" .. ldm.cols.sec .. "+" .. string.rep("-", 76) .. "+")

    local filterLower = filter:lower()

    -- Check if filter is a category
    local isCategory = false
    for _, cat in ipairs(ldm.categories) do
        if cat == filterLower then isCategory = true; break end
    end

    if filterLower == "all" then
        for _, category in ipairs(ldm.categories) do
            if not (category == "joker" and ldm.config.hide_jokers) then
                ldm.printCategory(category)
            end
        end
    elseif isCategory then
        ldm.printCategory(filterLower)
        -- Also show cards that have this as a tag but not primary category
        for key, _ in pairs(ldm.deck) do
            if ldm.db[key] and ldm.db[key].category ~= filterLower
               and table.contains(ldm.db[key].tags, filterLower) then
                ldm.printCard(key)
            end
        end
    else
        -- Try as collection name
        local filterTitle = filter:sub(1,1):upper() .. filter:sub(2):lower()
        if ldm.collections[filterTitle] then
            ldm.printCollection(filterTitle)
        else
            -- Try as suit name
            local foundSuit = false
            for collection, suits in pairs(ldm.collections) do
                for _, suit in ipairs(suits) do
                    if suit:lower() == filterLower then
                        ldm.printSuit(suit, collection)
                        foundSuit = true
                        break
                    end
                end
                if foundSuit then break end
            end
            if not foundSuit then
                -- Fallback: show all
                for _, category in ipairs(ldm.categories) do
                    if not (category == "joker" and ldm.config.hide_jokers) then
                        ldm.printCategory(category)
                    end
                end
            end
        end
    end

    cecho("\n" .. ldm.cols.sec .. "+" .. string.rep("=", 76) .. "+<reset>\n")
end

function ldm.printCategory(category)
    local label = category:sub(1,1):upper() .. category:sub(2)
    local padding = string.rep("-", 62 - #label)
    cecho("\n" .. ldm.cols.sec .. "+-- " .. ldm.cols.pri .. label .. " " ..
          ldm.cols.sec .. padding .. "+")

    -- Collect and sort cards for this category
    local cards = {}
    for key, _ in pairs(ldm.deck) do
        if ldm.db[key] and ldm.db[key].category == category then
            table.insert(cards, key)
        end
    end
    table.sort(cards)

    for _, key in ipairs(cards) do
        ldm.printCard(key)
    end
end

function ldm.printCollection(collection)
    local suits = ldm.collections[collection]
    if not suits then return end
    for _, suit in ipairs(suits) do
        ldm.printSuit(suit, collection)
    end
end

function ldm.printSuit(suit, collection)
    local label = suit .. " (" .. collection .. ")"
    local padding = string.rep("-", 60 - #label)
    cecho("\n" .. ldm.cols.sec .. "+-- " .. ldm.cols.pri .. label .. " " ..
          ldm.cols.sec .. padding .. "+")

    -- Sort cards in suit, joker last
    local cards = {}
    local joker = nil
    for key, _ in pairs(ldm.deck) do
        if ldm.db[key] and ldm.db[key].suit == suit then
            if ldm.db[key].category == "joker" then
                joker = key
            else
                table.insert(cards, key)
            end
        end
    end
    table.sort(cards)
    for _, key in ipairs(cards) do
        ldm.printCard(key)
    end
    if joker and not ldm.config.hide_jokers then
        ldm.printCard(joker)
    end

    -- Show missing cards
    local missing = {}
    for key, card in pairs(ldm.db) do
        if card.suit == suit and not ldm.deck[key] then
            table.insert(missing, key)
        end
    end
    if #missing > 0 then
        table.sort(missing)
        cecho("\n" .. ldm.cols.sec .. "|   [" .. ldm.cols.pri .. "Missing" ..
              ldm.cols.sec .. "] <slate_grey>" .. table.concat(missing, ", ") ..
              "<reset>")
    end
end

function ldm.printCard(cardKey)
    local card = ldm.db[cardKey]
    local deck = ldm.deck[cardKey]
    if not card or not deck then return end

    -- Skip jokers if hidden
    if card.category == "joker" and ldm.config.hide_jokers then return end

    local line = ldm.cols.sec .. "| "

    -- Favorite marker
    if ldm.favorites and table.contains(ldm.favorites, cardKey) then
        line = line .. "<yellow>* "
    else
        line = line .. "  "
    end

    -- Card name (colored by category)
    local col = ldm.cols[card.category] or ldm.cols.pri
    line = line .. col .. string.format("%-13s", cardKey)

    -- Charges [chg/max|rate|jkr]
    local chargeCol
    if deck.charges == 0 then
        chargeCol = "<firebrick>"
    elseif deck.charges < deck.max_charges then
        chargeCol = "<yellow>"
    else
        chargeCol = ldm.cols.pri
    end
    line = line .. ldm.cols.sec .. "[" .. chargeCol .. string.format("%2d", deck.charges) ..
           ldm.cols.sec .. "/" .. ldm.cols.pri .. string.format("%2d", deck.max_charges) ..
           ldm.cols.sec .. "|" .. ldm.cols.pri .. string.format("%2d", card.rate) .. "h"

    -- Joker indicator
    if card.category ~= "joker" then
        local jokerKey = card.joker
        if jokerKey and jokerKey ~= "" and ldm.deck[jokerKey] then
            if ldm.deck[jokerKey].charges > 0 then
                line = line .. ldm.cols.sec .. "|<green>J"
            else
                line = line .. ldm.cols.sec .. "|<firebrick>J"
            end
        else
            line = line .. ldm.cols.sec .. "| "
        end
    else
        line = line .. ldm.cols.sec .. "|<slate_grey>-"
    end
    line = line .. ldm.cols.sec .. "] "

    -- Short description
    line = line .. col .. string.format("%-30s", card.short)

    -- Tag indicators
    local tagStr = ""
    tagStr = tagStr .. (table.contains(card.tags, "combat") and ldm.cols.combat .. "C " or "  ")
    tagStr = tagStr .. (table.contains(card.tags, "travel") and ldm.cols.travel .. "T " or "  ")
    tagStr = tagStr .. (table.contains(card.tags, "utility") and ldm.cols.utility .. "U " or "  ")
    tagStr = tagStr .. (table.contains(card.tags, "bashing") and ldm.cols.bashing .. "B " or "  ")
    tagStr = tagStr .. (table.contains(card.tags, "seafaring") and ldm.cols.seafaring .. "S " or "  ")
    tagStr = tagStr .. (table.contains(card.tags, "style") and ldm.cols.style .. "Y " or "  ")
    line = line .. tagStr .. ldm.cols.sec .. "|"

    cecho("\n" .. line)
end

-- =============================================================================
-- COMBAT DISPLAY
-- =============================================================================

function ldm.printCombat()
    cecho("\n<cyan>===== Legend Deck: Combat Cards =====<reset>")

    local sections = {
        {
            title = "Pre-Fight Setup",
            cards = {
                {"Pazuzu",      "Prevent FT 1 min"},
                {"Haidion",     "Lock target celerity"},
                {"Grimlath",    "Pacing defense 2 min"},
                {"Noxtra",      "Stop flying + duanathar 3 min"},
            },
        },
        {
            title = "Lock Phase",
            cards = {
                {"Aringar",     "Strip shield LoS"},
                {"Vellis",      "Pull from trees/flying"},
                {"Centaur",     "Pull from sky + stun/entangle"},
                {"Seasone",     "Double loki room (FOR POISON)"},
            },
        },
        {
            title = "Execute / Finish",
            cards = {
                {"Ama-maalier", "Self-root 10s (immovable)"},
                {"Rudolpho",    "Prevent speech 1 min"},
                {"Yozhik",      "Thornwall (block escape)"},
                {"Maklak",      "LoS Icewall (block escape)"},
            },
        },
        {
            title = "Defensive / Emergency",
            cards = {
                {"Maran",       "5000hp barrier (25% absorb)"},
                {"Icosse",      "+1 Reflection"},
                {"Agith'tai",   "Reflect focus affs 30s"},
                {"Sycaerunax",  "2nd wind 10s on death"},
                {"Whitewolf",   "Cure aff on hitting parry 40s"},
            },
        },
        {
            title = "Group Combat",
            cards = {
                {"Severian",    "Steelmind all allies"},
                {"Zsarachnor",  "Force enemy another player 30s"},
                {"Parni",       "Hatred 20s (treat all as enemy)"},
            },
        },
        {
            title = "Movement Control",
            cards = {
                {"Scorpion",    "LoS firewall (up to 3 rooms)"},
                {"Erato",       "Throw into trees"},
                {"Leopard",     "Adjacent freeze ground"},
                {"Lunastra",    "Move flooding adjacent->here"},
            },
        },
    }

    for _, section in ipairs(sections) do
        cecho("\n<white>  --- " .. section.title .. " ---<reset>")
        for _, entry in ipairs(section.cards) do
            local cardKey = entry[1]
            local desc = entry[2]
            local charges = ldm.getCharges(cardKey)
            local maxCharges = ldm.getMaxCharges(cardKey)

            local chargeCol
            if charges == 0 then
                chargeCol = "<firebrick>"
            elseif charges < maxCharges then
                chargeCol = "<yellow>"
            else
                chargeCol = "<green>"
            end

            cecho("\n  " .. chargeCol .. string.format("[%d/%d]", charges, maxCharges) ..
                  "<reset> " .. string.format("%-14s", cardKey) ..
                  "<dim_grey>" .. desc .. "<reset>")
        end
    end

    cecho("\n<cyan>====================================<reset>\n")
end

-- =============================================================================
-- FULL NAME MATCHING (for trigger-based identification)
-- =============================================================================

--[[
    Match a full in-game card name to our db key.
    In-game: "Maran La'Saen, Seraph of Creation" -> "Maran"
    Strategy: try the first word of the full name as the key.
]]--
function ldm.matchFullName(fullName)
    if not fullName then return nil end

    -- Try exact match first
    if ldm.db[fullName] then return fullName end

    -- Try first word (most card keys are the first word of the full name)
    local firstWord = fullName:match("^(%S+)")
    if firstWord then
        -- Try exact case
        if ldm.db[firstWord] then return firstWord end
        -- Try case-insensitive
        for key, _ in pairs(ldm.db) do
            if key:lower() == firstWord:lower() then
                return key
            end
        end
    end

    return nil
end

-- =============================================================================
-- INPUT HOOK: Intercept "ldeck list <filter>" to pass filter to display
-- =============================================================================

if ldm._ldeckListHandler then
    killAnonymousEventHandler(ldm._ldeckListHandler)
end
ldm._ldeckListHandler = registerAnonymousEventHandler("sysDataSendRequest", function(_, cmd)
    if cmd and cmd:lower():find("^ldeck list ") then
        ldm.state.displayFilter = cmd:sub(12):trim()
    elseif cmd and cmd:lower() == "ldeck list" then
        ldm.state.displayFilter = "all"
    end
end)
