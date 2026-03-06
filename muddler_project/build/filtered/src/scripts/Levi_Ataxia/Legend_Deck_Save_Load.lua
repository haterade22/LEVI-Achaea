--[[
    ============================================================================
    LEGEND DECK MANAGER - SAVE / LOAD
    ============================================================================
    Persists ldm.deck (charge counts) and ldm.config to disk.
    Uses Mudlet's table.save/table.load matching the ataxia pattern.
    ============================================================================
]]--

ldm = ldm or {}

-- =============================================================================
-- SAVE
-- =============================================================================

function ldm.save()
    if not ldm.deck or not next(ldm.deck) then return end

    local separator = string.char(getMudletHomeDir():byte()) == "/" and "/" or "\\"
    local deck_loc = getMudletHomeDir() .. separator .. "legenddeck"
    local config_loc = getMudletHomeDir() .. separator .. "legenddeck_config"

    -- Save deck state (charges, max, timer)
    table.save(deck_loc, ldm.deck)

    -- Save config + favorites
    local configData = {
        favorites = ldm.favorites or {},
        config = ldm.config or {},
        enabled = ldm.enabled,
    }
    table.save(config_loc, configData)
end

-- =============================================================================
-- LOAD
-- =============================================================================

function ldm.load()
    local separator = string.char(getMudletHomeDir():byte()) == "/" and "/" or "\\"
    local deck_loc = getMudletHomeDir() .. separator .. "legenddeck"
    local config_loc = getMudletHomeDir() .. separator .. "legenddeck_config"

    -- Load deck state
    if io.exists(deck_loc) then
        local loaded = {}
        table.load(deck_loc, loaded)
        -- Merge: loaded data takes priority, but only for known cards
        for key, data in pairs(loaded) do
            if type(data) == "table" and data.charges then
                ldm.deck[key] = {
                    charges      = tonumber(data.charges) or 0,
                    max_charges  = tonumber(data.max_charges) or 0,
                    charge_timer = tonumber(data.charge_timer) or 0,
                }
            end
        end
    end

    -- Load config
    if io.exists(config_loc) then
        local configData = {}
        table.load(config_loc, configData)
        if configData.favorites then ldm.favorites = configData.favorites end
        if configData.config then
            for k, v in pairs(configData.config) do
                ldm.config[k] = v
            end
        end
        if configData.enabled ~= nil then ldm.enabled = configData.enabled end
    end

    -- Ensure all db cards have deck entries (handles new cards added to db)
    ldm.initDeck()
end

-- =============================================================================
-- AUTO-INIT: Initialize deck from db defaults on first load
-- =============================================================================

-- Initialize deck from db if db is already loaded (002 runs before 004)
if ldm.db and next(ldm.db) then
    ldm.initDeck()
end
