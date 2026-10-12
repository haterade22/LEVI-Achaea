--- test_target_tree.lua -- one tree of life is one cure in the target model (every class)
--
-- "<name> touches a tree of life tattoo." (trigger 389) charged ONE tree twice: onTargetTreeV3
-- branched over every tree-curable affliction (blackout included since v4.7.416), and then
-- tSingleRandom() erased the first affliction on its own list outright -- a list with no blackout,
-- which moves asthma / slickness / anorexia / impatience to positions 9-35 at run time. So a target
-- with asthma, slickness and blackout read 4/3 afflictions after one tree where the truth is 2, and
-- a real lock piece was gone. These tests drive the REAL trigger through the REAL public API
-- (tarAffed / ataxia_tarAffTimed, 017), the REAL tSingleRandom and ataxia_targetTreeV3 (curing/002)
-- and the REAL V3 tracker (007, 008). Every global the loaded files create or change is restored at
-- the end (one shared Lua state for all test files).
--
-- The review of that fix found two things the old erase had been doing by accident, and the last
-- two describe blocks pin them: an affliction V3 takes for CERTAIN must leave tAffs too (the sync
-- only visits afflictions still in some branch), and a level-1 broken limb, which V3 tracks outside
-- the branches, must still be charged when it is the only thing the tree could take.

local mock = require("mock_mudlet")
local before = {}
for k, v in pairs(_G) do before[k] = v end
local savedContains = table.contains

-- The V3 files initialise these as `X = X or {...}`, so a table left by an earlier test file would
-- be reused and mutated here. Clearing them first makes the loads build fresh ones, which the
-- restore at the end drops (and puts the old ones back untouched).
for _, k in ipairs({ "afflictionStatesV3", "affConfigV3", "simpleAffsV3", "affCacheV3", "targetBurningLevelV3",
  "affLastConfirmedV3", "targetDefensesV3", "cureBalancesV3", "cureBalanceTimerIDsV3", "passiveCooldownsV3",
  "negativeConfirmTimersV3", "tAffsV2", "tAffStacksV2" }) do
  _G[k] = nil
end
ataxiaTemp, tAffs, affTimers = {}, {}, {}

for _, f in ipairs({
  "src_new/scripts/levi_ataxia/levi/ataxia/017_Affliction_Management.lua",
  "src_new/scripts/levi_ataxia/levi/ataxia/curing/002_Wide_Groups.lua",
  "src_new/scripts/levi_ataxia/levi/ataxia/affliction_tracking_core/007_Branching_State_Tracker.lua",
  "src_new/scripts/levi_ataxia/levi/ataxia/affliction_tracking_core/008_V3_Integration.lua",
}) do
  local ok, err = pcall(dofile, f)
  if not ok then error("Failed to load " .. f .. ": " .. tostring(err)) end
end

-- table.contains is a Mudlet extension (tarAffed uses it); restored at the end.
table.contains = table.contains or function(t, v)
  for _, x in pairs(t) do if x == v then return true end end
  return false
end

local TREE = "src_new/triggers/levi_ataxia/for_levi/leviticus/389_Tree(U).lua"
local TL = dofile("src_new/tests/trigger_lib.lua")
-- Verbatim: kb/raw/logs/2026-10-11_mystor_shikudo-vs-infernal-dwc_win_FceAmb0o.txt:359
local LINE = "Agathon touches a tree of life tattoo."

local function body(path)
  local fh = assert(io.open(path, "r"))
  local src = fh:read("*a"); fh:close()
  return assert((loadstring or load)(src:match("%]%]%-%-\r?\n(.*)$")))
end
local TREE_BODY = body(TREE)

-- The world the trigger runs in. Only what the loaded files do not provide is stubbed.
local now, echoed, events = 1000, {}, {}
local function world()
  now, echoed, events = 1000, {}, {}
  mock.reset()                          -- no timer from an earlier test may fire into this one
  getEpoch = function() return now end
  target = "Agathon"
  isTargeted = function(n) return n == "Agathon" end
  -- Recorded, not dispatched: 017 registers "tar afflicted" by NAME, which the mock cannot call.
  raiseEvent = function(e, a) events[#events + 1] = { e, a } end
  checkTargetLocks = function() end     -- curing/003, not loaded
  ataxiaEcho, zgui = function() end, nil
  cecho = function(s) echoed[#echoed + 1] = s end
  fg = function() end
  ataxiaTemp = { tarAffTimers = {} }
  tAffs, affTimers = {}, {}
  tBals = { tree = true, focus = true, timers = {} }
  passiveFailsafe, tdeliverance = nil, nil
  treeTimer0, treeTimer4, treeTimer9, treeTimer = nil, nil, nil, nil
  magi = { offense = { state = { burns = 0 } } }
  affConfigV3.enabled = true
  resetStatesV3()
end

local function tree()
  line = LINE
  matches = { LINE, LINE:match("^(%w+) touches") }
  TREE_BODY()
end

local P = function(a) return getAffProbabilityV3(a) end
local function sum(affs)
  local s = 0
  for _, a in ipairs(affs) do s = s + P(a) end
  return s
end
-- Branch weights are thirds, so compare with a tolerance and say what came out.
local function near(got, want, what)
  if math.abs(got - want) > 1e-9 then
    error(string.format("%s: expected %.4f but got %.4f", what, want, got), 2)
  end
end
-- The afflictions erAff reported cured ("target cured aff", 017), in order.
local function cured()
  local out = {}
  for _, ev in ipairs(events) do
    if ev[1] == "target cured aff" then out[#out + 1] = ev[2] end
  end
  return out
end
-- V3 and tAffs agree that it is gone; the error names the affliction and the test's line.
local function gone(a)
  if P(a) ~= 0 or tAffs[a] ~= false then
    error(string.format("%s should be gone: P=%s, tAffs=%s", a, tostring(P(a)), tostring(tAffs[a])), 2)
  end
end
-- V3 and tAffs agree that it is still there, for certain.
local function kept(a)
  if P(a) ~= 1 or tAffs[a] ~= true then
    error(string.format("%s should be kept: P=%s, tAffs=%s", a, tostring(P(a)), tostring(tAffs[a])), 2)
  end
end

local ok, err = pcall(function()
describe("the target's tree is charged once (trigger 389)", function()
  it("clumsiness, weariness and blackout: one tree leaves a sum of 2, not 4/3", function()
    world()
    tarAffed("clumsiness", "weariness")
    ataxia_tarAffTimed("blackout", 4)
    tree()
    near(sum({ "clumsiness", "weariness", "blackout" }), 2, "sum")
    for _, a in ipairs({ "clumsiness", "weariness", "blackout" }) do near(P(a), 2 / 3, a) end
  end)

  it("asthma, slickness and blackout: a sum of 2, and no lock piece is gone", function()
    world()
    tarAffed("asthma", "slickness")
    ataxia_tarAffTimed("blackout", 4)
    tree()
    near(sum({ "asthma", "slickness", "blackout" }), 2, "sum")
    for _, a in ipairs({ "asthma", "slickness", "blackout" }) do near(P(a), 2 / 3, a) end
    -- Nothing was erased, so a cure line in the next 0.5 s has nothing to put back.
    expect(passiveFailsafe).toBeNil()
    -- Each candidate is still there in two branches of three, so none is reported cured.
    expect(#cured()).toBe(0)
  end)

  it("paralysis is still erased outright: a tree proves they were not paralysed", function()
    world()
    tarAffed("paralysis", "asthma", "slickness")
    ataxia_tarAffTimed("blackout", 4)
    tree()
    expect(P("paralysis")).toBe(0)
    near(sum({ "asthma", "slickness", "blackout" }), 2, "sum")
  end)

  it("stamps ataxiaTemp.targetTreeAt with the tree's time, and only for a tree that counts", function()
    world()
    now = 1234.5
    tarAffed("asthma")
    tree()
    expect(ataxiaTemp.targetTreeAt).toBe(1234.5)
    expect(tBals.tree).toBeFalse()
    -- A second line inside the 13 s window fails 389's tBals.tree gate and moves nothing.
    now = 1240
    tree()
    expect(ataxiaTemp.targetTreeAt).toBe(1234.5)
  end)

  it("the trigger's own pattern matches the logged line", function()
    expect(TL.anyMatches(TL.patterns(TREE), LINE)).toBeTrue()
  end)
end)

describe("with V3 disabled the old erase is unchanged", function()
  it("tSingleRandom still erases its pick (clumsiness first on its list)", function()
    world()
    local okInner, errInner = pcall(function()
      affConfigV3.enabled = false
      tarAffed("clumsiness", "weariness")
      ataxia_tarAffTimed("blackout", 4)
      tree()
      expect(P("clumsiness")).toBe(0)
      near(sum({ "clumsiness", "weariness", "blackout" }), 4 / 3, "sum")
      expect(echoed[#echoed]).toBe("<red> -clumsiness")
    end)
    affConfigV3.enabled = true
    if not okInner then error(errInner, 0) end
  end)
end)

describe("what V3 takes for certain leaves tAffs too (ataxia_targetTreeV3)", function()
  -- When the tree could take only one thing, onTargetTreeV3 removes it from every branch, and the
  -- sync (007) never visits an affliction no branch holds: tAffs kept it true while V3 said 0, and
  -- every tAffs reader (the Shikudo lock's checkSoftlock) saw a lock piece the tree had taken.
  it("a lone asthma: gone from tAffs as well as V3, reported cured once", function()
    world()
    tarAffed("asthma")
    tree()
    gone("asthma")
    expect(#cured()).toBe(1)
    expect(cured()[1]).toBe("asthma")
  end)

  it("only the pool affliction goes; its partner outside the pool stays", function()
    -- Hypochondria, recklessness, disloyalty and aeon are not in the tree pool (008), so each
    -- time the tree could take only the first of the pair.
    for _, pair in ipairs({ { "impatience", "hypochondria" }, { "anorexia", "recklessness" },
                            { "slickness", "disloyalty" }, { "weariness", "aeon" } }) do
      world()
      tarAffed(pair[1], pair[2])
      tree()
      gone(pair[1])
      kept(pair[2])
    end
  end)

  it("a lone blackout goes, and its 4 s clock stops with it (not cured twice)", function()
    world()
    ataxia_tarAffTimed("blackout", 4)
    tree()
    gone("blackout")
    expect(ataxiaTemp.tarAffTimers.blackout).toBeNil()
    mock.fire_timers()                   -- the 4 s expiry, had it still been running
    expect(#cured()).toBe(1)
  end)
end)

describe("a level-1 broken limb is charged when nothing else could be", function()
  -- The four limbs are tree-curable (008, v4.7.416) but simple-tracked (007): onTargetTreeV3 only
  -- looks in the branches, so it never charges one.
  it("a broken limb alone: the tree takes it", function()
    world()
    tarAffed("brokenleftleg")
    tree()
    gone("brokenleftleg")
    expect(#cured()).toBe(1)
  end)

  it("two limbs and nothing else: one goes (the left leg, first in the pool), one charge", function()
    world()
    tarAffed("brokenrightarm", "brokenleftleg")
    tree()
    gone("brokenleftleg")
    kept("brokenrightarm")
    expect(#cured()).toBe(1)
  end)

  it("beside a branch candidate the limb stays: V3 charges the candidate, and only once", function()
    world()
    tarAffed("brokenleftleg", "clumsiness")
    tree()
    gone("clumsiness")
    kept("brokenleftleg")
    expect(#cured()).toBe(1)
  end)

  it("a tree V3 calls an illusion charges nothing, not even a limb", function()
    world()
    tarAffed("clumsiness")
    tree()                               -- a real tree: V3's tree balance runs to 1013
    now = 1005
    tBals.tree = true                    -- 389's gate open again; V3's balance is not
    tarAffed("brokenleftleg")
    tree()
    kept("brokenleftleg")
  end)
end)

describe("tSingleRandom(opts) (curing/002)", function()
  it("noErase returns its pick and changes nothing: no erase, no bleed reset, no echo", function()
    world()
    tarAffed("haemophilia")
    tAffs.bleed = 300
    expect(tSingleRandom({ noErase = true })).toBe("haemophilia")
    expect(P("haemophilia")).toBe(1)
    expect(tAffs.bleed).toBe(300)
    expect(#echoed).toBe(0)
  end)

  it("noErase leaves passiveFailsafe alone, even when a lock affliction went to the back", function()
    world()
    tarAffed("asthma", "slickness")   -- asthma + slickness: asthma moves to position 35
    expect(tSingleRandom({ noErase = true })).toBe("slickness")
    expect(passiveFailsafe).toBeNil()
    expect(P("slickness")).toBe(1)
  end)

  it("the default erases that same pick and arms the failsafe, as before", function()
    world()
    tarAffed("asthma", "slickness")
    expect(tSingleRandom()).toBe("slickness")
    expect(P("slickness")).toBe(0)
    expect(P("asthma")).toBe(1)
    expect(passiveFailsafe).toBe("slickness")
    expect(echoed[#echoed]).toBe("<red> -slickness")
  end)
end)
end)

-- Restore the shared Lua state: drop every global the loaded files created and put back every
-- one they replaced.
for k in pairs(_G) do
  if before[k] == nil then _G[k] = nil end
end
for k, v in pairs(before) do _G[k] = v end
table.contains = savedContains
if not ok then error(err) end
