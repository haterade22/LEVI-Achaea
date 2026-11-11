--- test_lock_party_call.lua -- we tell the party when we are being locked (2026-11-11)
--
-- ataxia_lockPartyCall (can(x)/003) sends one `pt` line each time our lock gets worse:
-- LOCKING ME (2/3), SOFTLOCKED, HARDLOCKED, TRUELOCKED. Below two pieces the stage resets.

require("mock_mudlet")

ataxia = { settings = {}, vitals = {}, afflictions = {}, defences = {} }
ataxiaTemp = {}
tAffs = {}

function affed(what) return ataxia.afflictions[what] end
function ataxia_paused() return false end

local ok = pcall(dofile, "src_new/scripts/levi_ataxia/levi/ataxia/can(x)/001_Various__can_do__stuff.lua")
if not ok then error("Failed to load can(x)/001") end
ok = pcall(dofile, "src_new/scripts/levi_ataxia/levi/ataxia/can(x)/003_Lock_breakers.lua")
if not ok then error("Failed to load can(x)/003") end

local sent, clock = {}, 1000
local savedSend, savedEpoch, savedRelay, savedBasher = send, getEpoch, partyrelay, ataxiaBasher
send = function(s) sent[#sent + 1] = s end
getEpoch = function() return clock end

local function reset(affs)
  ataxia.afflictions = affs or {}
  ataxia.vitals = { bal = true, eq = true, bleed = 0 }
  ataxia.settings = {}
  ataxiaTemp = { class = "Serpent" }
  gmcp = { Char = { Status = { class = "Serpent" } } }
  partyrelay = true
  ataxiaBasher = { enabled = false }
  sent = {}
end

local function tick() ataxia_lockPartyCall() end

local okRun, err = pcall(function()
  describe("self-lock party call", function()
    it("one piece: nothing", function()
      reset({ asthma = true }); tick()
      expect(#sent).toBe(0)
    end)

    it("two pieces call LOCKING ME once, not on every prompt", function()
      reset({ asthma = true, slickness = true }); tick(); tick(); tick()
      expect(#sent).toBe(1)
      expect(sent[1]).toBe("pt LOCKING ME (2/3): asthma, slickness")
    end)

    it("each worse stage is called once", function()
      reset({ asthma = true, slickness = true }); tick()
      ataxia.afflictions.anorexia = true; tick(); tick()
      ataxia.afflictions.impatience = true; tick()
      expect(#sent).toBe(3)
      expect(sent[2]).toBe("pt SOFTLOCKED: asthma, slickness, anorexia")
      expect(sent[3]).toBe("pt HARDLOCKED: asthma, slickness, anorexia, impatience")
    end)

    it("truelock: paralysis with the lock-breaker blocked", function()
      reset({ asthma = true, slickness = true, anorexia = true, impatience = true,
        paralysis = true, weariness = true })
      expect(ataxia_canActive()).toBe(false)
      tick()
      expect(sent[1]:match("^pt TRUELOCKED: ") ~= nil).toBe(true)
    end)

    it("a lock that ends and comes back later is called again; a flicker is not", function()
      reset({ asthma = true, slickness = true }); tick()
      ataxia.afflictions.slickness = nil; tick()
      ataxia.afflictions.slickness = true; clock = clock + 1; tick()
      expect(#sent).toBe(1)
      ataxia.afflictions.slickness = nil; tick()
      ataxia.afflictions.slickness = true; clock = clock + 10; tick()
      expect(#sent).toBe(2)
    end)

    it("off with the relay off, the setting off, the basher on, or aeon", function()
      reset({ asthma = true, slickness = true }); partyrelay = false; tick()
      reset({ asthma = true, slickness = true }); ataxia.settings.lockPartyCall = false; tick()
      reset({ asthma = true, slickness = true }); ataxiaBasher.enabled = true; tick()
      reset({ asthma = true, slickness = true, aeon = true }); tick()
      expect(#sent).toBe(0)
    end)
  end)
end)

send, getEpoch, partyrelay, ataxiaBasher = savedSend, savedEpoch, savedRelay, savedBasher
if not okRun then error(err) end
