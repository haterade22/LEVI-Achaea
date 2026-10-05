--[[mudlet
type: script
name: Mapper GMCP Guard
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
    KEEP THE MAPPER'S `gmcpmapupdates` OFF IN THE TOWER  (v4.7.377)
    ============================================================================

    User: "if in mnemosyne, keep that off".

    The IRE mudlet-mapper (a separate package) gained `mconfig gmcpmapupdates` in 2026-10. With it
    on, `mmp.syncSafeRoomInfo` runs on every gmcp.Room.Info and writes the room's name,
    environment, indoor/outdoor flag and area onto the MAPPED room of that number, unchecked. In
    the tower, Creville's Legacy (incurable dementia) hands gmcp a REAL room number with
    hallucinated details (CLAUDE.md, v4.7.249), so those writes would rewrite real rooms in the
    local map -- and with `crowdmapservicesend on`, upstream reports every map write to the shared
    Crowdmap service.

    So: switched OFF on "mnemosyne entered", switched back ON on "mnemosyne left" -- and only if
    WE switched it off. A user who never turned it on is never touched.

    THE RESTORE IS OWED ACROSS A RELOAD, SO ITS MARKER IS DELIBERATELY SAVED.
    `ataxiaBasher.mapperGmcpOwed` rides the serialized basher table on purpose (the opposite of the
    v4.7.192 transient-flag rule, the Berserker's Edge shape): the mapper writes its options to disk
    only on sysExitEvent, and we save on disconnect, so the two files agree in both endings --
    a clean exit inside the tower stores "off" AND "owed", a crash stores neither and the mapper
    comes back with the user's own value. Lose the marker and the user's setting stays off for good,
    silently.

    THE PER-PROMPT CHECK IS THE BACKSTOP, NOT DECORATION.
    The events cover the normal path, and the wade-start line raises "mnemosyne entered" before the
    first tower room. Three paths raise no event, and the prompt check catches each of them:
      - a reload mid-climb: `inMnemosyne` comes back true from disk, and ataxiaBasher_mnemHere's
        transition guard then raises nothing;
      - the user turning it back on with mconfig in the middle of a climb;
      - a restore owed from an earlier session: the mapper loads its options once, at its own load,
        before we connect, so the first prompt is the first moment both values are real.
    `ataxia_loadSettings` deliberately does NOT restore -- on a fresh start it can run before the
    mapper's own option load, which would overwrite the restore and then find the marker cleared.

    Upstream calls `setOption(name, value, true)` itself in loadOptions; the third argument skips
    the option's onChange echo, so we print our own one line instead.
]]--

ataxiaTemp = ataxiaTemp or {}
ataxiaBasher = ataxiaBasher or {}

-- The option's value, or nil when there is no mapper or no such option (an older mapper).
-- Through the proxy's __index, the way upstream itself reads it.
local function mapperValue()
  if type(mmp) ~= "table" or type(mmp.settings) ~= "table" then return nil end
  local ok, v = pcall(function() return mmp.settings.gmcpmapupdates end)
  if ok then return v end
  return nil
end

-- Silent set; the caller reads the value back, since setOption reports a refusal by printing.
local function mapperSet(value)
  if type(mmp) ~= "table" or type(mmp.settings) ~= "table" then return end
  if type(mmp.settings.setOption) ~= "function" then return end
  pcall(mmp.settings.setOption, mmp.settings, "gmcpmapupdates", value, true)
end

local function say(msg)
  if ataxiaEcho then ataxiaEcho(msg) end
end

-- In the tower and the option is on: turn it off and owe the user a restore.
function ataxia_mnemMapperHold()
  if mapperValue() ~= true then return false end
  mapperSet(false)
  if mapperValue() ~= false then return false end -- the mapper refused; nothing is owed
  ataxiaBasher.mapperGmcpOwed = true
  say("Mnemosyne: mapper <white>gmcpmapupdates<reset> OFF for the tower (dementia fakes room data). " ..
    "It goes back ON when you leave.")
  return true
end

-- Out of the tower with a restore owed: put the user's setting back.
function ataxia_mnemMapperRelease()
  if not ataxiaBasher.mapperGmcpOwed then return false end
  if ataxiaBasher.inMnemosyne == true then return false end
  local v = mapperValue()
  if v == nil then return false end -- no mapper (yet): keep owing, the next prompt retries
  ataxiaBasher.mapperGmcpOwed = nil
  if v == false then
    mapperSet(true)
    if mapperValue() == true then
      say("Left Mnemosyne: mapper <white>gmcpmapupdates<reset> back ON.")
    end
  end
  return true
end

-- Every prompt. Outside the tower with nothing owed this is one table read.
function ataxia_mnemMapperTick()
  if ataxiaBasher.inMnemosyne == true then
    return ataxia_mnemMapperHold()
  elseif ataxiaBasher.mapperGmcpOwed then
    return ataxia_mnemMapperRelease()
  end
  return false
end

-- Kill-before-register: an XML reimport re-runs this file, and a stacked handler would act twice.
-- Ids live on ataxiaTemp -- a handler id must never be serialized (v4.7.336).
local function _reg(key, event, fn)
  if ataxiaTemp[key] then pcall(killAnonymousEventHandler, ataxiaTemp[key]) end
  ataxiaTemp[key] = registerAnonymousEventHandler(event, fn)
end
_reg("mapperGuardEnterH", "mnemosyne entered", function() ataxia_mnemMapperHold() end)
_reg("mapperGuardLeftH", "mnemosyne left", function() ataxia_mnemMapperRelease() end)
_reg("mapperGuardTickH", "gmcp.Char.Vitals", function() ataxia_mnemMapperTick() end)
