--[[mudlet
type: script
name: Snipe System
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- Leviticus
- Snipe
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

-- =============================================================================
-- SNIPE SYSTEM (Class-Agnostic)
-- =============================================================================
--
-- ALIAS:
--   snt              : Snipe current target, auto-scan exits
--   snt <dir>        : Snipe current target in specific direction
--   snt <Name>       : Set target, snipe, auto-scan exits
--   snt <Name> <dir> : Set target, snipe in specific direction
--
-- AUTO-SCAN FLOW:
--   1. Build direction queue (cached dir first, then room exits)
--   2. Send snipe for first direction
--   3. On failure ("You don't see your target") → try next direction
--   4. On success → cache direction, party callout, stop
-- =============================================================================

-- Namespace
snipe = snipe or {}
snipe.state = snipe.state or {}

-- Direction cache: target name (lowercase) → short direction string
snipe.directionCache = snipe.directionCache or {}

-- Scanning state
snipe.state.scanning = false
snipe.state.scanQueue = {}
snipe.state.scanIndex = 0
snipe.state.currentTarget = nil
snipe.state.currentDirection = nil

-- =============================================================================
-- UTILITY
-- =============================================================================

function snipe.echo(msg)
    cecho("\n<ansi_light_cyan>[<white>Snipe<ansi_light_cyan>]: <white>" .. msg)
end

-- =============================================================================
-- SCAN QUEUE
-- =============================================================================

--- Build an ordered list of directions to scan.
-- Cached direction goes first (if still a valid exit), then remaining exits.
function snipe.buildScanQueue(targetName)
    local queue = {}
    local cached = snipe.directionCache[targetName]
    local exits = gmcp.Room.Info and gmcp.Room.Info.exits or {}

    -- Cached direction first if it is still a valid exit
    if cached and exits[cached] then
        table.insert(queue, cached)
    end

    -- Remaining exits in stable compass order
    local dirOrder = {"n", "ne", "e", "se", "s", "sw", "w", "nw", "u", "d", "in", "out"}
    for _, d in ipairs(dirOrder) do
        if exits[d] and d ~= cached then
            table.insert(queue, d)
        end
    end

    return queue
end

-- =============================================================================
-- SEND COMMANDS
-- =============================================================================

function snipe.sendSnipe(targetName, dirShort)
    local dirLong = dir_toLong(dirShort)
    snipe.state.currentDirection = dirShort
    local sp = ataxia.settings.separator or ";"
    send("remove bow" .. sp .. "wield bow" .. sp .. "snipe " .. targetName .. " " .. dirLong)
end

-- =============================================================================
-- CORE LOGIC
-- =============================================================================

--- Main entry point. Called by the snt alias.
function snipe.execute(targetName, dirShort)
    -- Abort any active scan
    snipe.abort()

    if not targetName or targetName == "" then
        snipe.echo("<red>No target set. Use: snt <name> [direction]")
        return
    end

    snipe.state.currentTarget = targetName

    if dirShort then
        -- Single direction mode
        snipe.state.scanning = false
        snipe.sendSnipe(targetName, dirShort)
        snipe.echo("Sniping <yellow>" .. targetName .. "<white> " .. dir_toLong(dirShort) .. ".")
    else
        -- Auto-scan mode
        local queue = snipe.buildScanQueue(targetName:lower())
        if #queue == 0 then
            snipe.echo("<red>No exits found to scan.")
            return
        end

        snipe.state.scanning = true
        snipe.state.scanQueue = queue
        snipe.state.scanIndex = 1

        local dir = queue[1]
        snipe.echo("Scanning for <yellow>" .. targetName ..
                   "<white> (" .. #queue .. " exits). Trying <green>" ..
                   dir_toLong(dir) .. "<white>...")
        snipe.sendSnipe(targetName, dir)
    end
end

--- Advance to the next direction in the scan queue.
function snipe.advanceScan()
    if not snipe.state.scanning then
        return
    end

    snipe.state.scanIndex = snipe.state.scanIndex + 1
    local queue = snipe.state.scanQueue
    local idx = snipe.state.scanIndex

    if idx > #queue then
        snipe.echo("<red>Target <yellow>" ..
                   (snipe.state.currentTarget or "???") ..
                   "<red> not found in any direction.")
        snipe.abort()
        return
    end

    local dir = queue[idx]
    snipe.echo("Trying <green>" .. dir_toLong(dir) ..
               "<white> (" .. idx .. "/" .. #queue .. ")...")
    snipe.sendSnipe(snipe.state.currentTarget, dir)
end

--- Handle a successful snipe. Called by the success trigger.
function snipe.onSuccess(hitTarget)
    local dir = snipe.state.currentDirection
    local tgt = hitTarget or snipe.state.currentTarget

    -- Cache the successful direction
    if dir then
        snipe.directionCache[tgt:lower()] = dir
    end

    local dirStr = dir and dir_toLong(dir) or "unknown direction"
    snipe.echo("<green>Hit! <yellow>" .. tgt ..
               "<green> sniped " .. dirStr .. "!")

    -- Party callout
    if partyrelay and not ataxia.afflictions.aeon then
        send("pt Shot " .. tgt .. " " .. dirStr)
    end

    snipe.abort()
end

--- Handle a snipe failure (wrong direction). Called by the failure trigger.
function snipe.onFailure()
    if snipe.state.scanning then
        snipe.advanceScan()
    else
        snipe.echo("<red>Target not in that direction.")
    end
end

--- Abort any active scan.
function snipe.abort()
    snipe.state.scanning = false
    snipe.state.scanQueue = {}
    snipe.state.scanIndex = 0
    snipe.state.currentDirection = nil
end
