--- test_rf_line_dragoncurse.lua -- the Righteous Fire save line (mnemosyne/115) and the Dragoncurse
--- party call (555), v4.7.518. Real trigger files and patterns; every replaced global is restored.

require("mock_mudlet")
local TL = dofile("src_new/tests/trigger_lib.lua")

local NAMES = { "send", "tempTimer", "ataxia", "ataxiaTemp", "ataxiaBasher", "ataxiaEcho", "isTargeted",
  "matches", "ataxia_partyCallAllowed", "getEpoch" }
local saved = {}
for _, n in ipairs(NAMES) do saved[n] = _G[n] end

local function body(path)
  local fh = assert(io.open(path, "r"))
  local src = fh:read("*a"); fh:close()
  return assert((loadstring or load)(src:match("%]%]%-%-\r?\n(.*)$")))
end
local T = "src_new/triggers/levi_ataxia/for_levi/leviticus/"
local RF = T .. "mnemosyne/115_Righteous_Fire_Save.lua"
local DC = T .. "555_Dragoncurse_Set.lua"
local RF_BODY, DC_BODY = body(RF), body(DC)

local RF_LINE = "Fire surges about you, restoring you from death's cold brink and bringing holy wrath down"
  .. " upon Leviticus in a brilliant conflagration."
local DC_LINE = "You summon your ancient power and direct the curse of paralysis to strike down Tabethys in 4 seconds."

local sent, timers, calls, clock
local function reset()
  sent, timers, calls, clock = {}, {}, {}, 1000
  send = function(s) sent[#sent + 1] = s end
  tempTimer = function(t, fn) timers[#timers + 1] = { t = t, fn = fn }; return #timers end
  getEpoch = function() return clock end
  ataxiaEcho = function() end
  isTargeted = function() return false end
  ataxiaTemp = {}
  ataxiaBasher = { enabled = false }
  ataxia = { settings = {}, mnemosyne = { swarm = {
    onRighteousFire = function(how) calls[#calls + 1] = how; return true end } } }
end

local function hits(path, line)
  for _, p in ipairs(TL.patterns(path)) do
    if TL.matches(p.pat, p.type, line) then return true end
  end
  return false
end

local okRun, err = pcall(function()
  describe("Righteous Fire save line (115)", function()
    it("the pattern matches the whole line and its first wrapped row", function()
      expect(hits(RF, RF_LINE)).toBeTrue()
      expect(hits(RF, TL.wrap(RF_LINE, 119)[1])).toBeTrue()
    end)

    it("the line calls S.onRighteousFire once", function()
      reset()
      matches = { RF_LINE }
      RF_BODY()
      expect(#calls).toBe(1)
      expect(calls[1]).toBe("the fire line")
    end)

    it("a save the health jump already ran (under 3 s) is not run twice", function()
      reset()
      ataxia.mnemosyne.swarm._rfAt = clock - 1
      matches = { RF_LINE }
      RF_BODY()
      expect(#calls).toBe(0)
    end)

    it("a paladin's fire line does not match", function()
      expect(hits(RF, "As fire surges about the righteous Dunn, he is restored.")).toBeFalse()
    end)
  end)

  describe("Dragoncurse party call (555)", function()
    local function fire()
      local m = { DC_LINE, DC_LINE:match("curse of (%w+) to strike down (%w+) in (%d+) seconds") }
      matches = m
      DC_BODY()
      matches = { "another line" } -- the timer must not read this
      for _, tm in ipairs(timers) do tm.fn() end
    end

    it("the pattern matches", function() expect(hits(DC, DC_LINE)).toBeTrue() end)

    it("PvP: the call goes out when the curse strikes, with the target and the curse", function()
      reset()
      ataxia_partyCallAllowed = function(t) return t == "Tabethys" end
      fire()
      expect(timers[1].t).toBe(4)
      expect(sent[1]).toBe("pt Tabethys: paralysis")
    end)

    it("the PvE guard is asked about the target, not the curse", function()
      reset()
      local asked
      ataxia_partyCallAllowed = function(t) asked = t; return false end
      fire()
      expect(asked).toBe("Tabethys")
      expect(#sent).toBe(0)
    end)
  end)
end)

for _, n in ipairs(NAMES) do _G[n] = saved[n] end
if not okRun then error(err) end
