--[[mudlet
type: script
name: Alchemist Extispicy
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Ataxia
- System-related
- Class Things
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

-- EXTISPICY (Alchemy, ABADMIN 8): DISSECT <rat corpse>, 4.00s of balance, 100 mana. Dissecting
-- a city rat raises our critical strike chance. GMCP lists it as the defence `extispicy`.
--
-- The basher's kill line is "You have slain <x>, retrieving the corpse." -- the corpse is already
-- in our pack, so there is no GET. After a rat kill we probe `ii corpse` (the row shape
-- `733_Corpse_Found` and `ataxia_carnivoreEat` parse) and queue DISSECT on the first rat corpse id.
--
-- DISSECT NEEDS BALANCE, SO IT IS QUEUED -- and every basher attack sends `queue addclearfull`,
-- which would wipe it, and a cleared room moves on at once. So `ataxiaTemp.dissectHold` gates
-- `ataxiaBasher_tryAttack` and `ataxiaBasher_attack` (like bardComposeHold) from the probe until
-- the queued dissect runs (`queue_Scan` sees it) or a backstop timer ends it.

ataxiaTemp = ataxiaTemp or {}

local PROBE_TIMEOUT = 3
local HOLD_BACKSTOP = 8   -- balance back from the killing blow, plus latency
local MANA_COST = 100

-- "a young rat", "an old rat", "a black rat", "rats" -- not "ratman" or "pirate".
function ataxia_extispicyIsRat(name)
  name = type(name) == "string" and name:lower() or ""
  return name:find("%f[%a]rats?%f[%A]") ~= nil or name:find("%f[%a]rats?$") ~= nil
end

function ataxia_extispicyEnabled()
  return not (ataxia.settings and ataxia.settings.extispicy == false)
end

function ataxia_extispicyRelease(why)
  if ataxiaTemp.dissectTrigger then pcall(killTrigger, ataxiaTemp.dissectTrigger) end
  if ataxiaTemp.dissectTimer then pcall(killTimer, ataxiaTemp.dissectTimer) end
  ataxiaTemp.dissectTrigger, ataxiaTemp.dissectTimer = nil, nil
  ataxiaTemp.dissectHold = nil
end

-- Called from the queue-run line (misc_scripts/001_Queue_Scanning).
function ataxia_extispicyRan()
  if not ataxiaTemp.dissectHold then return false end
  ataxia_extispicyRelease("ran")
  return true
end

-- Called from the Slain trigger (340) with the slain denizen's name.
function ataxia_extispicyOnKill(name)
  if not ataxia_isClass("Alchemist") then return false end
  if not ataxia_extispicyEnabled() then return false end
  if not ataxia_extispicyIsRat(name) then return false end
  if ataxia.defences and ataxia.defences.extispicy then return false end
  local mp = gmcp and gmcp.Char and gmcp.Char.Vitals and tonumber(gmcp.Char.Vitals.mp)
  if mp and mp < MANA_COST then return false end
  if ataxiaTemp.dissectHold then return false end

  ataxiaTemp.dissectHold = true
  ataxiaTemp.dissectTrigger = tempRegexTrigger([[^\s+(.+)the corpse of (.+)$]], function()
    local id, what = string.trim(matches[2]), matches[3]
    if not ataxia_extispicyIsRat(what) then return end -- stay armed for the next row
    if ataxiaTemp.dissectTrigger then pcall(killTrigger, ataxiaTemp.dissectTrigger) end
    ataxiaTemp.dissectTrigger = nil
    send("queue addclear bal dissect " .. id, false)
    if ataxiaEcho then ataxiaEcho("Extispicy: dissecting <green>the corpse of " .. tostring(what) .. "<reset>.") end
    if ataxiaTemp.dissectTimer then pcall(killTimer, ataxiaTemp.dissectTimer) end
    ataxiaTemp.dissectTimer = tempTimer(HOLD_BACKSTOP, function() ataxia_extispicyRelease("backstop") end)
  end)
  -- No rat corpse listed: release the basher. Replaced by the backstop once a dissect is queued.
  ataxiaTemp.dissectTimer = tempTimer(PROBE_TIMEOUT, function() ataxia_extispicyRelease("probe") end)
  send("ii corpse", false)
  return true
end

function ataxia_setExtispicy(arg)
  arg = arg and arg:lower() or ""
  if arg == "off" then
    ataxia.settings.extispicy = false
    ataxiaEcho("Extispicy OFF -- rat kills will not be dissected.")
  elseif arg == "on" then
    ataxia.settings.extispicy = true
    ataxiaEcho("Extispicy ON -- every rat kill is dissected while the defence is down.")
  else
    ataxiaEcho("Extispicy: " .. (ataxia_extispicyEnabled() and "ON" or "OFF")
      .. " -- defence " .. ((ataxia.defences and ataxia.defences.extispicy) and "UP" or "down") .. ".")
  end
end
