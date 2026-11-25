--- test_slc_auto_shield.lua -- v4.7.522: the self limb counter's auto-shield skips a shield that is
--- already up. The shield is a DEFENCE (`ataxia.defences.shield`); the guard read
--- `ataxia.afflictions.shield`, which nothing sets, so it never fired.
---
--- Runs the real script (self_limb_tracking/004_Defensive_Reactions.lua) through its real event
--- handler. The handler is caught at load time, because the mock's killAnonymousEventHandler is a
--- no-op and a raiseEvent would also run copies left by other loads.

require("mock_mudlet")

local SCRIPT = "src_new/scripts/levi_ataxia/levi/ataxia/self_limb_tracking/004_Defensive_Reactions.lua"

local GLOBALS = { "send", "tempTimer", "registerAnonymousEventHandler", "selfLimbDamage" }
local ATAXIA = { "afflictions", "defences" }

local sent, handler, saved

local function begin()
  saved = { g = {}, a = {} }
  ataxia = ataxia or {}
  for _, k in ipairs(GLOBALS) do saved.g[k] = _G[k] end
  for _, k in ipairs(ATAXIA) do saved.a[k] = ataxia[k] end
  sent, handler = {}, nil
  -- Only the auto-shield is on; the other reactions stay out of the way.
  selfLimbDamage = {
    config = { enabled = true, autoShield = true, shieldCooldown = 4,
      sscPriority = false, partyCallout = false, classDefenses = false, bothArmsFlee = false },
    reactions = { sscPrioSent = {} },
  }
  registerAnonymousEventHandler = function(event, fn)
    if event == "self limb threshold" then handler = fn end
    return 1
  end
  local okLoad, errLoad = pcall(dofile, SCRIPT)
  if not okLoad then error(tostring(errLoad)) end
  send = function(c) sent[#sent + 1] = c end
  tempTimer = function() return 1 end
  ataxia.afflictions, ataxia.defences = {}, {}
end

local function finish()
  for _, k in ipairs(GLOBALS) do _G[k] = saved.g[k] end
  for _, k in ipairs(ATAXIA) do ataxia[k] = saved.a[k] end
end

local function run(fn)
  begin()
  local ok, err = pcall(fn)
  finish()
  if not ok then error(err, 0) end
end

local function shields()
  local n = 0
  for _, c in ipairs(sent) do if c == "touch shield" then n = n + 1 end end
  return n
end

describe("v4.7.522 -- the SLC auto-shield reads the shield DEFENCE", function()
  it("loads and registers its threshold handler", function()
    run(function() expect(type(handler)).toBe("function") end)
  end)

  it("no shield up: a critical limb touches the shield", function()
    run(function()
      handler("self limb threshold", "left leg", "critical", 1)
      expect(shields()).toBe(1)
    end)
  end)

  it("shield already up (ataxia.defences.shield): no touch is sent", function()
    run(function()
      ataxia.defences.shield = true
      handler("self limb threshold", "left leg", "critical", 1)
      expect(shields()).toBe(0)
    end)
  end)

  it("aeon still blocks the touch", function()
    run(function()
      ataxia.afflictions.aeon = true
      handler("self limb threshold", "left leg", "critical", 1)
      expect(shields()).toBe(0)
    end)
  end)

  it("a non-critical threshold sends nothing", function()
    run(function()
      handler("self limb threshold", "left leg", "warning", 2)
      expect(shields()).toBe(0)
    end)
  end)
end)
