--- test_shield_safe.lua -- v4.7.519: denizens that cannot break the shield are learned, and a room
--- of them gets the shield instead of a retreat (basher/001, "SHIELD-SAFE DENIZENS").
---
--- The maintainer (2026-11-24): "there are some mobs who cannot break shields... this has to be
--- tracked so we know when to touch shield instead of running". The log is
--- kb/raw/live/mnemosyne-shield-safe-mobs_2026-11-24.txt: a savage boar and a fearsome lion hurled
--- themselves against our shield for 6 s, "LAST STAND over (health back to 72%) -- attacking.", and
--- the attack dropped the shield. The block lines go through the REAL trigger 030 (its pattern too),
--- the Health lost lines through the REAL trigger 351, the break line through the REAL trigger 029.

require("mock_mudlet")
local TL = dofile("src_new/tests/trigger_lib.lua")

local BASHER = "src_new/scripts/levi_ataxia/levi/ataxia/basher/001_Bashing_Functions.lua"
local BLOCK = "src_new/triggers/levi_ataxia/for_levi/leviticus/denizen_attacks_misc_lines/030_Shield_Blocked_By_Denizen.lua"
local BREAK = "src_new/triggers/levi_ataxia/for_levi/leviticus/denizen_attacks_misc_lines/029_Shield_Broken_By_Denizen.lua"
local HEALTH = "src_new/triggers/levi_ataxia/for_levi/leviticus/351_Health_Lost_By_Type.lua"

-- The log's lines, verbatim (kb/raw/live/mnemosyne-shield-safe-mobs_2026-11-24.txt).
local BOAR = "A savage boar hurls itself against your shield in a futile attempt to harm you."
local LION = "A fearsome lion hurls itself against your shield in a futile attempt to harm you."

-- Every global and field these tests replace, put back after each test (one Lua state).
local GLOBALS = { "ataxiaEcho", "getEpoch", "send", "getLines", "getLineNumber", "matches", "line",
  "get_Battlerage", "ataxiaBasher_canShield", "ataxia_effHp", "ataxia_effHpp", "mnemBravado",
  "mnemRimewrought", "bashStats_recordIncoming", "ataxiaBasher_isDamageRateExtreme", "gmcp" }
local ATAXIA = { "vitals", "afflictions", "defences", "denizensHere", "mnemosyne" }
local BASHERF = { "enabled", "inMnemosyne", "lastStand", "lastStandRelease", "shieldBreakers",
  "shieldRecord", "fleeThresholdPct", "shieldThresholdPct", "manual" }

local clock, sent, said = 1000, {}, {}
local saved

local function begin()
  saved = { g = {}, a = {}, b = {}, t = {} }
  ataxia = ataxia or {}
  ataxiaBasher = ataxiaBasher or {}
  ataxiaTemp = ataxiaTemp or {}
  for _, k in ipairs(GLOBALS) do saved.g[k] = _G[k] end
  for _, k in ipairs(ATAXIA) do saved.a[k] = ataxia[k] end
  for _, k in ipairs(BASHERF) do saved.b[k] = ataxiaBasher[k] end
  for k, v in pairs(ataxiaTemp) do saved.t[k] = v end
  -- the stubs the basher file reads at run time
  ataxiaEcho = function(m) said[#said + 1] = tostring(m) end
  get_Battlerage = function() end
  ataxiaBasher_canShield = function() return false end -- the tower: every denizen on the list
  local okLoad, errLoad = pcall(dofile, BASHER)
  if not okLoad then error(tostring(errLoad)) end
  clock, sent, said = 1000, {}, {}
  getEpoch = function() return clock end
  send = function(c) sent[#sent + 1] = c end
  ataxia_effHp, ataxia_effHpp = nil, nil
  mnemBravado, mnemRimewrought = nil, nil
  bashStats_recordIncoming = nil
  ataxiaBasher_isDamageRateExtreme = function() return false end
  gmcp = { Room = { Info = { area = "", num = 5150 } }, Char = { Status = { class = "Serpent" } } }
  for k in pairs(ataxiaTemp) do ataxiaTemp[k] = nil end
  ataxia.vitals = { hpp = 100, hp = 11400, maxhp = 11400 }
  ataxia.afflictions, ataxia.defences = {}, {}
  ataxia.denizensHere = { [801] = "a savage boar", [802] = "a fearsome lion" }
  ataxia.mnemosyne = nil
  ataxiaBasher.enabled, ataxiaBasher.inMnemosyne, ataxiaBasher.manual = true, true, true
  ataxiaBasher.lastStand, ataxiaBasher.lastStandRelease = nil, nil
  ataxiaBasher.shieldBreakers, ataxiaBasher.shieldRecord = nil, nil
  ataxiaBasher.fleeThresholdPct, ataxiaBasher.shieldThresholdPct = 25, 40
end

local function finish()
  for _, k in ipairs(GLOBALS) do _G[k] = saved.g[k] end
  for _, k in ipairs(ATAXIA) do ataxia[k] = saved.a[k] end
  for _, k in ipairs(BASHERF) do ataxiaBasher[k] = saved.b[k] end
  for k in pairs(ataxiaTemp) do ataxiaTemp[k] = nil end
  for k, v in pairs(saved.t) do ataxiaTemp[k] = v end
end

local function run(fn)
  begin()
  local ok, err = pcall(fn)
  finish()
  if not ok then error(err, 0) end
end

local function blocked(text)
  local pats = TL.patterns(BLOCK)
  expect(TL.anyMatches(pats, text)).toBeTrue()
  expect(TL.anyMatches(pats, TL.wrap(text, 119)[1])).toBeTrue() -- the first server row alone
  matches = { text, text:match("^(.+) hurls itself against your shield") }
  dofile(BLOCK)
end

local function healthLost(text)
  local n, t = text:match("^Health lost: (%d+) %(([^)]+)%)%.?$")
  assert(n, "not a Health lost line: " .. text)
  matches = { text, n, t }
  dofile(HEALTH)
end

local function sentHas(cmd)
  for _, c in ipairs(sent) do if c == cmd then return true end end
  return false
end

local function saidHas(piece)
  for _, m in ipairs(said) do if m:find(piece, 1, true) then return true end end
  return false
end

-- A swarm whose ground retreat is open and whose disengage records its calls.
local function openSwarm(calls)
  ataxia.mnemosyne = { swarm = {
    _cfg = function() return { escapeAt = 35, returnAt = 85 } end,
    _enabled = function() return true end,
    _escapeRouteReady = function() return true end,
    _mayReturn = function() return (tonumber(ataxia.vitals.hpp) or 0) >= 85 and not ataxia.afflictions.paralysis end,
    disengage = function(why) calls[#calls + 1] = why; return true end,
  } }
end

-- The log's room under Prey: the swarm cannot leave, so the old last stand runs.
local function preySwarm()
  ataxia.mnemosyne = { swarm = {
    _cfg = function() return { escapeAt = 35, returnAt = 85 } end,
    _enabled = function() return false end,
    _mayReturn = function() return (tonumber(ataxia.vitals.hpp) or 0) >= 85 end,
    disengage = function() return false, "Prey -- every denizen tracks a retreat, so we fight here" end,
  } }
end

local function learnBoth()
  ataxia.defences.shield = true
  blocked(BOAR); blocked(LION); blocked(BOAR); blocked(LION)
  ataxia.defences.shield = nil
end

describe("v4.7.519 -- the shield record learns who cannot break the shield", function()
  it("replays the log: two blocks each mark the boar and the lion shield-safe", function()
    run(function()
      ataxia.defences.shield = true                       -- 14:28:42, the tattoo is touched
      blocked(BOAR)
      expect(ataxiaBasher.shieldRecord["savage boar"].blocked).toBe(1)
      expect((ataxiaBasher_shieldSafe("a savage boar"))).toBeFalse()
      blocked(LION)
      blocked(BOAR)
      expect((ataxiaBasher_shieldSafe("a savage boar"))).toBeTrue() -- "A savage boar" = "a savage boar"
      expect((ataxiaBasher_shieldSafeRoom())).toBeFalse()             -- the lion has one
      blocked(LION)
      local ok, names = ataxiaBasher_shieldSafeRoom()
      expect(ok).toBeTrue()
      expect(names).toBe("fearsome lion, savage boar")
      expect(ataxiaBasher.shieldRecord["fearsome lion"].broke).toBe(0)
      expect(saidHas("Learned: savage boar cannot break the shield")).toBeTrue()
    end)
  end)

  it("learns a block with no last stand running, and says so", function()
    run(function()
      expect(ataxiaBasher_onShieldBlocked("A savage boar")).toBe("no last stand (savage boar blocked 1x)")
    end)
  end)

  it("a shield-break line, or a hit through the shield after its attack line, marks the denizen", function()
    run(function()
      learnBoth()
      -- the shield-break line through the real trigger 029 (sample: the Grulk death)
      ataxia.denizensHere[803] = "a small brown lemming"
      line = "A small brown lemming rips apart your magical shield defence with its claws."
      dofile(BREAK)
      expect(ataxiaBasher.shieldRecord["small brown lemming"].broke).toBe(1)
      expect((ataxiaBasher_shieldSafeRoom())).toBeFalse()
      ataxia.denizensHere[803] = nil
      -- a hit through the shield: the attack line before it names the lion. The line is MADE UP in
      -- the shape of kb/raw/logs/2026-11-20_mnemosyne-nightmare-death.txt:221 ("The nightmare
      -- convulses and ..."): the short name, not the room list's whole name
      ataxia.defences.shield = true
      ataxiaBasher_noteShieldState()                       -- the danger check sees it up
      clock = 1001
      local buffer = { "14:28:47:120 [7305] ...", "The lion convulses and claws across your torso.",
        "Health lost: 1001 (physical cutting)." }
      getLineNumber = function() return 40 end
      getLines = function() return buffer end
      healthLost("Health lost: 1001 (physical cutting).")
      expect(ataxiaBasher.shieldRecord["fearsome lion"].broke).toBe(1)
      expect(ataxiaBasher.shieldRecord["savage boar"].broke).toBe(0)
      expect((ataxiaBasher_shieldSafe("a fearsome lion"))).toBeFalse()
    end)
  end)

  it("a hit through the shield that no line names is laid on no one in a room of two", function()
    run(function()
      learnBoth()
      ataxia.defences.shield = true
      ataxiaBasher_noteShieldState()
      clock = 1001
      expect(ataxiaBasher_shieldHit(900, "cold", "Cold radiance flares around you.")).toBe(
        "a hit through the shield laid on no one: 2 denizens here and the line before the hit names none of them")
      expect(ataxiaBasher_shieldHit(900, "unblockable", "A savage boar gores you.")).toBe(
        "a shield never stops unblockable damage")
      ataxia.denizensHere[802] = nil                      -- the boar alone: it is the only one
      expect(ataxiaBasher_shieldHit(900, "cold", "Cold radiance flares around you.")).toBe("savage boar broke 1x")
      ataxia.defences.shield = nil
      expect(ataxiaBasher_shieldHit(900, "cold", "x")).toBe("our shield is not up")
    end)
  end)
end)

describe("v4.7.519 -- a room of shield-safe denizens gets the shield instead of a retreat", function()
  it("low HP with the retreat open: shield and hold, no disengage", function()
    run(function()
      learnBoth()
      local calls = {}
      openSwarm(calls)
      ataxia.vitals.hpp = 23
      expect(ataxiaBasher_dangerLevel()).toBe("wait")
      expect(#calls).toBe(0)                              -- the disengage was never asked
      expect(sentHas("cq all")).toBeTrue()
      expect(sentHas("queue addclear freestand touch shield")).toBeTrue()
      expect(ataxiaTemp.lastStandSafe).toBeTrue()
      expect(saidHas("SHIELD-SAFE ROOM: HP 23% -- fearsome lion, savage boar never got through the shield")).toBeTrue()
      clock = 1003.5
      ataxia.defences.shield = true                       -- the shield rises
      expect(ataxiaBasher_dangerLevel()).toBe("wait")
      expect(#calls).toBe(0)
    end)
  end)

  it("outside a no-flee area the same room shields instead of fleeing", function()
    run(function()
      learnBoth()
      ataxiaBasher.inMnemosyne = false
      gmcp.Room.Info.area = "Test Bashing Area"
      ataxia.vitals.hpp = 20
      expect(ataxiaBasher_dangerLevel()).toBe("wait")
      expect(sentHas("queue addclear freestand touch shield")).toBeTrue()
    end)
  end)

  it("one unknown denizen in the room: the old retreat", function()
    run(function()
      learnBoth()
      ataxia.denizensHere[803] = "a tash'la warrior"
      local calls = {}
      openSwarm(calls)
      ataxia.vitals.hpp = 23
      expect(ataxiaBasher_dangerLevel()).toBe("wait")      -- the disengage took the round
      expect(#calls).toBe(1)
      expect(sentHas("queue addclear freestand touch shield")).toBeFalse()
      expect(ataxiaTemp.lastStandAt).toBeNil()
      local ok, why = ataxiaBasher_safeStandBegin(23, "LOW HP")
      expect(ok).toBeFalse()
      expect(why).toBe("tash'la warrior is not known shield-safe (0 of 2 blocks seen)")
    end)
  end)

  it("a hit through the shield ends a stand that replaced a retreat, and bars the room", function()
    run(function()
      learnBoth()
      local calls = {}
      openSwarm(calls)
      ataxia.vitals.hpp = 23
      expect(ataxiaBasher_dangerLevel()).toBe("wait")
      clock = 1002
      ataxia.defences.shield = true
      ataxiaBasher_lastStandHolding()                     -- the prompt sees the shield up
      clock = 1003
      getLineNumber, getLines = nil, nil                  -- no buffer: attribution only by the room
      healthLost("Health lost: 1500 (physical cutting).")
      expect(ataxiaTemp.lastStandAt).toBeNil()
      expect(ataxiaTemp.shieldPassRoom).toBe(5150)
      expect(saidHas("hit passed the shield in a shield-safe room -- back to the escape ladder")).toBeTrue()
      clock = 1020
      ataxia.defences.shield = nil
      expect(ataxiaBasher_dangerLevel()).toBe("wait")      -- the ladder's disengage, this time
      expect(#calls).toBe(1)
    end)
  end)
end)

describe("v4.7.519 -- in a shield-safe room the stand holds to the recovery gate", function()
  it("replays the log: the stand does not end at 72%, but at 85% and cured", function()
    run(function()
      preySwarm()
      ataxia.vitals.hpp = 23                              -- 14:28:43, LOW HP 23%, NOT leaving: Prey
      expect(ataxiaBasher_dangerLevel()).toBe("shield")   -- the old last stand: the room is unknown
      expect(ataxiaTemp.lastStandSafe).toBeNil()
      clock = 1001
      ataxia.defences.shield = true
      ataxiaBasher_lastStandHolding()
      blocked(BOAR); blocked(LION); blocked(BOAR); blocked(LION); blocked(BOAR)
      clock = 1007
      ataxia.vitals.hpp = 72                              -- 14:28:49, the log let go here
      expect(ataxiaBasher_dangerLevel()).toBe("wait")
      expect(ataxiaTemp.lastStandAt).toBe(1000)
      expect(saidHas("LAST STAND holds past 70%: every denizen here is shield-safe (fearsome lion, savage boar)")).toBeTrue()
      clock = 1015
      ataxia.vitals.hpp = 86
      expect(ataxiaBasher_lastStandHolding()).toBeFalse()
      expect(saidHas("LAST STAND over (recovered in a shield-safe room: 85% and cured)")).toBeTrue()
    end)
  end)

  it("an unsafe denizen walking in, or a hit through the shield, brings back the 70% release", function()
    run(function()
      preySwarm()
      learnBoth()
      ataxia.vitals.hpp = 23
      expect(ataxiaBasher_dangerLevel()).toBe("wait")     -- a shield-safe stand: the shield is sent
      expect(ataxiaTemp.lastStandSafe).toBeTrue()
      clock = 1001
      ataxia.defences.shield = true
      ataxia.vitals.hpp = 72
      expect(ataxiaBasher_lastStandHolding()).toBeTrue()
      ataxia.denizensHere[803] = "a tash'la warrior"
      expect(ataxiaBasher_lastStandHolding()).toBeFalse()
      expect(saidHas("LAST STAND over (health back to 72%)")).toBeTrue()
      -- a second stand in the same room, and a hit through the shield
      ataxia.denizensHere[803] = nil
      ataxiaTemp.lastStandCoolUntil = nil
      ataxia.defences.shield = nil
      ataxia.vitals.hpp = 23
      expect(ataxiaBasher_dangerLevel()).toBe("wait")
      clock = 1002
      ataxia.defences.shield = true
      ataxiaBasher_lastStandHolding()
      clock = 1003
      expect(ataxiaBasher_lastStandHit(900, "cold")).toBe("hit 1 of 2 through the shield")
      ataxia.vitals.hpp = 72
      expect(ataxiaBasher_lastStandHolding()).toBeFalse()
    end)
  end)

  it("with no swarm loaded the gate is 85%, and the cap is 120 s", function()
    run(function()
      learnBoth()
      ataxiaBasher.inMnemosyne = false
      gmcp.Room.Info.area = "Test Bashing Area"
      ataxia.vitals.hpp = 20
      expect(ataxiaBasher_dangerLevel()).toBe("wait")
      ataxia.defences.shield = true
      ataxia.vitals.hpp = 84
      clock = 1050                                        -- past the old 30 s cap
      expect(ataxiaBasher_lastStandHolding()).toBeTrue()
      clock = 1121
      expect(ataxiaBasher_lastStandHolding()).toBeFalse()
      expect(saidHas("held 120s in a shield-safe room")).toBeTrue()
    end)
  end)
end)
