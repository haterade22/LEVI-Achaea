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
  "src_new/scripts/levi_ataxia/levi/ataxia/016_Targeting_Functions.lua",
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

  -- 2026-11-07 Serpent spar (kb/raw/logs/ours/2026-11-07_164635_Saibel.log:422): the tree took
  -- recklessness, her only affliction then. The pool had no recklessness, so V3 kept it.
  it("a tree with only recklessness on takes it, from V3 and from tAffs", function()
    world()
    tarAffed("recklessness")
    tree()
    expect(P("recklessness")).toBe(0)
    expect(tAffs.recklessness).toBeFalse()
  end)

  -- Deep review F19 (2026-11-08): 389 took one Magi burn off on every tree. Burning is no tree cure
  -- in V3, and the game's lines own the count (general/025: "The fires consuming X diminish
  -- somewhat."); a tree on burning Kalys left burning at 1.00
  -- (kb/raw/logs/2026-10-19_tabethys_magi-group_kalys_o6UKnyyy.txt:359-361).
  it("a tree leaves the Magi burn count and burning alone", function()
    world()
    tarAffed("weariness", "nausea", "burning")
    magi.offense.state.burns = 2
    tburns = 2
    tree()
    expect(magi.offense.state.burns).toBe(2)
    expect(tburns).toBe(2)
    expect(P("burning")).toBe(1)
  end)
end)

-- The [TREE] countdown echoes (389). In the 2026-11-07 spar Saibel's tree came 12 ms before the
-- pending 14 s echo, and `if treeTimer then return end` skipped that tree's whole countdown.
describe("every accepted tree starts its own countdown echoes (trigger 389)", function()
  -- Run one mock timer as Mudlet would at its time, and drop it from the list.
  local function fire(id)
    local t = assert(mock.active_timers[id], "no such timer: " .. tostring(id))
    mock.active_timers[id] = nil
    local run = type(t.callback) == "string" and assert((loadstring or load)(t.callback)) or t.callback
    run()
  end
  local function delays()
    return mock.active_timers[treeTimer0].delay, mock.active_timers[treeTimer4].delay,
      mock.active_timers[treeTimer9].delay, mock.active_timers[treeTimer].delay
  end

  it("one tree starts the 0, 4, 9 and 14 s echoes", function()
    world()
    tree()
    local d0, d4, d9, d14 = delays()
    expect(d0).toBe(0); expect(d4).toBe(4); expect(d9).toBe(9); expect(d14).toBe(14)
  end)

  it("a tree just before the pending 14 s echo kills it and starts four new echoes", function()
    world()
    tree()
    local old14 = treeTimer
    fire(treeTimer0); fire(treeTimer4); fire(treeTimer9)   -- 0, 4 and 9 s
    expect(treeTimer0).toBeNil()
    fire(tBals.timers.tree)                                  -- 13 s: tBals.tree is up again
    expect(tBals.tree).toBeTrue()
    now = now + 13.988                                       -- the 14 s echo is still pending
    tree()
    expect(mock.active_timers[old14]).toBeNil()
    expect(treeTimer ~= old14).toBeTrue()
    local d0, d4, d9, d14 = delays()
    expect(d0).toBe(0); expect(d4).toBe(4); expect(d9).toBe(9); expect(d14).toBe(14)
    -- One countdown runs, not two: one timer at each echo's delay. (V3's own 13 s tree balance
    -- and 389's 13 s re-arm are timers too, so count by delay.)
    local count = { [0] = 0, [4] = 0, [9] = 0, [14] = 0 }
    for _, t in pairs(mock.active_timers) do
      if count[t.delay] then count[t.delay] = count[t.delay] + 1 end
    end
    for d, n in pairs(count) do
      if n ~= 1 then error(string.format("%d timers at %d s, want 1", n, d)) end
    end
  end)

  it("the new countdown prints all four echoes", function()
    world()
    tree()
    fire(treeTimer0); fire(treeTimer4); fire(treeTimer9); fire(tBals.timers.tree)
    tree()
    echoed = {}
    fire(treeTimer0); fire(treeTimer4); fire(treeTimer9); fire(treeTimer)
    expect(#echoed).toBe(4)
    expect(echoed[4]:find("can now use tree", 1, true) ~= nil).toBeTrue()
    expect(treeTimer).toBeNil()
  end)

  it("a tree inside the 13 s window starts nothing: 389's tBals.tree gate holds", function()
    world()
    tree()
    local ids = { treeTimer0, treeTimer4, treeTimer9, treeTimer }
    now = now + 5
    tree()
    expect(treeTimer0).toBe(ids[1]); expect(treeTimer4).toBe(ids[2])
    expect(treeTimer9).toBe(ids[3]); expect(treeTimer).toBe(ids[4])
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
    -- Dissonance, horror, unweavingmind and heartseed are not in the tree pool (008): the game
    -- marks each NoRandomCure. So each time the tree could take only the first of the pair. (The
    -- old partners, hypochondria, recklessness, disloyalty and aeon, joined the pool on 2026-11-07.)
    for _, pair in ipairs({ { "impatience", "dissonance" }, { "anorexia", "horror" },
                            { "slickness", "unweavingmind" }, { "weariness", "heartseed" } }) do
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

describe("the target's focus clock (triggers 398, 399)", function()
  local TRG = "src_new/triggers/levi_ataxia/for_levi/leviticus/"
  local UNK, KNOWN = TRG .. "398_Focus_(UNK).lua", TRG .. "399_Focus_(known).lua"
  local UNK_BODY, KNOWN_BODY = body(UNK), body(KNOWN)
  local function focusLine(who) return "A look of extreme focus crosses the face of " .. who .. "." end

  local function focus(who)
    line = focusLine(who)
    matches = { line, who }
    UNK_BODY()
  end
  -- The clock's length: 398 and 399 name the timer, so read its delay.
  local function clock() return mock.active_timers[tBals.timers.focus].delay end

  it("the trigger's own pattern matches the line", function()
    expect(TL.anyMatches(TL.patterns(UNK), focusLine("Agathon"))).toBeTrue()
  end)

  it("a bystander's focus leaves the target's clock alone", function()
    world()
    targetIshere = false
    focus("Bystander")
    expect(tBals.focus).toBeTrue()
    expect(tBals.focusUsedAt).toBeNil()
    expect(tBals.timers.focus).toBeNil()
    expect(targetIshere).toBeFalse()             -- and it does not say the target is here
  end)

  it("so the target's real cure right after a bystander's focus still counts", function()
    world()
    tarAffed("anorexia")
    focus("Bystander")
    focus("Agathon")
    expect(P("anorexia")).toBe(0)
    expect(tBals.focus).toBeFalse()
  end)

  it("the target's focus starts the 2 s clock and says he is here", function()
    world()
    targetIshere = false
    now = 1234.5
    focus("Agathon")
    expect(tBals.focus).toBeFalse()
    expect(tBals.focusUsedAt).toBe(1234.5)
    expect(clock()).toBe(2)
    expect(targetIshere).toBeTrue()
    mock.fire_timers()
    expect(tBals.focus).toBeTrue()
    expect(tBals.timers.focus).toBeNil()
  end)

  it("a focus line while the clock runs moves nothing (an illusion), as in 399", function()
    world()
    tBals.focus = false
    focus("Agathon")
    expect(tBals.timers.focus).toBeNil()
    expect(tBals.focusUsedAt).toBeNil()
  end)

  it("398 under shadowmadness: 4.8 s, below the measured floor of 4.82", function()
    world()
    tarAffed("shadowmadness")
    focus("Agathon")
    expect(clock()).toBe(4.8)
  end)

  -- Deep review F43 (2026-11-08): 399 repeated 398's clock behind tBals.focus, which 398 had set
  -- false a line earlier, so it never ran. 398 owns the clock now; 399 only reads the next line.
  it("399 after 398 starts no second clock and moves nothing on a plain next line", function()
    world()
    serpent = nil
    tarAffed("shadowmadness", "stupidity")
    focus("Agathon")
    local id, p = tBals.timers.focus, P("stupidity")
    multimatches = { { focusLine("Agathon"), "Agathon" }, {}, { "The next line." } }
    KNOWN_BODY()
    expect(tBals.timers.focus).toBe(id)
    expect(clock()).toBe(4.8)
    expect(P("stupidity")).toBe(p)
  end)
end)

describe("one reset for the target's balances (ataxia_resetTargetBals, 016)", function()
  local TRG = "src_new/triggers/levi_ataxia/for_levi/leviticus/"
  local SITES = {
    "src_new/scripts/levi_ataxia/levi/ataxia/login/001_Login_Function.lua",
    "src_new/scripts/levi_ataxia/levi/levi_scripts/mage/006_Target_Priority.lua",
    TRG .. "401_Target_Has_Died.lua",
    TRG .. "405_Starburst!.lua",
  }
  local function read(path)
    local fh = assert(io.open(path, "r"))
    local src = fh:read("*a"); fh:close()
    return src
  end
  -- How many running timers write this field of tBals.
  local function timersWriting(field)
    local n = 0
    for _, t in pairs(mock.active_timers) do
      if type(t.callback) == "string" and t.callback:find("tBals." .. field .. " = true", 1, true) then n = n + 1 end
    end
    return n
  end
  local function isFullShape()
    for _, k in ipairs({ "tree", "focus", "plant", "salve", "passive" }) do
      if tBals[k] ~= true then error("tBals." .. k .. " should be true but is " .. tostring(tBals[k]), 2) end
    end
    expect(next(tBals.timers)).toBeNil()
  end
  -- The old target's tree and focus are down, with both timers running.
  local function oldTargetDown()
    world()
    tree()
    line = "A look of extreme focus crosses the face of Agathon."
    matches = { line, "Agathon" }
    body(TRG .. "398_Focus_(UNK).lua")()
    expect(timersWriting("tree")).toBe(1)
    expect(timersWriting("focus")).toBe(1)
  end

  it("kills every running timer and restores the whole shape", function()
    oldTargetDown()
    ataxia_resetTargetBals()
    expect(timersWriting("tree")).toBe(0)
    expect(timersWriting("focus")).toBe(0)
    isFullShape()
  end)

  it("the old target's 13 s tree timer cannot mark the new target's tree up early", function()
    oldTargetDown()
    ataxia_resetTargetBals()
    target = "Brunhild"
    isTargeted = function(n) return n == "Brunhild" end
    line = "Brunhild touches a tree of life tattoo."
    matches = { line, "Brunhild" }
    TREE_BODY()
    expect(tBals.tree).toBeFalse()
    expect(timersWriting("tree")).toBe(1)        -- his, alone
  end)

  -- The focus knocks start the same kind of timer, so an old target's knock must not free the new
  -- target's focus clock.
  describe("the focus knocks name their timer", function()
    local KNOCKS = {
      { "homunculus", TRG .. "homunculus/001_Focus_Knock.lua", 2.3 },
      { "water lord", TRG .. "water_lord/011_++_Focus_Knock_++.lua", 2 },
    }
    local function knock(path)
      local saved = deselect
      deselect = function() end
      matches = { "the knock line", "Agathon" }
      body(path)()
      deselect = saved
    end
    for _, k in ipairs(KNOCKS) do
      it(k[1] .. ": the reset kills it", function()
        world()
        knock(k[2])
        expect(tBals.focus).toBeFalse()
        expect(timersWriting("focus")).toBe(1)
        expect(mock.active_timers[tBals.timers.focus].delay).toBe(k[3])
        ataxia_resetTargetBals()
        expect(timersWriting("focus")).toBe(0)
      end)

      it(k[1] .. ": when it runs it marks the focus up and drops its id", function()
        world()
        knock(k[2])
        expect(tBals.timers.focus ~= nil).toBeTrue()
        mock.fire_timers()
        expect(tBals.focus).toBeTrue()
        expect(tBals.timers.focus).toBeNil()
      end)
    end

    it("homunculus: a knock replaces a running focus clock, so one timer stays", function()
      world()
      line = "A look of extreme focus crosses the face of Agathon."
      matches = { line, "Agathon" }
      body(TRG .. "398_Focus_(UNK).lua")()
      knock(TRG .. "homunculus/001_Focus_Knock.lua")
      expect(timersWriting("focus")).toBe(1)
    end)

    it("homunculus under shadowmadness keeps its 5 s", function()
      world()
      tarAffed("shadowmadness")
      knock(TRG .. "homunculus/001_Focus_Knock.lua")
      expect(mock.active_timers[tBals.timers.focus].delay).toBe(5)
    end)
  end)

  it("is safe with no table and with no timers", function()
    world()
    tBals = nil
    ataxia_resetTargetBals()
    isFullShape()
    tBals = {}                                   -- 016's own load-order case (test_tekura6_kai)
    ataxia_resetTargetBals()
    isFullShape()
  end)

  -- Both triggers dropped salve and passive, so "not tBals.salve" read true (dwc_runie, 033).
  local function deathLineResets(path, text)
    oldTargetDown()
    ataxia_paused = function() return false end
    ataxia_isClass = function() return false end
    twohanded_resetFractures, expandAlias = function() end, function() end
    shikudo = nil
    line = text
    matches = { text, "Agathon" }
    body(path)()
    isFullShape()
    expect(timersWriting("tree")).toBe(0)
    expect(timersWriting("focus")).toBe(0)
  end

  it("trigger 401 (the target died) keeps salve and passive, and kills the timers", function()
    deathLineResets(TRG .. "401_Target_Has_Died.lua", "You have slain Agathon.")
  end)

  it("trigger 405 (starburst) keeps salve and passive, and kills the timers", function()
    deathLineResets(TRG .. "405_Starburst!.lua", "A starburst tattoo flares and bathes Agathon in red light.")
  end)

  it("no site replaces tBals by hand: 016 holds the only literal", function()
    for _, path in ipairs(SITES) do
      local src = read(path)
      if src:find("tBals = {", 1, true) then error(path .. " replaces tBals by hand") end
      if not src:find("ataxia_resetTargetBals()", 1, true) then error(path .. " does not call the helper") end
    end
    local _, literals = read("src_new/scripts/levi_ataxia/levi/ataxia/016_Targeting_Functions.lua"):gsub("tBals = {", "")
    expect(literals).toBe(1)
  end)

  it("the basher's load-time seed has the same shape", function()
    local src = read("src_new/scripts/levi_ataxia/levi/ataxia/basher/001_Bashing_Functions.lua")
    local seed = assert((loadstring or load)("return " .. src:match("tBals = tBals or (%b{})")))()
    world()
    ataxia_resetTargetBals()
    for k in pairs(seed) do if tBals[k] == nil then error("the helper has no " .. k) end end
    for k in pairs(tBals) do if seed[k] == nil then error("the seed has no " .. k) end end
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
