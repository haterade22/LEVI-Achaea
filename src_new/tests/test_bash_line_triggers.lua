--- test_bash_line_triggers.lua -- the bash line triggers follow the basher (v4.7.425)
--
-- User: "Your vicious attack cleaves to a nearby enemy. Why isnt this highlighted?" The trigger
-- (denizen_attacks_misc_lines/026) is fine; its folder ships OFF and only the "basher enabled"
-- event turned it on. A reload or reimport resets the folder while the SAVED ataxiaBasher.enabled
-- comes back true with no event, so the whole folder stayed dead while we bashed.

require("mock_mudlet")

local _saved = {
  isActive = isActive, enableTrigger = enableTrigger, getEpoch = getEpoch,
  ataxiaBasher = ataxiaBasher, ataxiaTemp = ataxiaTemp,
}

local folderOn, enabled, NOW = false, {}, 1000
isActive = function(name, kind)
  if name == "Denizen Attacks / Misc Lines" and kind == "trigger" then return folderOn and 1 or 0 end
  return 0
end
enableTrigger = function(name)
  enabled[#enabled + 1] = name
  if name == "Denizen Attacks / Misc Lines" then folderOn = true end
end
getEpoch = function() return NOW end
ataxiaBasher = { enabled = true }
ataxiaTemp = {}

dofile("src_new/scripts/levi_ataxia/levi/ataxia/genrunning/003_Engaged_Disengage.lua")

local function reset(on)
  folderOn, enabled, NOW = on, {}, NOW + 100
  ataxiaBasher = { enabled = true }
  ataxiaTemp = {}
end

describe("bash line triggers follow the basher", function()
  it("turns the folder on when the basher is on and the folder is off (after a reimport)", function()
    reset(false)
    expect(ataxiaBasher_syncLineTriggers()).toBeTrue()
    expect(folderOn).toBeTrue()
    expect(enabled[1]).toBe("Denizen Attacks / Misc Lines")
    expect(enabled[2]).toBe("Gold Dropped")
  end)

  it("does nothing when the folder is already on", function()
    reset(true)
    expect(ataxiaBasher_syncLineTriggers()).toBeFalse()
    expect(#enabled).toBe(0)
  end)

  it("does nothing while the basher is off", function()
    reset(false); ataxiaBasher.enabled = false
    expect(ataxiaBasher_syncLineTriggers()).toBeFalse()
    expect(#enabled).toBe(0)
  end)

  it("asks Mudlet at most once per 2 s", function()
    reset(true)
    ataxiaBasher_syncLineTriggers()
    folderOn = false -- the folder is reset by a reimport just after a check
    NOW = NOW + 1
    expect(ataxiaBasher_syncLineTriggers()).toBeFalse()
    NOW = NOW + 1
    expect(ataxiaBasher_syncLineTriggers()).toBeTrue()
  end)

  it("the vitals dispatch calls it", function()
    local f = assert(io.open("src_new/scripts/levi_ataxia/levi/ataxia/genrunning/004_Autobashing_Functions.lua"))
    local src = f:read("*a"); f:close()
    local body = src:match("function ataxiaBasher_gmcpDispatch%(%)(.-)\nend")
    expect(body ~= nil).toBeTrue()
    expect(body:find("ataxiaBasher_syncLineTriggers()", 1, true) ~= nil).toBeTrue()
  end)
end)

isActive, enableTrigger, getEpoch = _saved.isActive, _saved.enableTrigger, _saved.getEpoch
ataxiaBasher, ataxiaTemp = _saved.ataxiaBasher, _saved.ataxiaTemp
