--[[mudlet
type: script
name: Mnemosyne Commands
hierarchy:
- Levi_Ataxia
- Ataxia
- Mnemosyne
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

--[[
    ============================================================================
    MNEMOSYNE RUN TRACKER - COMMAND DISPATCH
    ============================================================================
    Backs the `mnem` alias. Provides config commands plus manual overrides for
    every endpoint (which double as test tools and a fallback when game wording
    changes).

    Depends on 001_HTTP_Client.lua and 002_Reporter_API.lua.
    ============================================================================
]]--

ataxia.mnemosyne = ataxia.mnemosyne or {}
local M = ataxia.mnemosyne

function M.status()
  local c = M._cfg()
  M.echo("<gold>Mnemosyne Run Tracker")
  cecho("\n  <NavajoWhite>URL:        <grey>" .. M._baseUrl())
  cecho("\n  <NavajoWhite>Token:      " .. (M._hasToken() and "<green>set" or "<indian_red>not set"))
  cecho("\n  <NavajoWhite>Auto:       " .. (c.enabled and "<green>ON" or "<grey>off"))
  cecho("\n  <NavajoWhite>Contemplate:" .. (c.contemplate and " <green>ON" or " <grey>off"))
  local r = M.run or {}
  cecho("\n  <NavajoWhite>Run:        "
    .. (r.active and ("<green>active <grey>(ripple " .. tostring(r.ripple or 0)
      .. (r.publicId and (", id " .. tostring(r.publicId)) or "") .. ")") or "<grey>none"))
end

function M.help()
  M.echo("<gold>mnem commands:")
  local rows = {
    { "mnem status", "Show config + current run state" },
    { "mnem token <token>", "Save your API token" },
    { "mnem on | off", "Toggle automatic reporting" },
    { "mnem contemplate", "Toggle boon enrichment via BOON CONTEMPLATE" },
    { "mnem test", "Ping /health to check connectivity" },
    { "mnem debug", "Toggle verbose debug echoes" },
    { "mnem map [on|off|status]", "Toggle / diagnose the per-ripple mini-map" },
    { "mnem explore [on|off|status]", "Auto-sweep the 4x4, clear rooms, stop at the boon screen" },
    { "mnem boons", "This run's claimed boons (local history)" },
    { "mnem boonfill", "BOON CONTEMPLATE owned boons with no description yet (run BOONS first)" },
    { "mnem affixes", "This run's active affixes (ongoing effects)" },
    { "mnem library", "All-time affix catalogue" },
    { "mnem quiet [on|off]", "Silence auto boon/affix echoes (still records)" },
    { "mnem start | end", "Manually start / end a run" },
    { "mnem check", "Re-sync with an in-progress run (/run_exists)" },
    { "mnem ripple <n>", "Manually report ripple level" },
    { "mnem boss <name>", "Manually report the boss" },
    { "mnem monsters <text>", "Manually report monsters" },
    { "mnem death [killer]", "Manually report a death" },
  }
  for _, row in ipairs(rows) do
    cecho("\n  <a_darkmagenta>" .. row[1] .. "  <grey>-- <NavajoWhite>" .. row[2])
  end
end

-- Resolve an on|off|<other> argument to a boolean: "on" -> true, "off" -> false,
-- anything else -> a plain toggle of `current`. (Avoids the `x and false or y`
-- trap where an "off" branch silently falls through to the toggle.)
function M._toggleState(arg, current)
  if arg == "on" then return true end
  if arg == "off" then return false end
  return not current
end

function M.command(rest)
  rest = (rest or ""):gsub("^%s+", ""):gsub("%s+$", "")
  local cmd, arg = rest:match("^(%S*)%s*(.-)$")
  cmd = (cmd or ""):lower()
  local c = M._cfg()

  if cmd == "" or cmd == "status" then
    M.status()
  elseif cmd == "token" then
    if arg == "" then
      M.echo("Usage: mnem token <token>")
    else
      c.token = arg
      ataxia_saveSettings(false)
      M.echo("<green>Token saved.<reset> Use <a_darkmagenta>mnem on<reset> to enable auto-reporting.")
    end
  elseif cmd == "on" then
    c.enabled = true
    ataxia_saveSettings(false)
    M.echo("<green>Automatic reporting ON.")
    M.runExists() -- resync run state in case we enabled mid-run
  elseif cmd == "off" then
    c.enabled = false
    ataxia_saveSettings(false)
    M.echo("<indian_red>Automatic reporting OFF.")
  elseif cmd == "contemplate" then
    c.contemplate = not c.contemplate
    ataxia_saveSettings(false)
    M.echo("Auto-contemplate " .. (c.contemplate and "<green>ON" or "<grey>off") .. ".")
  elseif cmd == "debug" then
    c.debug = not c.debug
    M.echo("Debug " .. (c.debug and "<green>ON" or "<grey>off") .. ".")
  elseif cmd == "map" then
    if ataxia.mnemosyne.map then
      if arg == "status" and ataxia.mnemosyne.map.status then
        ataxia.mnemosyne.map.status()
      elseif ataxia.mnemosyne.map.toggle then
        local state -- nil => toggle
        if arg == "on" then state = true elseif arg == "off" then state = false end
        ataxia.mnemosyne.map.toggle(state)
      end
    end
  elseif cmd == "test" or cmd == "health" then
    M.testHealth()
  elseif cmd == "start" then
    M.startRun()
  elseif cmd == "end" then
    M.endRun()
  elseif cmd == "check" then
    M.runExists()
  elseif cmd == "ripple" then
    if arg == "" then M.echo("Usage: mnem ripple <number>") else M.setRipple(tonumber(arg)) end
  elseif cmd == "boss" then
    if arg == "" then M.echo("Usage: mnem boss <name>") else M.reportBoss(arg) end
  elseif cmd == "monsters" then
    if arg == "" then M.echo("Usage: mnem monsters <text>") else M.reportMonsters(arg) end
  elseif cmd == "death" then
    M.reportDeath(arg)
  elseif cmd == "explore" then
    if arg == "off" then M.exploreOff()
    elseif arg == "status" then M.exploreStatus()
    elseif arg == "on" then M.exploreOn()
    else M.exploreToggle() end
  elseif cmd == "boons" then
    M.reportBoons()
  elseif cmd == "boonfill" then
    M.boonFill()
  elseif cmd == "affixes" then
    M.reportAffixes()
  elseif cmd == "library" then
    M.reportLibrary()
  elseif cmd == "quiet" then
    c.quiet = M._toggleState(arg, M._quiet())
    ataxia_saveSettings(false)
    M.echo("Quiet mode " .. (c.quiet and "<green>ON <grey>(auto boon/affix echoes silenced; still recording)" or "<grey>off") .. ".")
  else
    M.help()
  end
end
