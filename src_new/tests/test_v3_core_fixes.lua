--- test_v3_core_fixes.lua -- the V3 tracker faults of the 2026-11-08 deep review (group B)
--
-- Each describe block is one finding. The tests drive the REAL trigger bodies (herbs, smoke,
-- salves, Dragonheal, the priest's dazzle, the coating lines) through the REAL public API (016,
-- 017), the REAL tree and passive pools (curing/002, 008) and the REAL V3 tracker (007, 008).
-- Fight-log lines are verbatim, cited as <log>:<row>. Every global the loaded files create or
-- change is restored at the end (one shared Lua state for all test files).

local mock = require("mock_mudlet")
local before = {}
for k, v in pairs(_G) do before[k] = v end
local savedContains, savedStarts, savedTitle = table.contains, string.starts, string.title

-- The V3 files initialise these as `X = X or {...}`. Clear them, so the loads build fresh tables.
for _, k in ipairs({ "afflictionStatesV3", "affConfigV3", "simpleAffsV3", "affCacheV3", "targetBurningLevelV3",
  "affLastConfirmedV3", "targetDefensesV3", "cureBalancesV3", "cureBalanceTimerIDsV3", "passiveCooldownsV3",
  "negativeConfirmTimersV3", "tAffsV2", "tAffStacksV2" }) do
  _G[k] = nil
end
ataxiaTemp, tAffs, affTimers = {}, {}, {}

for _, f in ipairs({
  "src_new/scripts/levi_ataxia/levi/ataxia/016_Targeting_Functions.lua",
  "src_new/scripts/levi_ataxia/levi/ataxia/017_Affliction_Management.lua",
  "src_new/scripts/levi_ataxia/levi/ataxia/update_stuff/001_ataxia_Players_Update.lua",
  "src_new/scripts/levi_ataxia/levi/ataxia/curing/002_Wide_Groups.lua",
  "src_new/scripts/levi_ataxia/levi/ataxia/affliction_tracking_core/007_Branching_State_Tracker.lua",
  "src_new/scripts/levi_ataxia/levi/ataxia/affliction_tracking_core/008_V3_Integration.lua",
}) do
  local ok, err = pcall(dofile, f)
  if not ok then error("Failed to load " .. f .. ": " .. tostring(err)) end
end
-- The real isTargeted (016). world() puts in an exact-name stub; the F42 tests use this one.
local realIsTargeted = isTargeted

-- Mudlet extensions the loaded code uses; restored at the end.
table.contains = table.contains or function(t, v)
  for _, x in pairs(t) do if x == v then return true end end
  return false
end
string.starts = string.starts or function(s, p) return s:sub(1, #p) == p end
string.title = string.title or function(s) return s:sub(1, 1):upper() .. s:sub(2) end

local LEVI = "src_new/triggers/levi_ataxia/for_levi/leviticus/"
local function body(path)
  local fh = assert(io.open(LEVI .. path, "r"))
  local src = fh:read("*a"); fh:close()
  return assert((loadstring or load)(src:match("%]%]%-%-\r?\n(.*)$")))
end
local KELP, BLOODROOT = body("herbs/003_Kelp_(Unknown).lua"), body("herbs/005_Bloodroot_TEST.lua")
local SMOKE, HEAD, LIMBS, SALVES = body("390_Smoked.lua"), body("392_Applied_Head.lua"),
  body("395_Applied_Limbs.lua"), body("396_Salves.lua")
local DRAGONHEAL, DAZZLE = body("passive_active/005_Dragonheal.lua"), body("priest/003_Dazzle.lua")
local GOT_SILERIS, SILERIS_TRUE = body("442_Got_Sileris.lua"), body("707_Sileris_True.lua")

local SAIBEL = "kb/raw/logs/ours/2026-11-07_164635_Saibel.log"
local FCE = "kb/raw/logs/2026-10-11_mystor_shikudo-vs-infernal-dwc_win_FceAmb0o.txt"

-- The world the triggers run in. Only what the loaded files do not provide is stubbed.
local now, events, echoes, timersOn = 1000, {}, {}, {}
local function world(who)
  now, events, echoes, timersOn = 1000, {}, {}, {}
  mock.reset()                          -- no timer from an earlier test may fire into this one
  getEpoch = function() return now end
  target = who or "Saibel"
  isTargeted = function(n)
    return type(n) == "string" and type(target) == "string" and n:lower() == target:lower()
  end
  raiseEvent = function(e, a) events[#events + 1] = { e, a } end
  checkTargetLocks = function() end     -- curing/003, not loaded
  ataxiaEcho = function(s) echoes[#echoes + 1] = s end
  zgui, cecho, fg, selectString, resetFormat = nil, function() end, function() end, function() end, function() end
  predictBal, ataxia_boxEcho, target_salveBal, target_appliedTo = function() end, function() end,
    function() end, function() end
  enableTimer = function(n) timersOn[n] = true; return true end
  disableTimer = function(n) timersOn[n] = false; return true end
  Algedonic = { Echo = function() end }
  confirmAffV2, onTargetSmokeV2, onTargetBloodrootV2, onTargetSalveLimbsV2 = nil, nil, nil, nil
  ataxia = { playersHere = { target }, settings = { separator = "|" } }
  ataxiaTemp = { tarAffTimers = {}, crushedCheck = { pending = false, lastApply = 0 }, class = "Serpent" }
  tAffs, affTimers, lb = {}, {}, nil
  tBals = { tree = true, focus = true, plant = true, salve = true, passive = true, timers = {} }
  serpent, strikingHigh, tdeliverance, anorexiaFailsafe, passiveFailsafe = nil, nil, nil, nil, nil
  lastKelp, lastKelpAffs, kelpDisambiguateTimer, salveChargedAtV3 = nil, nil, nil, nil
  magi = { offense = { state = { burns = 0 } } }
  affConfigV3.enabled, affConfigV3.debugEcho = true, true
  resetStatesV3()
end

-- One game line through one trigger body: matches[2] is the name, as the patterns capture it.
local function run(chunk, text, ...)
  line = text
  matches = { text, ... }
  chunk()
end

local P = function(a) return getAffProbabilityV3(a) end
local function near(got, want, what)
  if math.abs(got - want) > 1e-9 then
    error(string.format("%s: expected %.6f but got %.6f", what, want, got), 2)
  end
end
local function sum(affs)
  local s = 0
  for _, a in ipairs(affs) do s = s + P(a) end
  return s
end
-- The afflictions reported cured ("target cured aff", raised by erAff in 017), in order.
local function cured()
  local out = {}
  for _, ev in ipairs(events) do
    if ev[1] == "target cured aff" then out[#out + 1] = ev[2] end
  end
  return out
end
local function echoed(text)
  for _, s in ipairs(echoes) do
    if s:find(text, 1, true) then return true end
  end
  return false
end

local ok, err = pcall(function()
describe("F2: a negative-confirm timeout keeps the cure (no unfold)", function()
  it("a magnesium eat over paralysis and slickness still took one of them after 1.3 s", function()
    world()
    tarAffed("paralysis", "slickness", "asthma")
    run(BLOODROOT, "Saibel eats a magnesium chip.", "Saibel", "magnesium chip")   -- SAIBEL:1241
    near(P("paralysis"), 1 / 3, "paralysis after the eat")
    expect(negativeConfirmTimersV3.herb_negconf ~= nil).toBeTrue()
    mock.fire_timers()                   -- the 1.3 s window closes with no second cure
    near(P("paralysis"), 1 / 3, "paralysis after the window")        -- the unfold made it 1
    near(P("slickness"), 2 / 3, "slickness after the window")
    expect(echoed("branch kept: ")).toBeTrue()
  end)

  -- SAIBEL:2054 and :2057. The smoke proves asthma absent; the eat's 1.3 s window had nothing to
  -- close it (a smoke that only collapses is no cure, deep review U-007:556), and its unfold put
  -- asthma back at 1.00 in the replay.
  it("an aurum eat then a smoke: asthma stays gone when the eat's window closes", function()
    world()
    tarAffed("asthma", "weariness", "disloyalty", "slickness")
    run(KELP, "Saibel eats an aurum flake.", "Saibel", "an aurum flake")
    now = now + 0.004
    run(SMOKE, "Saibel takes a long drag off her pipe.", "Saibel")
    expect(P("asthma")).toBe(0)
    near(P("weariness"), 1, "weariness after the smoke")
    near(P("disloyalty") + P("slickness"), 1, "the smoke took one of disloyalty and slickness")
    mock.fire_timers()                   -- the herb (1.3 s) and smoke (2.0 s) windows close
    expect(P("asthma")).toBe(0)
    expect(tAffs.asthma).toBeFalse()
    near(P("weariness"), 1, "weariness after the windows")
    near(P("disloyalty") + P("slickness"), 1, "disloyalty + slickness after the windows")
  end)
end)

describe("F12: a cure that leaves every branch under 1% keeps the branches", function()
  local TEN = { "clumsiness", "weariness", "asthma", "nausea", "stupidity", "dizziness", "shyness",
    "epilepsy", "addiction", "hypochondria" }

  it("Dragonheal (three cures) over ten afflictions keeps the pinshot and seven afflictions", function()
    world("Xylarys")
    tarAffed("pinshot", unpack(TEN))
    -- kb/raw/logs/2026-11-03_shikudo-group-alias-2.txt:1562
    run(DRAGONHEAL, "Xylarys lets out a great keening, casting the impurities from his form.", "Xylarys")
    near(P("pinshot"), 1, "pinshot")     -- 0 before: C(10,3) = 120 branches at 1/120, all pruned
    expect(tAffs.pinshot).toBeTrue()
    near(sum(TEN), 7, "the ten afflictions after three cures")
    expect(#afflictionStatesV3 <= affConfigV3.maxStates).toBeTrue()
    -- Each one, not only the sum: equal branches cut at 50 read 0.90, 0.56 and 0.98 for these.
    for _, a in ipairs(TEN) do near(P(a), 0.7, a) end
  end)

  it("three trees over ten afflictions do the same", function()
    world()
    tarAffed("pinshot", unpack(TEN))
    for i = 1, 3 do
      now = now + 14                     -- past the 13 s tree clock
      ataxia_targetTreeV3()
    end
    near(P("pinshot"), 1, "pinshot")
    expect(tAffs.pinshot).toBeTrue()
    near(sum(TEN), 7, "the ten afflictions after three trees")
    for _, a in ipairs(TEN) do near(P(a), 0.7, a) end
  end)

  it("a fourth tree over ten still reads even (210 branches at 1/210)", function()
    world()
    tarAffed("pinshot", unpack(TEN))
    for i = 1, 4 do
      now = now + 14
      ataxia_targetTreeV3()
    end
    expect(#afflictionStatesV3).toBe(210)
    for _, a in ipairs(TEN) do near(P(a), 0.6, a) end
  end)

  -- 84 branches at 0.0119, none under the floor, so the keep-all path is not what gets here: this
  -- is the board's own count against the cap. The nine are the candidates the live client printed
  -- at kb/raw/logs/2026-11-03_shikudo-group-alias-2.txt:1562-1563.
  it("nine afflictions after three cures keep every branch", function()
    local NINE = { "weariness", "stupidity", "anorexia", "impatience", "confusion", "slickness", "asthma",
      "healthleech", "clumsiness" }
    world("Xylarys")
    tarAffed(unpack(NINE))
    run(DRAGONHEAL, "Xylarys lets out a great keening, casting the impurities from his form.", "Xylarys")
    expect(#afflictionStatesV3).toBe(84)
    for _, a in ipairs(NINE) do near(P(a), 6 / 9, a) end
  end)

  it("a package reload over a running session takes the cap", function()
    local kept = affConfigV3
    affConfigV3 = { enabled = true, minProbability = 0.01, maxStates = 50, debugEcho = true }
    local fine, e = pcall(dofile,
      "src_new/scripts/levi_ataxia/levi/ataxia/affliction_tracking_core/007_Branching_State_Tracker.lua")
    local cap = affConfigV3.maxStates
    affConfigV3 = kept
    if not fine then error(e, 0) end
    expect(cap).toBe(300)
  end)
end)

describe("F15: the passive pool is the game's random-cure pool", function()
  it("holds every tree-curable affliction, and pacified, not pacifism", function()
    local pool = {}
    for _, a in ipairs(passiveCurableAffsV3) do pool[a] = true end
    for _, a in ipairs(treeCurableAffsV3) do
      if not pool[a] then error("passive pool misses " .. a) end
    end
    expect(pool.pacified).toBeTrue()
    expect(pool.pacifism).toBeNil()
    expect(passiveCurableAffsV3[1]).toBe("voyria")
  end)

  it("one passive cure over masochism and asthma splits evenly (it always took the asthma)", function()
    world()
    tarAffed("masochism", "asthma")
    onClassCureV3(nil, 1)
    near(P("masochism"), 0.5, "masochism")
    near(P("asthma"), 0.5, "asthma")
  end)
end)

describe("F38 / X2: the application line closes the guess, and 396 does not charge it again", function()
  -- FCE:3152 and :3154
  it("an arms application after a branched aurum eat closes the eat's window, with no ILLUSION", function()
    world("Agathon")
    tarAffed("weariness", "clumsiness")
    run(KELP, "Agathon eats an aurum flake.", "Agathon", "an aurum flake")
    expect(negativeConfirmTimersV3.herb_negconf ~= nil).toBeTrue()
    now = now + 0.5
    local text = "Agathon takes some salve from a vial and rubs it on his arms."
    run(LIMBS, text, "Agathon", "arms")
    run(SALVES, text, "Agathon")         -- the same line, after 395 (folder order)
    expect(negativeConfirmTimersV3.herb_negconf).toBeNil()
    expect(echoed("ILLUSION")).toBeFalse()
  end)

  it("a branched head application keeps its own window through 396", function()
    world("Agathon")
    tarAffed("stuttering", "concussion")
    local text = "Agathon takes some salve from a vial and rubs it on his head."
    run(HEAD, text, "Agathon")
    expect(negativeConfirmTimersV3.salve_negconf ~= nil).toBeTrue()
    run(SALVES, text, "Agathon")
    expect(negativeConfirmTimersV3.salve_negconf ~= nil).toBeTrue()
    expect(echoed("ILLUSION")).toBeFalse()
  end)

  it("a second application inside the salve clock is still an illusion", function()
    world("Agathon")
    local text = "Agathon takes some salve from a vial and rubs it on his torso."
    run(SALVES, text, "Agathon")
    now = now + 0.3
    run(SALVES, text, "Agathon")
    expect(echoed("[V3] ILLUSION: target applied salve while on salve balance")).toBeTrue()
  end)
end)

describe("X3: the ILLUSION lines print", function()
  it("a second tree inside the 13 s clock prints [V3] ILLUSION", function()
    world()
    tarAffed("clumsiness", "weariness")
    ataxia_targetTreeV3()
    now = now + 5
    ataxia_targetTreeV3()
    expect(echoed("[V3] ILLUSION: target used tree while on tree balance")).toBeTrue()
  end)

  it("nothing is left that calls ataxia.decho", function()
    local fh = assert(io.open("src_new/scripts/levi_ataxia/levi/ataxia/affliction_tracking_core/008_V3_Integration.lua"))
    local src = fh:read("*a"); fh:close()
    expect(src:find("ataxia.decho(", 1, true)).toBeNil()
  end)
end)

describe("F39: a certain impatience blocks the focus, whatever the float sum says", function()
  it("kelp, bloodroot and kelp leave impatience in every branch at a sum under 1", function()
    world()
    tarAffed("impatience", "weariness", "asthma", "clumsiness", "sensitivity", "healthleech",
      "paralysis", "slickness", "parasite")
    for _, h in ipairs({ "kelp", "bloodroot", "kelp" }) do
      now = now + 2
      onHerbCureV3(h)
    end
    expect(P("impatience") < 1).toBeTrue()          -- 0.99999999999999978
    expect(isAffCertainV3("impatience")).toBeTrue()
    now = now + 2
    onTargetFocusV3()
    expect(isAffCertainV3("impatience")).toBeTrue()  -- the focus stripped it before
    expect(P("impatience") > 0.99).toBeTrue()
  end)

  it("is false when one branch lacks it, and true for a simple-tracked affliction", function()
    world()
    afflictionStatesV3 = { { affs = { impatience = true }, prob = 0.5 }, { affs = {}, prob = 0.5 } }
    rebuildCacheV3()
    expect(isAffCertainV3("impatience")).toBeFalse()
    simpleAffsV3.prone = true
    expect(isAffCertainV3("prone")).toBeTrue()
  end)
end)

describe("F40: a tree proves paralysis absent", function()
  it("a 25% paralysis takes no share of the tree and is gone after it", function()
    world()
    afflictionStatesV3 = {
      { affs = { paralysis = true, clumsiness = true }, prob = 0.25 },
      { affs = { clumsiness = true }, prob = 0.75 },
    }
    rebuildCacheV3()
    ataxia_targetTreeV3()
    expect(P("paralysis")).toBe(0)
    expect(P("clumsiness")).toBe(0)      -- the tree's only candidate in both branches
  end)
end)

describe("F41: dazzled goes in under the game's name, so the cures can take it", function()
  local LINE = "Agathon reels as the beam strikes, dazzled and confused."   -- priest/003's pattern
  it("priest/003 gives dazzled", function()
    world("Agathon")
    run(DAZZLE, LINE, "Agathon")
    expect(P("dazzled")).toBe(1)
    expect(P("dazzle")).toBe(0)
  end)

  it("priest/003 names dazzled itself", function()
    world("Agathon")
    local given
    local real = ataxia_tarAffTimed
    ataxia_tarAffTimed = function(a) given = a end
    local ok, err = pcall(run, DAZZLE, LINE, "Agathon")
    ataxia_tarAffTimed = real
    assert(ok, err)
    expect(given).toBe("dazzled")
  end)

  it("a tree over dazzled and asthma splits evenly (dazzle was never a candidate)", function()
    world("Agathon")
    run(DAZZLE, LINE, "Agathon")
    tarAffed("asthma")
    ataxia_targetTreeV3()
    near(P("dazzled"), 0.5, "dazzled")
    near(P("asthma"), 0.5, "asthma")
  end)

  it("a head application cures it", function()
    world("Agathon")
    run(DAZZLE, LINE, "Agathon")
    run(HEAD, "Agathon takes some salve from a vial and rubs it on his head.", "Agathon")
    expect(P("dazzled")).toBe(0)
  end)
end)

describe("U-002:230: a tree reports only what the tracker held", function()
  -- SAIBEL:1059, replayed: asthma at 0.02 and not in tAffs, clumsiness certain.
  it("a 2% asthma the tree pushed under 1% leaves without a report", function()
    world()
    afflictionStatesV3 = {
      { affs = { clumsiness = true }, prob = 0.98 },
      { affs = { clumsiness = true, asthma = true, weariness = true }, prob = 0.02 },
    }
    rebuildCacheV3()
    tAffs.clumsiness = true
    ataxia_targetTreeV3()
    expect(P("asthma")).toBe(0)
    expect(P("weariness")).toBe(0)
    local got = cured()
    expect(#got).toBe(1)
    expect(got[1]).toBe("clumsiness")
  end)

  it("the passive cure does the same", function()
    world()
    afflictionStatesV3 = {
      { affs = { clumsiness = true }, prob = 0.98 },
      { affs = { clumsiness = true, asthma = true, weariness = true }, prob = 0.02 },
    }
    rebuildCacheV3()
    tAffs.clumsiness = true
    onClassCureV3(nil, 1)
    local got = cured()
    expect(#got).toBe(1)
    expect(got[1]).toBe("clumsiness")
  end)
end)

describe("F42 / H3: a part name is completed, a full name is never renamed", function()
  local function real(t, here)
    world(t)
    gmcp = {}
    isTargeted = realIsTargeted
    ataxia.playersHere = here
  end

  -- A gmcp.Room.Players through the real handler (update_stuff/001). It rebuilds
  -- ataxia.playersHere one name at a time and asks isTargeted as it goes, so a list is half built
  -- when the first names are asked about.
  local function enterRoom(t, names)
    real(t, {})
    -- isTargeted keeps the last full name in a local, and an earlier test may have left this one.
    target = "Nobody"
    realIsTargeted("Nobody")
    target = t
    ataxiaBasher, ataxiagui = { ignore = {} }, {}
    targetIshere = false
    timersOn.TargetOutOfRoom = true
    local list = {}
    for i, n in ipairs(names) do list[i] = { name = n, fullname = n } end
    gmcp = { Char = { Status = { name = "Levi" } }, Room = { Players = list } }
    ataxia_Players_Update("gmcp.Room.Players")
  end

  it("Room.Players lists Kaiden before Kai: target Kai stays Kai and is here", function()
    enterRoom("Kai", { "Kaiden", "Kai" })
    expect(target).toBe("Kai")
    expect(targetIshere).toBeTrue()
    expect(timersOn.TargetOutOfRoom).toBeFalse()
  end)

  it("Room.Players lists Kai before Kaiden: the same, whatever order GMCP sends", function()
    enterRoom("Kai", { "Kai", "Kaiden" })
    expect(target).toBe("Kai")
    expect(targetIshere).toBeTrue()
    expect(timersOn.TargetOutOfRoom).toBeFalse()
  end)

  it("Room.Players lists only Saibel: `t sai` is still completed", function()
    enterRoom("sai", { "Saibel" })
    expect(target).toBe("Saibel")
    expect(targetIshere).toBeTrue()
    expect(timersOn.TargetOutOfRoom).toBeFalse()
  end)

  it("a name the last Room.Players listed is a full name, even off ataxia.playersHere", function()
    real("Kai", {})
    target = "Nobody"
    realIsTargeted("Nobody")
    target = "Kai"
    gmcp = { Room = { Players = { { name = "Kai", fullname = "Kai" } } } }
    expect(isTargeted("Kaiden")).toBeFalse()
    expect(target).toBe("Kai")
  end)

  it("target Kaiden: Kai's line is not his, and the target stays Kaiden", function()
    real("Kaiden", { "Kaiden", "Kai" })
    expect(isTargeted("Kai")).toBeFalse()
    expect(target).toBe("Kaiden")
  end)

  it("target Kai, listed: Kaiden's line is not hers", function()
    real("Kai", { "Kai", "Kaiden" })
    expect(isTargeted("Kaiden")).toBeFalse()
    expect(target).toBe("Kai")
  end)

  it("target Kai, not listed, once a line has named Kai: Kaiden's line is not hers", function()
    real("Kai", {})
    expect(isTargeted("Kai")).toBeTrue()
    expect(isTargeted("Kaiden")).toBeFalse()
    expect(target).toBe("Kai")
  end)

  it("`t sai` with Saibel listed: her line completes the name, case ignored", function()
    real("sai", { "Saibel" })
    expect(isTargeted("Saibel")).toBeTrue()
    expect(target).toBe("Saibel")
    expect(isTargeted("saibel")).toBeTrue()
    expect(isTargeted("Sai")).toBeFalse()
  end)

  it("a name that is not a string is never the target", function()
    real("Saibel", { "Saibel" })
    expect(isTargeted(nil)).toBeFalse()
    expect(isTargeted(12)).toBeFalse()
  end)
end)

describe("F21: switching target stops the old chase and reads the new target's presence", function()
  local function switch(name)
    matches = { "t " .. name, name }
    switchTarget(name)
  end
  local function stubs()
    setafflictionstackslevi = function() end
    ataxia_isClass = function() return false end
    twohanded_resetFractures = function() end
    gmcp = { Char = { Status = { class = "Serpent" } } }
    ataxiaBasher, pariah = nil, nil
  end

  it("a listed new target: the timer is off and she is here", function()
    world("Kaiden")
    stubs()
    ataxia.playersHere = { "Saibel" }
    timersOn.TargetOutOfRoom = true
    targetIshere = false
    switch("saibel")
    expect(target).toBe("Saibel")
    expect(timersOn.TargetOutOfRoom).toBeFalse()
    expect(targetIshere).toBeTrue()
  end)

  it("a new target not listed: not here (it kept the old target's true)", function()
    world("Kaiden")
    stubs()
    ataxia.playersHere = { "Kaiden" }
    targetIshere = true
    switch("saibel")
    expect(targetIshere).toBeFalse()
    expect(timersOn.TargetOutOfRoom).toBeFalse()
  end)
end)

describe("F23: no coating is assumed on a new target", function()
  it("the reset leaves fangbarrier and sileris false", function()
    world()
    targetresetafflictionslevi()
    expect(tAffs.fangbarrier).toBeFalse()
    expect(tAffs.sileris).toBeFalse()
    expect(tAffs.rebounding).toBeTrue()  -- the opening flay of the assumed rebounding is unchanged
  end)

  it("the shell forming sets the coating", function()
    world("Agathon")
    targetresetafflictionslevi()
    -- kb/raw/logs/2026-10-11_mystor_shikudo-vs-infernal-dwc_win_c.iJVmpL.txt:1465
    local text = "A supple metallic shell of quicksilver has formed around Agathon."
    run(GOT_SILERIS, text, "Agathon")
    expect(tAffs.fangbarrier).toBeTrue()
    expect(tAffs.sileris).toBeTrue()
  end)

  it("a bite the coating stops sets it", function()
    world("Agathon")
    targetresetafflictionslevi()
    -- 707's pattern; no log has the line yet.
    run(SILERIS_TRUE, "You try to bite Agathon, but your fangs are stopped by an odd metallic coating.", "Agathon")
    expect(tAffs.fangbarrier).toBeTrue()
  end)
end)
end)

table.contains, string.starts, string.title = savedContains, savedStarts, savedTitle
for k in pairs(_G) do
  if before[k] == nil then _G[k] = nil end
end
for k, v in pairs(before) do _G[k] = v end
if not ok then error(err) end
