--- test_mnem_brazier.lua -- Convocation boon: summon a denizen with the brazier tattoo
--
-- Boon: "You may now use brazier tattoos on non-boss denizens, but your brazier tattoo incurs a 1
-- minutes cooldown." User rule (2026-11-20): touch brazier whenever the tattoo is off cooldown and
-- our room has no denizen. Keyword = last word of the last non-own denizen fought this ripple.
-- Captured lines (OURS, 2026-11-20) are used verbatim below.
--
-- Files share ONE Lua state: every global replaced here is saved and restored at the bottom.

require("mock_mudlet")

local saved = {
  ataxia = ataxia, ataxiaBasher = ataxiaBasher, ataxiaTemp = ataxiaTemp, send = send,
  getEpoch = getEpoch, mnemConvocation = mnemConvocation, yajl = yajl, postHTTP = postHTTP,
  getHTTP = getHTTP, line = line, matches = matches, mnemRimewrought = mnemRimewrought,
}

yajl = yajl or { to_string = function() return "JSON" end, to_value = function() return nil end }
postHTTP = postHTTP or function() end
getHTTP = getHTTP or function() end
ataxia = { settings = { reporting = {} } }
ataxiaTemp = {}
for _, f in ipairs({ "001_HTTP_Client", "002_Reporter_API", "003_Commands", "004_Parsers",
                     "005_Ripple_Map", "007_History", "008_Explorer" }) do
  dofile("src_new/scripts/levi_ataxia/levi/ataxia/mnemosyne/" .. f .. ".lua")
end
local M = ataxia.mnemosyne
local MAP = M.map

local sent, ticks, now = {}, {}, 1000
local realSched, realStep, realHaemo = M._scheduleTick, M._nextExploreStep, M._haemoHold
local realSwarm = M.swarm

local function setup()
  ataxia.denizensHere = {}
  ataxia.vitals = { bal = true, eq = true, hpp = 100 }
  ataxiaBasher = { inMnemosyne = true }
  ataxiaTemp = {}
  mnemConvocation = true
  mnemRimewrought = false
  MAP.current = 5
  sent, ticks, now = {}, {}, 1000
  getEpoch = function() return now end
  send = function(c) sent[#sent + 1] = c end
  M._scheduleTick = function(d) ticks[#ticks + 1] = d end
  M._nextExploreStep = function() return nil, "stub" end
  M._haemoHold = function() return false end
  M.swarm = { state = "idle" }
  M.explore.on, M.explore.moving, M.explore.pausedAtBoon = true, false, false
end

local function teardown()
  M._scheduleTick, M._nextExploreStep, M._haemoHold, M.swarm = realSched, realStep, realHaemo, realSwarm
  M.explore.on = false
end

local function scenario(fn)
  setup()
  local ok, err = pcall(fn)
  teardown()
  if not ok then error(err, 0) end
end

-- A tick with nothing to do ends the sweep (explore.on = false); keep it on between ticks.
local function tick()
  M.explore.on = true
  M._exploreTick()
end

local function fought()
  ataxia.denizensHere = { [11] = "an elderly constable" }
  tick()
  ataxia.denizensHere = {}
  sent = {}
end

describe("Convocation keyword", function()
  it("is the last word, lower case, punctuation stripped", function()
    expect(M._brazierKeyword("an elderly constable")).toBe("constable")
    expect(M._brazierKeyword("The Grizzled Watchman.")).toBe("watchman")
    expect(M._brazierKeyword("a snarling wolf,")).toBe("wolf")
    expect(M._brazierKeyword("")).toBeNil()
    expect(M._brazierKeyword(nil)).toBeNil()
  end)

  it("is learned from a denizen in the room by the tick", function()
    scenario(function()
      ataxia.denizensHere = { [11] = "an elderly constable" }
      tick()
      expect(ataxiaTemp.mnemBrazierKey).toBe("constable")
      expect(#sent).toBe(0)
    end)
  end)

  it("onBrazierSummon re-learns it from the captured line's name", function()
    scenario(function()
      M.onBrazierSummon("an elderly constable")
      expect(ataxiaTemp.mnemBrazierKey).toBe("constable")
    end)
  end)

  it("a ripple change forgets key and tried room but keeps the cooldown stamp", function()
    scenario(function()
      ataxiaTemp.mnemBrazierKey, ataxiaTemp.mnemBrazierTriedRoom, ataxiaTemp.mnemBrazierAt = "x", 5, 900
      M.onRipple(3)
      expect(ataxiaTemp.mnemBrazierKey).toBeNil()
      expect(ataxiaTemp.mnemBrazierTriedRoom).toBeNil()
      expect(ataxiaTemp.mnemBrazierAt).toBe(900)
    end)
  end)
end)

describe("Convocation pick on the tick", function()
  it("sends touch brazier <key> in an empty room once the keyword is known", function()
    scenario(function()
      fought()
      tick()
      expect(sent[1]).toBe("touch brazier constable")
      expect(#sent).toBe(1)
      expect(ticks[#ticks]).toBe(2)
    end)
  end)

  it("sends nothing without the boon flag", function()
    scenario(function()
      fought()
      mnemConvocation = false
      tick()
      expect(#sent).toBe(0)
      M.explore.on = true
      local cmd, why = M._brazierPick()
      expect(cmd).toBeNil()
      expect(why ~= nil).toBeTrue()
    end)
  end)

  it("sends nothing under Rimewrought (tattoos inert, v4.7.333)", function()
    scenario(function()
      fought()
      mnemRimewrought = true
      tick()
      expect(#sent).toBe(0)
      M.explore.on = true
      local cmd, why = M._brazierPick()
      expect(cmd).toBeNil()
      expect(why).toBe("Rimewrought: tattoos inert")
    end)
  end)

  it("sends nothing while a denizen is in the room", function()
    scenario(function()
      fought()
      ataxia.denizensHere = { [12] = "a snarling wolf" }
      tick()
      expect(#sent).toBe(0)
    end)
  end)

  it("the pick itself refuses with a denizen present", function()
    scenario(function()
      fought()
      ataxia.denizensHere = { [12] = "a snarling wolf" }
      M.explore.on = true
      local cmd, why = M._brazierPick()
      expect(cmd).toBeNil()
      expect(why).toBe("denizens here")
    end)
  end)

  it("sends nothing before any denizen was fought (no keyword) and says why", function()
    scenario(function()
      tick()
      expect(#sent).toBe(0)
      M.explore.on = true
      local cmd, why = M._brazierPick()
      expect(cmd).toBeNil()
      expect(why:find("keyword", 1, true) ~= nil).toBeTrue()
    end)
  end)

  it("holds 60 s after the taxed line, then sends again", function()
    scenario(function()
      fought()
      M.onBrazierTaxed()
      expect(ataxiaTemp.mnemBrazierAt).toBe(1000)
      now = 1059
      tick()
      expect(#sent).toBe(0)
      now = 1060
      tick()
      expect(sent[1]).toBe("touch brazier constable")
    end)
  end)

  it("tries once per room, and again in the next room", function()
    scenario(function()
      fought()
      tick()
      tick()
      expect(#sent).toBe(1)
      MAP.current = 6
      tick()
      expect(#sent).toBe(2)
    end)
  end)

  it("a Haemophiliac hold blocks it", function()
    scenario(function()
      fought()
      M._haemoHold = function() return true end
      tick()
      expect(#sent).toBe(0)
    end)
  end)

  it("needs balance and equilibrium", function()
    scenario(function()
      fought()
      ataxia.vitals.bal = false
      tick()
      expect(#sent).toBe(0)
      ataxia.vitals.bal, ataxia.vitals.eq = true, false
      tick()
      expect(#sent).toBe(0)
    end)
  end)

  it("is refused while the explorer is paused at the boon screen or the swarm is busy", function()
    scenario(function()
      fought()
      M.swarm = { state = "recovering" }
      M.explore.on = true
      expect(M._brazierPick()).toBeNil()
      M.swarm = { state = "idle" }
      M.explore.pausedAtBoon = true
      M.explore.on = true
      expect(M._brazierPick()).toBeNil()
    end)
  end)
end)

describe("Convocation triggers (real patterns)", function()
  local TL = dofile("src_new/tests/trigger_lib.lua")
  local DIR = "src_new/triggers/levi_ataxia/for_levi/leviticus/mnemosyne/"
  local SUMMON = "You wave your hand over the brazier tattoo and summon an elderly constable to you."
  local TAXED = "The colour is leeched from your brazier tattoo as it is greatly taxed."

  it("the summon pattern matches the captured line, and the handler learns the name", function()
    local pats = TL.patterns(DIR .. "111_Brazier_Summon.lua")
    expect(TL.anyMatches(pats, SUMMON)).toBeTrue()
    expect(TL.anyMatches(pats, "You wave your hand over the brazier tattoo.")).toBeFalse()
    local realMatches = matches
    local ok, err = pcall(function()
      scenario(function()
        matches = { SUMMON, "an elderly constable" }
        dofile(DIR .. "111_Brazier_Summon.lua")
        expect(ataxiaTemp.mnemBrazierKey).toBe("constable")
      end)
    end)
    matches = realMatches
    if not ok then error(err, 0) end
  end)

  it("the taxed pattern is the exact whole line and stamps the cooldown", function()
    local pats = TL.patterns(DIR .. "112_Brazier_Taxed.lua")
    expect(TL.anyMatches(pats, TAXED)).toBeTrue()
    expect(TL.anyMatches(pats, "The colour is leeched from your tattoo.")).toBeFalse()
    scenario(function()
      dofile(DIR .. "112_Brazier_Taxed.lua")
      expect(ataxiaTemp.mnemBrazierAt).toBe(1000)
    end)
  end)
end)

-- Restore shared state for whoever runs after us.
ataxia, ataxiaBasher, ataxiaTemp, send, getEpoch = saved.ataxia, saved.ataxiaBasher, saved.ataxiaTemp, saved.send, saved.getEpoch
mnemConvocation, yajl, postHTTP, getHTTP = saved.mnemConvocation, saved.yajl, saved.postHTTP, saved.getHTTP
line, matches = saved.line, saved.matches
mnemRimewrought = saved.mnemRimewrought
