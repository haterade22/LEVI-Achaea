--[[mudlet
type: script
name: Vial Summary
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- Inventory
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

-- Vial Summary System for Achaea
-- Parses elixlist/venomlist output and displays a compact grouped summary
-- Usage: elist (elixir summary) or vlist (venom summary)

--------------------------------------------------------------------------------
-- NAMESPACE AND STATE
--------------------------------------------------------------------------------

vialSummary = vialSummary or {}

vialSummary.state = {
  phase = "IDLE",       -- IDLE, CAPTURING
  mode = nil,           -- "elixir" or "venom"
  triggers = {},        -- temp trigger IDs for cleanup
  timers = {},          -- temp timer IDs for cleanup
  data = {},            -- { ["short name"] = { count = N, totalSips = N } }
  hasData = false,      -- true after first data line captured
  separatorCount = 0,   -- track separator lines (header has one, end has one)
}

--------------------------------------------------------------------------------
-- UTILITY
--------------------------------------------------------------------------------

function vialSummary.echo(text)
  cecho("\n<dark_orchid>[<light_slate_blue>Vials<dark_orchid>]<lavender>: <plum>" .. text)
end

function vialSummary.shortName(raw)
  -- Trim whitespace
  local trimmed = raw:match("^%s*(.-)%s*$")

  -- Elixir patterns
  local name = trimmed:match("^an elixir of (.+)$")
    or trimmed:match("^a salve of (.+)$")
    or trimmed:match("^an epidermal salve$") and "epidermal"
    or trimmed:match("^a caloric salve$") and "caloric"
    or trimmed:match("^a tincture of (.+)$")

  -- Venom pattern
  if not name then
    name = trimmed:match("^the venom (.+)$")
  end

  -- Special cases
  if not name then
    if trimmed == "empty" then
      name = "empty"
    elseif trimmed == "blood" then
      name = "blood"
    else
      -- Fallback: use the raw trimmed name
      name = trimmed
    end
  end

  return name
end

function vialSummary.formatNumber(n)
  local s = tostring(n)
  local pos = #s % 3
  if pos == 0 then pos = 3 end
  local result = s:sub(1, pos)
  for i = pos + 1, #s, 3 do
    result = result .. "," .. s:sub(i, i + 2)
  end
  return result
end

--------------------------------------------------------------------------------
-- INIT AND CLEANUP
--------------------------------------------------------------------------------

function vialSummary.init()
  vialSummary.state.phase = "IDLE"
  vialSummary.state.mode = nil
  vialSummary.state.triggers = {}
  vialSummary.state.timers = {}
  vialSummary.state.data = {}
  vialSummary.state.hasData = false
  vialSummary.state.separatorCount = 0
end

function vialSummary.cleanup()
  for _, trigId in ipairs(vialSummary.state.triggers) do
    killTrigger(trigId)
  end
  for _, timerId in ipairs(vialSummary.state.timers) do
    killTimer(timerId)
  end
  vialSummary.state.triggers = {}
  vialSummary.state.timers = {}
end

--------------------------------------------------------------------------------
-- DISPLAY
--------------------------------------------------------------------------------

function vialSummary.display()
  local mode = vialSummary.state.mode
  local title = (mode == "elixir") and "Elixir Summary" or "Venom Summary"
  local unit = (mode == "elixir") and "sips" or "doses"

  -- Sort entries by total quantity descending
  local sorted = {}
  for name, info in pairs(vialSummary.state.data) do
    table.insert(sorted, { name = name, count = info.count, total = info.totalSips })
  end
  table.sort(sorted, function(a, b) return a.total > b.total end)

  -- Find max name length for alignment
  local maxLen = 0
  for _, e in ipairs(sorted) do
    if #e.name > maxLen then maxLen = #e.name end
  end
  maxLen = math.max(maxLen, 5) -- minimum width

  -- Header
  cecho("\n<dark_orchid>--- <light_slate_blue>" .. title .. "<dark_orchid> ---")

  -- Rows
  local totalVials = 0
  local totalQuantity = 0
  for _, e in ipairs(sorted) do
    local padded = e.name .. string.rep(" ", maxLen - #e.name)
    local quantityStr = ""
    if e.total > 0 then
      quantityStr = "  (" .. vialSummary.formatNumber(e.total) .. " " .. unit .. ")"
    end
    cecho("\n<plum>" .. padded .. ": <light_slate_blue>" ..
      string.format("%3d", e.count) .. " vials" ..
      "<lavender>" .. quantityStr)
    totalVials = totalVials + e.count
    totalQuantity = totalQuantity + e.total
  end

  -- Footer
  cecho("\n<dark_orchid>" .. string.rep("-", maxLen + 30))
  cecho("\n<plum>TOTAL" .. string.rep(" ", maxLen - 5) .. ": <light_slate_blue>" ..
    string.format("%3d", totalVials) .. " vials" ..
    "<lavender>  (" .. vialSummary.formatNumber(totalQuantity) .. " " .. unit .. ")")
  cecho("\n")
end

--------------------------------------------------------------------------------
-- FINISH
--------------------------------------------------------------------------------

function vialSummary.finish()
  if vialSummary.state.phase ~= "CAPTURING" then return end
  vialSummary.cleanup()
  vialSummary.display()
  vialSummary.state.phase = "IDLE"
end

--------------------------------------------------------------------------------
-- TRIGGER SETUP
--------------------------------------------------------------------------------

function vialSummary.setupTriggers()
  -- Trigger 1: Data line capture
  -- Matches lines like:
  --   An obfuscated crystal v105928 an elixir of mana              240      ---
  --   Stone vial158007        the venom prefarar             14       ---
  --   A stygian vial239896          empty                          0        45
  local t1 = tempRegexTrigger(
    [[^.+?\d+\s{2,}(.+?)\s{2,}(\d+)\s+\S+\s*$]],
    function()
      if vialSummary.state.phase ~= "CAPTURING" then return end

      local fluidRaw = matches[2]
      local sips = tonumber(matches[3]) or 0
      local shortName = vialSummary.shortName(fluidRaw)

      if not vialSummary.state.data[shortName] then
        vialSummary.state.data[shortName] = { count = 0, totalSips = 0 }
      end
      vialSummary.state.data[shortName].count = vialSummary.state.data[shortName].count + 1
      vialSummary.state.data[shortName].totalSips = vialSummary.state.data[shortName].totalSips + sips
      vialSummary.state.hasData = true
    end
  )
  table.insert(vialSummary.state.triggers, t1)

  -- Trigger 2: MORE prompt - auto-continue
  local t2 = tempTrigger(
    "[Type MORE if you wish to continue reading",
    function()
      if vialSummary.state.phase == "CAPTURING" then
        send("MORE", false)
      end
    end
  )
  table.insert(vialSummary.state.triggers, t2)

  -- Trigger 3: End-of-list separator line
  -- The output has a separator after the header and one at the end.
  -- We fire finish() only when we see a separator AFTER data lines have been captured.
  local t3 = tempRegexTrigger(
    [[^-{20,}\s*$]],
    function()
      if vialSummary.state.phase ~= "CAPTURING" then return end
      vialSummary.state.separatorCount = vialSummary.state.separatorCount + 1

      -- The first separator is before the data, the second is after all data
      if vialSummary.state.hasData and vialSummary.state.separatorCount >= 2 then
        -- Small delay to ensure all buffered lines are processed
        local timer = tempTimer(0.3, function()
          vialSummary.finish()
        end)
        table.insert(vialSummary.state.timers, timer)
      end
    end
  )
  table.insert(vialSummary.state.triggers, t3)
end

--------------------------------------------------------------------------------
-- START COMMAND
--------------------------------------------------------------------------------

function vialSummary.start(mode)
  if vialSummary.state.phase ~= "IDLE" then
    vialSummary.echo("Already capturing. Please wait for the current scan to finish.")
    return
  end

  vialSummary.init()
  vialSummary.state.phase = "CAPTURING"
  vialSummary.state.mode = mode
  vialSummary.setupTriggers()

  -- Timeout safety net (30 seconds)
  local timeout = tempTimer(30, function()
    if vialSummary.state.phase == "CAPTURING" then
      vialSummary.echo("Scan timed out. Showing partial results.")
      vialSummary.finish()
    end
  end)
  table.insert(vialSummary.state.timers, timeout)

  -- Send the game command
  local cmd = (mode == "elixir") and "elixlist" or "venomlist"
  send(cmd, false)

  local label = (mode == "elixir") and "elixir" or "venom"
  vialSummary.echo("Scanning " .. label .. " inventory...")
end
