--- test_prone_shield.lua -- v4.7.521: TOUCH SHIELD needs us standing, so a basher shield sent while
--- prone queues a stand ahead of it, and prone on a bad leg starts no stand at all.
---
--- The fact (OURS, live probe 2026-11-24, kb/raw/live/shield-touch-prone_2026-11-24.txt): sitting,
--- `queue addclear freestand touch shield` is held; a `free` entry is refused "You must be standing
--- first."; after "You stand up." the held freestand entry runs on the same tick. The defect: the
--- prone handler queues ONE `queue prepend eqbal stand`, and the last stand's `cq all` deleted it.

require("mock_mudlet")

local BASHER = "src_new/scripts/levi_ataxia/levi/ataxia/basher/001_Bashing_Functions.lua"

-- Every global and field these tests replace, put back after each test (one Lua state).
local GLOBALS = { "ataxiaEcho", "getEpoch", "send", "get_Battlerage", "ataxiaBasher_canShield",
  "ataxia_effHp", "ataxia_effHpp", "mnemBravado", "mnemRimewrought", "bashStats_recordIncoming",
  "ataxiaBasher_isDamageRateExtreme", "gmcp", "ataxiaBasher_checkPlayerFlee",
  "ataxiaBasher_assembleAttack", "ataxiaBasher_bashingFuncs" }
local ATAXIA = { "vitals", "afflictions", "defences", "denizensHere", "mnemosyne" }
local BASHERF = { "enabled", "inMnemosyne", "lastStand", "lastStandRelease", "shieldBreakers",
  "shieldRecord", "fleeThresholdPct", "shieldThresholdPct", "manual", "paused" }

local clock, sent, said, swung = 1000, {}, {}, 0
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
  ataxiaEcho = function(m) said[#said + 1] = tostring(m) end
  get_Battlerage = function() end
  ataxiaBasher_canShield = function() return false end -- the tower: every denizen on the list
  local okLoad, errLoad = pcall(dofile, BASHER)
  if not okLoad then error(tostring(errLoad)) end
  clock, sent, said, swung = 1000, {}, {}, 0
  getEpoch = function() return clock end
  send = function(c) sent[#sent + 1] = c end
  ataxia_effHp, ataxia_effHpp = nil, nil
  mnemBravado, mnemRimewrought = nil, nil
  bashStats_recordIncoming = nil
  ataxiaBasher_isDamageRateExtreme = function() return false end
  ataxiaBasher_checkPlayerFlee = function() return false end
  ataxiaBasher_assembleAttack = function() swung = swung + 1 end
  ataxiaBasher_bashingFuncs = { Serpent = "ataxiaBasher_serpentBashing" }
  gmcp = { Room = { Info = { area = "", num = 5150 } }, Char = { Status = { class = "Serpent" } } }
  for k in pairs(ataxiaTemp) do ataxiaTemp[k] = nil end
  ataxia.vitals = { hpp = 100, hp = 11400, maxhp = 11400 }
  ataxia.afflictions, ataxia.defences = {}, {}
  ataxia.denizensHere = { [101] = "a tash'la warrior", [102] = "a tash'la interceptor" }
  -- Prey (kb: the tash'la death): the swarm cannot leave, so the ordinary last stand runs.
  ataxia.mnemosyne = { swarm = {
    _cfg = function() return { escapeAt = 35, returnAt = 85 } end,
    _enabled = function() return false end,
    disengage = function() return false, "Prey -- every denizen tracks a retreat, so we fight here" end,
  } }
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

local function sentHas(cmd)
  for _, c in ipairs(sent) do if c == cmd then return true end end
  return false
end

local function saidHas(piece)
  for _, m in ipairs(said) do if m:find(piece, 1, true) then return true end end
  return false
end

local function same(got, want)
  expect(#got).toBe(#want)
  for i = 1, math.max(#got, #want) do expect(got[i]).toBe(want[i]) end
end

describe("v4.7.521 -- the last stand stands us up before the shield", function()
  it("prone: cq all, the freestand shield, then the stand, as three entries", function()
    run(function()
      ataxia.afflictions.prone = true
      ataxia.vitals.hpp = 20
      ataxiaBasher_attack()
      same(sent, { "cq all", "queue addclear freestand touch shield", "queue prepend eqbal stand" })
      expect(swung).toBe(0)
      expect(ataxiaTemp.lastStandAt).toBe(1000)
    end)
  end)

  it("the resend after 3 s stands us again (the first stand was refused or cleared)", function()
    run(function()
      ataxia.afflictions.prone = true
      ataxia.vitals.hpp = 20
      ataxiaBasher_attack()
      sent = {}
      clock = 1003.1
      ataxiaBasher_attack()
      same(sent, { "cq all", "queue addclear freestand touch shield", "queue prepend eqbal stand" })
    end)
  end)

  it("standing: no stand is queued", function()
    run(function()
      ataxia.vitals.hpp = 20
      ataxiaBasher_attack()
      same(sent, { "cq all", "queue addclear freestand touch shield" })
    end)
  end)

  it("prone at 0 stacks (cured, zeroed) counts as standing", function()
    run(function()
      ataxia.afflictions.prone = 0
      ataxia.vitals.hpp = 20
      ataxiaBasher_attack()
      expect(sentHas("queue prepend eqbal stand")).toBeFalse()
    end)
  end)

  it("in lava: no cq all, and the stand is still queued", function()
    run(function()
      ataxia.mnemosyne.roomLava = function() return true end
      ataxia.afflictions.prone = true
      ataxia.vitals.hpp = 20
      ataxiaBasher_attack()
      same(sent, { "queue addclear freestand touch shield", "queue prepend eqbal stand" })
    end)
  end)
end)

describe("v4.7.521 -- prone on a bad leg: the stand is refused, so no shield", function()
  it("no new last stand starts, and the reason is said", function()
    run(function()
      ataxia.afflictions.prone = true
      ataxia.afflictions.brokenleftleg = true
      ataxia.vitals.hpp = 20
      local want, why = ataxiaBasher_lastStandWanted(20)
      expect(want).toBeFalse()
      expect(why).toBe("prone on a bad leg: the stand is refused, so no shield")
      expect(ataxiaBasher_lastStand(20)).toBeNil()
      expect(ataxiaTemp.lastStandAt).toBeNil()
      expect(saidHas("NO SHIELD: no last stand -- prone on a bad leg")).toBeTrue()
      expect(sentHas("queue addclear freestand touch shield")).toBeFalse()
    end)
  end)

  it("one damaged leg is enough (the stand checks both legs)", function()
    run(function()
      ataxia.afflictions.prone = true
      ataxia.afflictions.damagedrightleg = true
      expect(ataxiaBasher_proneNoShield()).toBe("prone on a bad leg: the stand is refused, so no shield")
      ataxia.afflictions.prone = nil
      expect(ataxiaBasher_proneNoShield()).toBeNil()        -- standing on it: the shield works
    end)
  end)

  it("the swarm's own leg reader is used when it is loaded", function()
    run(function()
      ataxia.afflictions.prone = true
      ataxia.mnemosyne.swarm._oneLegOut = function() return true end
      expect(ataxiaBasher_proneNoShield()).toBe("prone on a bad leg: the stand is refused, so no shield")
    end)
  end)

  it("a stand already on, shield not up, ends on the next round so the retreat can run", function()
    run(function()
      ataxia.afflictions.prone = true
      ataxia.vitals.hpp = 20
      expect(ataxiaBasher_lastStand(20)).toBe("shield")    -- prone, legs fine: the stand starts
      clock = 1001
      ataxia.afflictions.mangledleftleg = true             -- knocked about while it waits
      expect(ataxiaBasher_lastStand(20)).toBeNil()
      expect(ataxiaTemp.lastStandAt).toBeNil()
      expect(ataxiaTemp.lastStandCoolUntil).toBeNil()      -- no cooldown: once up, a stand may start
      expect(saidHas("LAST STAND over (prone on a bad leg: the stand is refused, so no shield)")).toBeTrue()
    end)
  end)

  it("a stand whose shield is already up keeps holding", function()
    run(function()
      ataxia.vitals.hpp = 20
      expect(ataxiaBasher_lastStand(20)).toBe("shield")
      clock = 1001
      ataxia.defences.shield = true
      ataxia.afflictions.prone = true
      ataxia.afflictions.brokenleftleg = true
      expect(ataxiaBasher_lastStand(20)).toBe("wait")
      expect(ataxiaTemp.lastStandAt).toBe(1000)
    end)
  end)

  it("safeStandBegin refuses with the reason, and ends a shield-safe stand that cannot rise", function()
    run(function()
      ataxia.afflictions.prone = true
      ataxia.afflictions.brokenrightleg = true
      local ok, why = ataxiaBasher_safeStandBegin(23, "LOW HP")
      expect(ok).toBeFalse()
      expect(why).toBe("prone on a bad leg: the stand is refused, so no shield")
      -- a shield-safe stand already on, with its shield not up
      ataxiaTemp.lastStandAt, ataxiaTemp.lastStandSafe = 1000, true
      ok, why = ataxiaBasher_safeStandBegin(23, "LOW HP")
      expect(ok).toBeFalse()
      expect(why).toBe("prone on a bad leg: the stand is refused, so no shield")
      expect(ataxiaTemp.lastStandAt).toBeNil()
      expect(#sent).toBe(0)
    end)
  end)

  it("the helper sends nothing on a bad leg while prone", function()
    run(function()
      ataxia.afflictions.prone = true
      ataxia.afflictions.brokenleftleg = true
      local ok, why = ataxiaBasher_queueShield(true)
      expect(ok).toBeFalse()
      expect(why).toBe("prone on a bad leg: the stand is refused, so no shield")
      expect(#sent).toBe(0)
    end)
  end)
end)

describe("v4.7.521 -- the plain shield sends stand us too", function()
  it("executeFlee, unable to move and prone: cq all, the shield, the stand", function()
    run(function()
      local realTimer, realGui = ataxiaBasher_startFleeTimer, ataxiagui_updateVitals
      ataxiaBasher_startFleeTimer = function() end
      ataxiagui_updateVitals = function() end
      local okRun, errRun = pcall(function()
        ataxia.afflictions.prone = true
        ataxia.afflictions.webbed = true
        ataxiaBasher_executeFlee()
      end)
      ataxiaBasher_startFleeTimer, ataxiagui_updateVitals = realTimer, realGui
      if not okRun then error(errRun, 0) end
      same(sent, { "cq all", "queue addclear freestand touch shield", "queue prepend eqbal stand" })
    end)
  end)
end)
