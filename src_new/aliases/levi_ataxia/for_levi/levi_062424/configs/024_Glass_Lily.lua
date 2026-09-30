--[[mudlet
type: alias
name: Glass Lily
hierarchy:
- Levi_Ataxia
- Ataxia
- Basher
- Configs
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^lily(?: (on|off|now|count(?: \d+)?))?$
command: ''
packageName: ''
]]--

-- `lily`            -- status: on/off, how many we drop, when the next drop is due.
-- `lily on|off`     -- the hourly DROP LILY (default on).
-- `lily now`        -- drop them now, whatever the clock says.
-- `lily count <n>`  -- how many lilies to drop each time (default 3).
local arg = matches[2]
if arg == "on" or arg == "off" then
  ataxia.settings.lilyAuto = (arg == "on")
  ataxia_saveSettings(false)
  ataxiaEcho("Hourly glass lily drop is now "
    .. (ataxia.settings.lilyAuto and "<green>on" or "<red>off") .. "<reset>.")
elseif arg == "now" then
  ataxia_lilyDrop("manual", true)
elseif arg and arg:find("^count") then
  local n = tonumber(arg:match("(%d+)$"))
  if not n or n < 1 then
    ataxiaEcho("Usage: lily count <n>  (currently " .. ataxia_lilyCount() .. ").")
    return
  end
  ataxia.settings.lilyCount = math.floor(n)
  ataxia_saveSettings(false)
  ataxiaEcho("Glass lily: dropping <cyan>" .. ataxia_lilyCount() .. "<reset> each hour.")
else
  local wait = ataxia_lilyWait()
  ataxiaEcho("Glass lily: " .. (ataxia_lilyEnabled() and "<green>on" or "<red>off") .. "<reset>, "
    .. ataxia_lilyCount() .. " per drop, "
    .. (wait > 0 and ("next in <cyan>" .. math.ceil(wait / 60) .. " min<reset>") or "<cyan>due now<reset>")
    .. (ataxiaTemp.lilyDroppedAt and "" or " (no drop seen this session)") .. ".")
end
