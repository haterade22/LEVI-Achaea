--- test_shikudo_offense.lua -- the live Shikudo offense (006 dispatch, 007 lock), phase 2 (v4.7.417)
-- and the lock offense's rework (v4.7.420: Mystor's route, KAI CHOKE kill, Telepathy as its own round).
-- Loads the REAL scripts, monk/004 (kai, kata, ASSESS) first. Every global they create or change is
-- restored at the end (one shared Lua state for all test files).

local before = {}
for k, v in pairs(_G) do before[k] = v end

local SH = "src_new/scripts/levi_ataxia/levi/levi_scripts/shikudo/"
local KAIKATA = "src_new/scripts/levi_ataxia/levi/ataxia/monk/004_Kai_And_Kata.lua"
ataxia = { vitals = {}, settings = {}, balances = {} }
ataxiaTemp = {}
tAffs = {}
target = "Agathon"
cecho = function() end
-- A clock we move by hand (monk/004 reads getEpoch for ASSESS age and the kata lapse).
local now = 1000
getEpoch = function() return now end
-- Both offenses read target afflictions through haveAff (V3); here it reads the tAffs a test sets.
-- An earlier test file may have left its own haveAff behind, so this one is always installed, and
-- so is the class reader 007's Apostate skip uses.
haveAff = function(aff) return tAffs ~= nil and tAffs[aff] and true or false end
local targetClass = "Unknown"
ataxiaNDB_getClass = function() return targetClass end
combatQueue = function() return "" end
lb = {}
for _, f in ipairs({ KAIKATA, SH .. "006_CC_Shikudo_Dispatch.lua", SH .. "007_CC_Shikudo_Lock.lua" }) do
  local ok, err = pcall(dofile, f)
  if not ok then error("Failed to load " .. f .. ": " .. tostring(err)) end
end

describe("the lock offense's Telepathy (007)", function()
  local function pick(eq, affs, form)
    ataxia.vitals = { eq = eq, form = form or "Oak" }
    tAffs = affs or {}
    mindlocked = false
    return shikudoLock.selectTelepathy()
  end

  it("sends MIND commands whatever equilibrium reads at the press, and needs no lock first", function()
    local soft = { asthma = true, anorexia = true, slickness = true }
    expect(pick(true, soft)).toBe("mind impatience Agathon")
    expect(pick(true, { asthma = true, anorexia = true, slickness = true, impatience = true }))
      .toBe("mind paralyse Agathon")
    expect(pick(true, {})).toBeNil()
    expect(pick(true, {}, "Rain")).toBe("mind impatience Agathon")
    expect(pick(true, { paralysis = true })).toBeNil()
    -- The `free` queue waits for equilibrium whatever the round is (HELP 4.6.1).
    expect(pick(false, soft)).toBe("mind impatience Agathon")
  end)

  it("never sends the old bare words, and never MIND BATTER", function()
    local pool = { "asthma", "anorexia", "slickness", "impatience", "paralysis", "disrupted" }
    for _, form in ipairs({ "Rain", "Oak", "Willow" }) do
      for mask = 0, 2 ^ #pool - 1 do
        local affs = {}
        for i, a in ipairs(pool) do
          if math.floor(mask / 2 ^ (i - 1)) % 2 == 1 then affs[a] = true end
        end
        local c = pick(true, affs, form)
        if c then
          expect(c:find("^mind ") ~= nil).toBeTrue()
          expect(c:find("mindlock", 1, true)).toBeNil()
          expect(c:find("batter", 1, true)).toBeNil()
        end
      end
    end
  end)
end)

describe("Crescent reads the ASSESS health (006)", function()
  -- Both readings: the floored percentage (lastAssess) the v4.7.417 006 reads, and the raw numbers,
  -- time and name (698) that ataxia_assessAtMostHalf reads, so this holds for either 006.
  local function assessed(pct, hp)
    ataxiaTemp = { lastAssess = pct, lastAssessHp = hp, lastAssessMax = 7000,
      lastAssessAt = getEpoch(), lastAssessWho = "Agathon" }
  end

  it("fires on a prone target at 50% or less, from a fresh ASSESS", function()
    ataxia.vitals = { form = "Maelstrom" }
    tAffs = { prone = true }
    assessed(40, 2800)
    expect(shikudo.selectKick()).toBe("crescent")
    assessed(60, 4200)
    expect(shikudo.selectKick() ~= "crescent").toBeTrue()
  end)
end)

describe("a refused transition keeps the kata (shikudo/002)", function()
  it("does not zero the count", function()
    local fh = assert(io.open("src_new/triggers/levi_ataxia/for_levi/leviticus/shikudo/002_Reset_Failsafe.lua", "r"))
    local body = fh:read("*a"):match("%]%]%-%-\r?\n(.*)$")
    fh:close()
    ataxia.vitals = { kata = 3 }
    assert((loadstring or load)(body))()
    expect(ataxia.vitals.kata).toBe(3)
  end)
end)

-- ---------------------------------------------------------------------------------------------
-- The lock offense, reworked (007, v4.7.420)
-- ---------------------------------------------------------------------------------------------

-- Every 007 test starts from a clean round history, so no test depends on another's order. That
-- includes runLine: until a run line has matched one of our rounds, a round counts when queued.
local function lockReset()
  shikudoLock.state.lastRound = nil
  shikudoLock.state.mindRun = 0
  shikudoLock.state.prelude = 0
  shikudoLock.state.choking = false
  shikudoLock.state.alt = {}
  shikudoLock.state.roundAlt = {}
  shikudoLock.state.pending = nil
  shikudoLock.state.runLine = false
  shikudoLock.state.phase = "SOFTLOCK"
end

describe("the lock reads kai through monk/004 (007)", function()
  it("KAI CHOKE is affordable at 10 kai, not at 9, and never while kai is unknown", function()
    lockReset()
    ataxia.vitals = { kai = 10 }
    ataxiaTemp = { kaiAt = getEpoch() }
    expect(shikudoLock.canKaiChoke()).toBeTrue()
    expect(shikudoLock.kaiLabel()).toBe("<green>10 KAI CHOKE READY")
    ataxia.vitals.kai = 9
    expect(shikudoLock.canKaiChoke()).toBeFalse()
    -- No stamp this session: a kai restored from disk is not a reading (the v4.7.299 rule).
    ataxia.vitals.kai = 95
    ataxiaTemp = {}
    expect(shikudoLock.canKaiChoke()).toBeFalse()
    expect(shikudoLock.kaiLabel()).toBe("<yellow>?")
  end)
end)

-- The afflictions a test names, as a set.
local function set(...)
  local t = {}
  for _, a in ipairs({ ... }) do t[a] = true end
  return t
end

describe("the lock route: Oak half first, anorexia last (Mystor, #8)", function()
  local function route(form, kata, affs)
    lockReset()
    ataxia.vitals = { form = form, kata = kata }
    ataxia.settings = {}
    tAffs = affs or {}
    return shikudoLock.shouldTransition()
  end

  it("Oak goes to Willow only with asthma AND slickness on, else to Gaital at 12", function()
    expect(route("Oak", 6, {})).toBeNil()
    expect(route("Oak", 6, set("asthma"))).toBeNil()
    expect(route("Oak", 6, set("asthma", "slickness"))).toBe("Willow")
    expect(route("Oak", 12, {})).toBe("Gaital")
  end)

  it("Oak never goes to Willow with anorexia already on: it holds, then goes round by Gaital", function()
    expect(route("Oak", 6, set("asthma", "slickness", "anorexia"))).toBeNil()
    expect(route("Oak", 9, set("asthma", "slickness", "anorexia", "impatience", "paralysis"))).toBeNil()
    expect(route("Oak", 12, set("asthma", "slickness", "anorexia"))).toBe("Gaital")
  end)

  it("Rain goes to Oak mid-lock, at 10 with the arm prep in, or at its cap of 15", function()
    expect(route("Rain", 6, set("anorexia"))).toBe("Oak")
    expect(route("Rain", 9, set("weariness", "clumsiness"))).toBeNil()
    expect(route("Rain", 10, set("weariness", "clumsiness"))).toBe("Oak")
    expect(route("Rain", 15, {})).toBe("Oak")
  end)

  it("Willow holds while the Oak half holds, and goes back to Rain once it drops", function()
    expect(route("Willow", 9, set("asthma", "slickness", "anorexia"))).toBeNil()
    expect(route("Willow", 6, set("anorexia", "slickness"))).toBe("Rain")
  end)

  it("never goes to Tykonos, whatever the afflictions, and never below a chain of 5", function()
    local pool = { "asthma", "slickness", "anorexia", "paralysis", "impatience", "weariness", "clumsiness" }
    local forms = { "Rain", "Oak", "Willow", "Gaital", "Maelstrom", "Tykonos" }
    for mask = 0, 2 ^ #pool - 1 do
      local affs = {}
      for i, a in ipairs(pool) do
        if math.floor(mask / 2 ^ (i - 1)) % 2 == 1 then affs[a] = true end
      end
      for _, form in ipairs(forms) do
        for _, kata in ipairs({ 5, 10, 15 }) do
          expect(route(form, kata, affs) ~= "Tykonos").toBeTrue()
        end
        expect(route(form, 4, affs)).toBeNil()
      end
    end
  end)
end)

describe("flashheel is a break: kick the leg that is not broken (#3, 007)", function()
  local function kick(form, affs, hits)
    ataxia.vitals = { form = form }
    tAffs = affs or {}
    lb = { Agathon = hits and { hits = hits } or nil }
    return shikudoLock.selectKick(form)
  end

  it("Willow kicks the unbroken leg; with neither broken, asking again gives the same leg", function()
    lockReset()
    expect(kick("Willow", set("brokenleftleg"))).toBe("flashheel right")
    expect(kick("Willow", set("brokenrightleg"))).toBe("flashheel left")
    -- The side alternates per round the game RUNS (the run-line block below), not per call.
    expect(kick("Willow", {})).toBe("flashheel left")
    expect(kick("Willow", {})).toBe("flashheel left")
  end)

  it("Gaital spinkicks a prone target, else flashheels the unbroken leg", function()
    lockReset()
    expect(kick("Gaital", set("prone"))).toBe("spinkick")
    expect(kick("Gaital", set("brokenleftleg"))).toBe("flashheel right")
  end)

  it("Oak kicks the torso, and Rain frontkicks the less damaged arm", function()
    lockReset()
    expect(kick("Oak", {})).toBe("risingkick torso")
    expect(kick("Rain", {}, { ["left arm"] = 10, ["right arm"] = 30 })).toBe("frontkick left")
    expect(kick("Rain", {}, { ["left arm"] = 30, ["right arm"] = 10 })).toBe("frontkick right")
  end)
end)

describe("Crescent needs prone and a fresh ASSESS of half or less (#5, 007)", function()
  local function crescent(affs, hp, age)
    lockReset()
    ataxia.vitals = { form = "Maelstrom" }
    tAffs = affs
    lb = {}
    ataxiaTemp = { lastAssess = math.floor(hp / 70), lastAssessHp = hp, lastAssessMax = 7000,
      lastAssessAt = getEpoch() - (age or 1), lastAssessWho = "Agathon" }
    shikudoLock.updatePhase() -- as dispatch does: a truelock is KILL, which alone is no reason
    return shikudoLock.selectKick("Maelstrom") == "crescent"
  end

  it("fires only on a prone target, at half health or less, read in the last 5 seconds", function()
    expect(crescent(set("prone"), 3000)).toBeTrue()
    expect(crescent({}, 3000)).toBeFalse()
    expect(crescent(set("prone"), 3540)).toBeFalse() -- 50.57%, which the floored reading calls 50
    expect(crescent(set("prone"), 3000, 20)).toBeFalse()
    expect(crescent(set("asthma", "anorexia", "slickness", "paralysis", "impatience", "weariness"), 3000))
      .toBeFalse()
  end)

  it("otherwise Maelstrom kicks the torso", function()
    crescent({}, 3000)
    expect(shikudoLock.selectKick("Maelstrom")).toBe("risingkick torso")
  end)
end)

describe("the lock's combos are Mystor's, and never repeat a strike (007)", function()
  local HITS = { ["left arm"] = 10, ["right arm"] = 30, ["left leg"] = 10, ["right leg"] = 30 }
  local function combo(form, affs)
    lockReset()
    ataxia.vitals = { form = form }
    tAffs = affs or {}
    lb = { Agathon = { hits = HITS } }
    return shikudoLock.buildCombo(form)
  end
  local function count(s, word)
    local n = 0
    for _ in s:gmatch("%f[%a]" .. word .. "%f[%A]") do n = n + 1 end
    return n
  end

  it("Rain: frontkick, kuro and ruku, the kick and the ruku on the same arm", function()
    expect(combo("Rain", {})).toBe("combo $tar frontkick left kuro left ruku left")
    -- With no limb reading the sides alternate per combo, but the kick and the ruku still agree.
    lb = {}
    for _ = 1, 2 do
      local kickArm, rukuArm = shikudoLock.buildCombo("Rain"):match("^combo %$tar frontkick (%a+) kuro %a+ ruku (%a+)$")
      expect(kickArm ~= nil and kickArm == rukuArm).toBeTrue()
    end
  end)

  it("Oak puts on asthma AND slickness in one combo", function()
    local c = combo("Oak", {})
    expect(c).toContain("risingkick torso")
    expect(c).toContain("livestrike")
    expect(c).toContain("ruku torso")
  end)

  it("Willow is one hiraku and one hiru, never a double hiraku", function()
    local c = combo("Willow", set("anorexia"))
    expect(count(c, "hiraku")).toBe(1)
    expect(count(c, "hiru")).toBe(1)
  end)

  it("no form ever sends the same strike twice, whatever is on the target", function()
    local pool = { "asthma", "slickness", "paralysis", "weariness", "clumsiness", "addiction" }
    for _, form in ipairs({ "Rain", "Oak", "Willow", "Gaital", "Maelstrom", "Tykonos" }) do
      for mask = 0, 2 ^ #pool - 1 do
        local affs = {}
        for i, a in ipairs(pool) do
          if math.floor(mask / 2 ^ (i - 1)) % 2 == 1 then affs[a] = true end
        end
        tAffs = affs
        local s1, s2 = shikudoLock.pickStaff(form, "left", "right")
        expect(s1 ~= nil and s2 ~= nil).toBeTrue()
        expect(s1 ~= s2).toBeTrue()
      end
    end
    local m = combo("Maelstrom", set("asthma"))
    expect(m).toBe("combo $tar risingkick torso ruku torso jinzuku")
  end)
end)

describe("Telepathy: impatience before anorexia, paralyse to close it, filler in Rain (007)", function()
  local function pick(affs, form)
    ataxia.vitals = { eq = true, form = form }
    tAffs = affs
    return shikudoLock.selectTelepathy()
  end

  it("impatience is critical as soon as the lock is forming, so FOCUS cannot cure the anorexia", function()
    local cmd, critical = pick(set("asthma"), "Oak")
    expect(cmd).toBe("mind impatience Agathon")
    expect(critical).toBeTrue()
    cmd, critical = pick(set("asthma", "anorexia", "slickness", "impatience"), "Willow")
    expect(cmd).toBe("mind paralyse Agathon")
    expect(critical).toBeTrue()
  end)

  it("the Rain filler is impatience, then paralyse, then disrupt, and is not critical", function()
    local cmd, critical = pick({}, "Rain")
    expect(cmd).toBe("mind impatience Agathon")
    expect(critical).toBeFalse()
    expect(pick(set("impatience"), "Rain")).toBe("mind paralyse Agathon")
    expect(pick(set("impatience", "paralysis"), "Rain")).toBe("mind disrupt Agathon")
    expect(pick(set("impatience", "paralysis", "disrupted"), "Rain")).toBeNil()
  end)

  it("an Apostate gets no filler paralyse, but still the one that closes the lock", function()
    targetClass = "Apostate"
    local ok, err = pcall(function()
      expect(pick(set("impatience"), "Rain")).toBe("mind disrupt Agathon")
      expect(pick(set("asthma", "anorexia", "slickness", "impatience"), "Rain")).toBe("mind paralyse Agathon")
    end)
    targetClass = "Unknown"
    if not ok then error(err, 0) end
  end)

  it("the KILL prelude is confuse, then disrupt", function()
    tAffs = {}
    expect(shikudoLock.selectPrelude()).toBe("mind confuse Agathon")
    tAffs = set("confusion")
    expect(shikudoLock.selectPrelude()).toBe("mind disrupt Agathon")
    tAffs = set("confusion", "disrupted")
    expect(shikudoLock.selectPrelude()).toBeNil()
  end)
end)

-- The real dispatch with `send` captured: the one line it sent, or nil. `send` is put back even
-- when the dispatch throws.
local function dispatchLine()
  local sent, saved = {}, send
  send = function(c) sent[#sent + 1] = c end
  local ok, err = pcall(shikudoLock.dispatch)
  send = saved
  if not ok then error(err, 0) end
  expect(#sent <= 1).toBeTrue()
  return sent[1]
end

-- A fight state for the planner: our form, kata and equilibrium, the target's afflictions, limb
-- readings that make every side "left", and kai 95 seen this session.
local function fight(form, kata, affs, eq)
  lockReset()
  ataxia.vitals = { form = form, kata = kata, eq = eq ~= false, kai = 95 }
  ataxia.settings = { separator = ";" }
  tAffs = affs
  lb = { Agathon = { hits = { ["left arm"] = 10, ["right arm"] = 30, ["left leg"] = 10, ["right leg"] = 30 } } }
  ataxiaTemp = { kaiAt = getEpoch() }
end

local TRUELOCK = { "asthma", "anorexia", "slickness", "paralysis", "impatience", "weariness" }

local TL = dofile("src_new/tests/trigger_lib.lua")
local MOCK = package.loaded["mock_mudlet"] or require("mock_mudlet")

-- The temp triggers registered with the mock under 007's run-line pattern.
local function runTriggers()
  local found = {}
  for _, t in pairs(MOCK.active_triggers) do
    if t.pattern == shikudoLock.RAN_PATTERN then found[#found + 1] = t end
  end
  return found
end

-- The game runs `sent` (a whole "queue addclear free ..." command). It prints "[System]: Running
-- queued free command: <round>" -- upper-cased here, since its case is not known and queue_Scan
-- lower-cases it -- wrapped at `width` (default 120), and the trigger sees the FIRST row: it goes
-- through 007's real pattern (trigger_lib) and its real callback. True when 007 took it as the
-- round it had pending.
local function ran(sent, width)
  local full = "[System]: Running queued free command: " .. (sent:gsub("^queue addclear free ", "")):upper()
  local row = TL.wrap(full, width or 120)[1]
  expect(TL.matches(shikudoLock.RAN_PATTERN, 1, row)).toBeTrue()
  local trig = runTriggers()
  expect(#trig).toBe(1)
  local had, saved = shikudoLock.state.pending, matches
  matches = { row, row:match("^%[System%]: Running queued %w+ command: (.+)$") }
  local ok, err = pcall(trig[1].callback)
  matches = saved
  if not ok then error(err, 0) end
  return had ~= nil and shikudoLock.state.pending == nil
end

-- One round the game runs: a press of `sr`, then the run line of what it queued.
local function round(width)
  local line = dispatchLine()
  expect(ran(line, width)).toBeTrue()
  return line
end

describe("the transition goes first, as the game takes it (007)", function()
  it("Oak with the Oak half on: transition to Willow, then the Willow combo, then ASSESS", function()
    fight("Oak", 6, set("asthma", "slickness", "weariness", "clumsiness", "impatience"))
    local line = dispatchLine()
    expect(line).toBe("queue addclear free wield staff;transition to willow form;"
      .. "combo Agathon flashheel left hiraku hiru;assess Agathon")
    expect(line:find("transition to the", 1, true)).toBeNil()
  end)

  it("a lock missing only weariness stays in Oak for its kuro, rather than going to Willow", function()
    fight("Oak", 6, set("asthma", "slickness", "anorexia", "impatience", "paralysis"))
    expect(dispatchLine()).toBe("queue addclear free wield staff;combo Agathon risingkick torso kuro left ruku left;"
      .. "assess Agathon")
  end)

  it("no transition below a chain of 5, and every round ends with ASSESS", function()
    fight("Oak", 3, {}, false)
    expect(dispatchLine()).toBe("queue addclear free wield staff;combo Agathon risingkick torso livestrike ruku torso;"
      .. "assess Agathon")
  end)

  it("a shield is shattered first, never with a crescent", function()
    fight("Maelstrom", 3, set("shield", "prone"))
    ataxiaTemp.lastAssessHp, ataxiaTemp.lastAssessMax = 2800, 7000
    ataxiaTemp.lastAssessAt, ataxiaTemp.lastAssessWho = getEpoch(), "Agathon"
    expect(dispatchLine()).toBe("queue addclear free wield staff;combo Agathon shatter risingkick torso;assess Agathon")
  end)
end)

describe("Telepathy is its own round; impatience before anorexia (007)", function()
  it("a critical MIND command replaces the combo, and may carry the transition", function()
    fight("Oak", 3, set("asthma", "slickness"))
    expect(dispatchLine()).toBe("queue addclear free mind impatience Agathon;assess Agathon")
    fight("Oak", 6, set("asthma", "slickness"))
    expect(dispatchLine()).toBe("queue addclear free transition to willow form;mind impatience Agathon;assess Agathon")
  end)

  it("at most two MIND rounds in a row, then a combo", function()
    fight("Oak", 3, set("asthma", "slickness"))
    expect(round()).toContain("mind impatience")
    expect(round()).toContain("mind impatience")
    local third = round()
    expect(third).toContain("combo Agathon")
    expect(third:find("mind ", 1, true)).toBeNil()
    expect(round()).toContain("mind impatience")
  end)

  it("the Rain filler goes out only after a combo", function()
    fight("Rain", 3, {})
    expect(round()).toContain("combo Agathon frontkick left")
    expect(round()).toBe("queue addclear free mind impatience Agathon;assess Agathon")
    expect(round()).toContain("combo Agathon")
  end)

  it("no MIND round once the chain is 13 s past its last strike: the combo keeps it alive", function()
    -- A chain of 3 carries no transition, so the combo's strikes are what keeps it.
    fight("Oak", 3, set("asthma", "slickness"))
    ataxiaTemp.kataAt = getEpoch() - 13
    expect(dispatchLine()).toBe("queue addclear free wield staff;combo Agathon risingkick torso nervestrike kuro left;"
      .. "assess Agathon")
    fight("Oak", 3, set("asthma", "slickness"))
    ataxiaTemp.kataAt = getEpoch() - 5
    expect(dispatchLine()).toBe("queue addclear free mind impatience Agathon;assess Agathon")
  end)

  it("equilibrium down at the press does not turn a critical MIND round into a combo", function()
    -- Both would wait on the `free` queue and run at the same moment; the combo would land hiraku
    -- before impatience.
    fight("Willow", 0, set("asthma", "slickness"), false)
    expect(dispatchLine()).toBe("queue addclear free mind impatience Agathon;assess Agathon")
  end)

  it("a round that transitions sends its MIND command however old the chain: the transition resets it", function()
    fight("Oak", 6, set("asthma", "slickness"))
    ataxiaTemp.kataAt = getEpoch() - 13
    expect(dispatchLine()).toBe("queue addclear free transition to willow form;mind impatience Agathon;assess Agathon")
  end)

  it("with chainTelepathy the MIND command rides after the combo instead", function()
    fight("Rain", 3, {})
    shikudoLock.config.chainTelepathy = true
    local ok, err = pcall(function()
      expect(dispatchLine()).toBe("queue addclear free wield staff;combo Agathon frontkick left kuro left ruku left;"
        .. "mind impatience Agathon;assess Agathon")
    end)
    shikudoLock.config.chainTelepathy = false
    if not ok then error(err, 0) end
  end)
end)

describe("the lock's kill is KAI CHOKE, after confuse and disrupt (007)", function()
  it("confuse, then disrupt, then KAI CHOKE alone, and it keeps choking", function()
    fight("Willow", 3, set(unpack(TRUELOCK)))
    expect(round()).toBe("queue addclear free mind confuse Agathon;assess Agathon")
    tAffs.confusion = true
    expect(round()).toBe("queue addclear free mind disrupt Agathon;assess Agathon")
    tAffs.disrupted = true
    local choke = round()
    expect(choke).toBe("queue addclear free kai choke Agathon;assess Agathon")
    -- Disrupted cured after the first choke: still a choke, never the prelude again.
    tAffs.disrupted = nil
    expect(round()).toBe("queue addclear free kai choke Agathon;assess Agathon")
  end)

  it("after maxPrelude prelude rounds the choke goes out regardless", function()
    fight("Willow", 3, set(unpack(TRUELOCK)))
    for _ = 1, shikudoLock.config.maxPrelude do
      expect(round()).toContain("mind confuse Agathon")
    end
    expect(round()).toContain("kai choke Agathon")
  end)

  it("no KAI CHOKE without the kai for it", function()
    fight("Willow", 3, set(unpack(TRUELOCK)))
    ataxia.vitals.kai = 5
    local line = dispatchLine()
    expect(line:find("kai choke", 1, true)).toBeNil()
    expect(line).toContain("combo Agathon")
  end)

  it("a broken lock ends the chokes, and the next one starts with its prelude again", function()
    fight("Willow", 3, set("confusion", "disrupted", unpack(TRUELOCK)))
    expect(round()).toContain("kai choke Agathon")
    expect(shikudoLock.state.choking).toBeTrue()
    tAffs.weariness = nil
    expect(round()).toContain("combo Agathon")
    expect(shikudoLock.state.choking).toBeFalse()
    tAffs.weariness, tAffs.confusion = true, nil
    expect(round()).toContain("mind confuse Agathon")
  end)
end)

describe("the round history moves when the game RUNS a round, not when sr is pressed (007)", function()
  -- `queue addclear free` replaces a round still waiting, so a press that changes the history
  -- makes the round that runs depend on how often the key was pressed (v4.7.420 review).

  it("pressing again before a round runs queues the same round", function()
    fight("Rain", 3, {})
    expect(round()).toContain("combo Agathon")
    local filler = dispatchLine()
    expect(filler).toBe("queue addclear free mind impatience Agathon;assess Agathon")
    expect(dispatchLine()).toBe(filler)
    expect(dispatchLine()).toBe(filler)
    expect(ran(filler)).toBeTrue()
    expect(dispatchLine()).toContain("combo Agathon")
  end)

  it("a critical MIND round is not turned into a combo by pressing again", function()
    local mind = "queue addclear free transition to willow form;mind impatience Agathon;assess Agathon"
    fight("Oak", 6, set("asthma", "slickness"))
    expect(round()).toBe(mind)
    for _ = 1, 3 do expect(dispatchLine()).toBe(mind) end
    expect(ran(mind)).toBeTrue()
    -- Two MIND rounds have now RUN: the cap sends the combo.
    expect(dispatchLine()).toContain("combo Agathon flashheel")
  end)

  it("pressing does not use up the KILL prelude, and the choke latch waits for a choke that ran", function()
    local confuse = "queue addclear free mind confuse Agathon;assess Agathon"
    fight("Willow", 3, set(unpack(TRUELOCK)))
    expect(round()).toBe(confuse)
    for _ = 1, 4 do expect(dispatchLine()).toBe(confuse) end
    expect(shikudoLock.state.prelude).toBe(1)
    expect(ran(confuse)).toBeTrue()
    expect(round()).toBe(confuse)
    expect(shikudoLock.state.prelude).toBe(3)
    local choke = dispatchLine()
    expect(choke).toBe("queue addclear free kai choke Agathon;assess Agathon")
    expect(shikudoLock.state.choking).toBeFalse()
    expect(ran(choke)).toBeTrue()
    expect(shikudoLock.state.choking).toBeTrue()
  end)

  it("a run line is matched from its first row, wherever the server wraps it", function()
    local savedQueue = combatQueue
    combatQueue = function() return "g body;g gold;stand;" end
    local ok, err = pcall(function()
      for _, width in ipairs({ 100, 119, 124, 200 }) do
        fight("Rain", 3, {})
        round(width)
        local filler = dispatchLine()
        expect(filler).toBe("queue addclear free g body;g gold;stand;mind impatience Agathon;assess Agathon")
        expect(ran(filler, width)).toBeTrue()
        expect(shikudoLock.state.lastRound).toBe("mind")
        local combo = dispatchLine()
        local rows = TL.wrap("[System]: Running queued free command: " .. combo:sub(#"queue addclear free " + 1), width)
        expect(#rows > 1 or width == 200).toBeTrue() -- the combo's run line really wraps
        expect(ran(combo, width)).toBeTrue()
        expect(shikudoLock.state.lastRound).toBe("combo")
      end
    end)
    combatQueue = savedQueue
    if not ok then error(err, 0) end
  end)

  it("another command's run line moves nothing", function()
    fight("Rain", 3, {})
    round()
    local filler = dispatchLine()
    expect(ran("queue addclear free mind sense Agathon")).toBeFalse()
    expect(shikudoLock.state.lastRound).toBe("combo")
    expect(dispatchLine()).toBe(filler)
    expect(ran(filler)).toBeTrue()
    expect(ran(filler)).toBeFalse() -- nothing pending any more
  end)

  it("until a run line has matched one of our rounds, a round counts when it is queued", function()
    -- With queue alerts off no run line ever prints; the MIND cap must hold all the same.
    fight("Oak", 3, set("asthma", "slickness"))
    expect(dispatchLine()).toContain("mind impatience")
    expect(dispatchLine()).toContain("mind impatience")
    expect(dispatchLine()).toContain("combo Agathon")
    expect(shikudoLock.state.runLine).toBeFalse()
  end)

  it("with no limb reading, the flashheel leg alternates per round that runs", function()
    fight("Willow", 3, {})
    lb = {}
    expect(round()).toContain("flashheel left")
    local nextRound = dispatchLine()
    expect(nextRound).toContain("flashheel right")
    expect(dispatchLine()).toBe(nextRound)
    expect(ran(nextRound)).toBeTrue()
    expect(dispatchLine()).toContain("flashheel left")
  end)

  it("the run-line trigger is registered once, and a reload replaces it", function()
    expect(#runTriggers()).toBe(1)
    local oldId
    for id, t in pairs(MOCK.active_triggers) do
      if t.pattern == shikudoLock.RAN_PATTERN then oldId = id end
    end
    local savedTemp = ataxiaTemp
    ataxiaTemp = { shikLockRunTrigger = oldId }
    local ok, err = pcall(dofile, SH .. "007_CC_Shikudo_Lock.lua")
    local newId = ataxiaTemp.shikLockRunTrigger
    ataxiaTemp = savedTemp
    if not ok then error(err, 0) end
    expect(MOCK.active_triggers[oldId]).toBeNil()
    expect(#runTriggers()).toBe(1)
    expect(newId ~= nil and newId ~= oldId).toBeTrue()
  end)
end)

-- Restore the shared Lua state.
for k in pairs(_G) do
  if before[k] == nil then _G[k] = nil end
end
for k, v in pairs(before) do _G[k] = v end
