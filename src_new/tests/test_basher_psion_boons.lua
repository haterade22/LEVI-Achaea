--- test_basher_psion_boons.lua -- the Psion boons, and the transcendence counter (v4.7.349)
--
-- User: "Psion is another class we need to add." Three boons, pasted:
--
--   Bloodletter's Fury  "Your emulation rupture ability is now effective against denizens. While
--                        you possess the rupturesight defence, your weaving attacks against
--                        denizens will now deal unblockable damage and 50% increased base damage,
--                        and you will recover balance 20% faster."
--   Mindbreak           "Your psionics shatter ability deals 500% increased damage."
--   Razor Clarity       "You deal 50% bonus damage and have 2% bonus critical chance while
--                        benefitting from the emulation clarity defence."
--
-- Two of them pay out for as long as a DEFENCE stands, which makes them keepers rather than
-- attacks -- and ENACT costs EQUILIBRIUM, which every Psion weave leaves idle. The third needs no
-- rotation change at all, and these tests pin that as a decision rather than leaving it to look
-- like an oversight.
--
-- Then, separately, the counter those rounds read: the user pasted the transcendence decay ladder
-- and it turned out the pattern watching it could never have matched.

local mock = require("mock_mudlet")

function ataxiaEcho() end
ataxia = ataxia or {}
ataxia.settings = { separator = ";" }
ataxia.vitals = { hpp = 100, rage = 0 }
ataxia.defences = {}
ataxiaBasher = ataxiaBasher or {}
ataxiaBasher.enabled, ataxiaBasher.shielded, ataxiaBasher.rageraze = true, false, false
ataxiaBasher.battlerage = ataxiaBasher.battlerage or {}
ataxiaTemp = ataxiaTemp or {}
target = 44001
gmcp = {
  Room = { Info = { num = 1, area = "" } },
  Char = { Status = { class = "Psion", level = "80 " }, Vitals = { maxmp = 6000 } },
  IRE = { Target = { Info = {} } },
}
function ataxiaBasher_assembleBattlerage() return "" end
function ataxiaBasher_brCommit(x) return x or "" end
function ataxiaBasher_psionBattlerage() return "" end

-- tempTimer is what the keepers use to release their anti-spam hold; run it under our control.
local timers = {}
local realTempTimer = tempTimer
tempTimer = function(secs, code)
  timers[#timers + 1] = { at = secs, code = code }
  return #timers
end
local function fireTimers()
  local pending = timers
  timers = {}
  for _, t in ipairs(pending) do
    local f = loadstring and loadstring(t.code) or load(t.code)
    if f then f() end
  end
end

local clock = 100000
local realEpoch = getEpoch
getEpoch = function() return clock end

local ok, err = pcall(dofile, "src_new/scripts/levi_ataxia/levi/ataxia/basher/002_Class_Bashing.lua")
if not ok then error("failed to load class bashing: " .. tostring(err)) end

-- The room count every AoE rider reads (M._denizenCount, 008). Stubbed; restored at file end.
denizens = 0
ataxia.mnemosyne = ataxia.mnemosyne or {}
local realDenizenCount = ataxia.mnemosyne._denizenCount
ataxia.mnemosyne._denizenCount = function() return denizens end

local function reset()
  clock = clock + 500
  timers = {}
  ataxia.defences = {}
  ataxia.vitals.hpp, ataxia.vitals.rage = 100, 0
  ataxiaBasher.shielded, ataxiaBasher.rageraze = false, false
  ataxiaBasher.psionKeepHold = nil
  psionBloodletter, psionRazorClarity, psionMindbreak = false, false, false
  psionPsiwave = false
  psionEarthquake = false
  psionProphet = false
  psionRoth = false
  ataxiaTemp.psionRuptureUpAt = nil
  ataxiaTemp.psionForesightAt, ataxiaTemp.psionForesightTry = nil, nil
  gmcp.IRE.Target.Info = {}
  ataxiaBasher.upheavalAt = nil
  denizens = 0
  psionPanoply = false
  ataxiaTemp.psionKeepAt, ataxiaTemp.psionTranscendAt = nil, nil
  ataxiaTemp.psionRothAt = nil
  ataxiaTemp.psionSecondskinAttempted = true
  ataxiaTemp.transcendence = 0
  ataxia.defences.psitranscend, ataxia.defences.secondskin = true, true
end

local function keepers(roth)
  return ataxiaBasher_psionEmulationKeepers(";", roth)
end

-- =====================================================================================
describe("Razor Clarity keeps the clarity defence up", function()
  it("enacts it when the boon is held and the defence is down", function()
    reset()
    psionRazorClarity = true
    expect(keepers(false)).toBe("enact clarity;")
  end)

  it("does nothing without the boon -- it is only worth an eq while it pays 50%", function()
    reset()
    expect(keepers(false)).toBe("")
  end)

  it("does nothing while the defence is already up", function()
    reset()
    psionRazorClarity = true
    ataxia.defences.clarity = true
    expect(keepers(false)).toBe("")
  end)
end)

describe("Bloodletter's Fury keeps rupturesight up", function()
  it("enacts RUPTURE -- the command that grants the defence the boon names", function()
    reset()
    psionBloodletter = true
    expect(keepers(false)).toBe("enact rupture;")
  end)

  it("stands down once the defence is up", function()
    reset()
    psionBloodletter = true
    ataxia.defences.rupturesight = true
    expect(keepers(false)).toBe("")
  end)

  -- ONE EQUILIBRIUM ACTION PER ROUND (v4.7.351, deep review). This test used to assert
  -- "enact clarity;enact rupture;" -- the collision itself. Both ENACTs cost 2.30s of
  -- equilibrium and a queued chain runs back to back, so the second was refused while its hold
  -- was stamped as if it had gone.
  it("both boons: ONE per round, rupture first, clarity on the next idle equilibrium", function()
    reset()
    psionBloodletter, psionRazorClarity = true, true
    expect(keepers(false)).toBe("enact rupture;")   -- the larger boon, alone
    clock = clock + 3                                -- rupture still held; eq free again
    expect(keepers(false)).toBe("enact clarity;")
  end)
end)

describe("the keepers do not spam, and do not waste roth's free grant", function()
  it("holds after a send, and re-arms when the hold expires", function()
    reset()
    psionRazorClarity = true
    expect(keepers(false)).toBe("enact clarity;")
    expect(keepers(false)).toBe("")          -- still in flight
    clock = clock + 12
    expect(keepers(false)).toBe("enact clarity;")
  end)

  -- Per defence, not "two different numbers exist": the deep review's mutation run swapped the
  -- two values and the old sorted-pair assertion could not tell.
  it("holds each defence for ITS OWN period: clarity 12s, rupturesight 4s", function()
    reset()
    psionRazorClarity = true
    keepers(false)
    clock = clock + 5
    expect(keepers(false)).toBe("")                  -- clarity still held at 5s
    clock = clock + 7
    expect(keepers(false)).toBe("enact clarity;")    -- ...released at 12s
    reset()
    psionBloodletter = true
    keepers(false)
    clock = clock + 3
    expect(keepers(false)).toBe("")                  -- rupture held at 3s
    clock = clock + 1
    expect(keepers(false)).toBe("enact rupture;")    -- ...released at 4s
  end)

  it("an explicit hold overrides both", function()
    reset()
    psionRazorClarity = true
    ataxiaBasher.psionKeepHold = 3
    keepers(false)
    clock = clock + 2
    expect(keepers(false)).toBe("")
    clock = clock + 1
    expect(keepers(false)).toBe("enact clarity;")
    ataxiaBasher.psionKeepHold = nil
  end)

  -- A TIMESTAMP, not a timer (v4.7.351): a lost tempTimer wedged the old flag on for the session.
  it("arms no timer -- the hold expires on its own", function()
    reset()
    psionBloodletter, psionRazorClarity = true, true
    keepers(false)
    expect(#timers).toBe(0)
  end)

  -- Roth grants clarity AND rupture free, and transcend takes the eq too: either way, nothing.
  it("stands down entirely when the round's equilibrium is already spent", function()
    reset()
    psionBloodletter, psionRazorClarity = true, true
    expect(keepers(true)).toBe("")
    expect(ataxiaTemp.psionKeepAt).toBeNil()          -- and burns no hold doing it
  end)
end)

-- =====================================================================================
describe("the keepers ride the Psion round", function()
  it("go out with the weave -- eq riders beside a balance swing", function()
    reset()
    psionRazorClarity = true
    local cmd = ataxiaBasher_psionBashing()
    expect(cmd:find("enact clarity", 1, true) ~= nil).toBeTrue()
    expect(cmd:find("weave deathblow 44001", 1, true) ~= nil).toBeTrue()
    expect(cmd:find("enact clarity", 1, true) < cmd:find("weave", 1, true)).toBeTrue()
  end)

  it("ride the SHIELDED round too -- raising a defence is not an attack", function()
    reset()
    psionBloodletter = true
    ataxiaBasher.shielded = true
    local cmd = ataxiaBasher_psionBashing()
    expect(cmd:find("enact rupture", 1, true) ~= nil).toBeTrue()
    expect(cmd:find("weave cleave 44001", 1, true) ~= nil).toBeTrue()
  end)

  it("roth still comes first, and takes the keepers' place for that round", function()
    reset()
    psionBloodletter, psionRazorClarity = true, true
    ataxia.vitals.hpp = 30
    local cmd = ataxiaBasher_psionBashing()
    expect(cmd:find("enact wrath", 1, true) ~= nil).toBeTrue()
    expect(cmd:find("enact clarity", 1, true)).toBeNil()
    expect(cmd:find("enact rupture", 1, true)).toBeNil()
  end)

  it("the round is unchanged when neither boon is held", function()
    reset()
    local cmd = ataxiaBasher_psionBashing()
    expect(cmd:find("enact ", 1, true)).toBeNil()
    expect(cmd:find("weave deathblow 44001", 1, true) ~= nil).toBeTrue()
  end)
end)

-- =====================================================================================
-- MINDBREAK CHANGES NOTHING, AND THAT IS THE FINDING. `psi shatter` already fires on every FULL
-- transcendence, which is exactly when a psionics action is free ("once at full harmony, you can
-- perform a psionics action while off equilibrium and for no incurred equilibrium cost"). The
-- gate is about when shatter is FREE, not whether it is worth it, so a damage multiplier does
-- not move it. This pins that as a decision, so a later reader does not "fix" it by accident.
describe("Mindbreak: latched, and deliberately inert", function()
  it("shatter fires at full transcendence with or without the boon", function()
    reset()
    ataxiaTemp.transcendence = 100
    local without = ataxiaBasher_psionBashing()
    reset()
    psionMindbreak = true
    ataxiaTemp.transcendence = 100
    local with = ataxiaBasher_psionBashing()
    expect(without:find("psi shatter 44001", 1, true) ~= nil).toBeTrue()
    expect(with).toBe(without)
  end)

  -- v4.7.356: shatter goes out ONLY at full transcendence ("we should only use PSI Shatter when at
  -- 100 transcendence!") -- with or without the boon.
  it("and below full transcendence there is no shatter, boon or not", function()
    reset()
    ataxiaTemp.transcendence = 90
    local without = ataxiaBasher_psionBashing()
    reset()
    psionMindbreak = true
    ataxiaTemp.transcendence = 90
    local with = ataxiaBasher_psionBashing()
    expect(without:find("psi shatter", 1, true)).toBeNil()
    expect(with).toBe(without)
  end)
end)

-- =====================================================================================
-- THE COUNTER THOSE ROUNDS READ. User pasted the decay ladder (60 -> 50 -> ... -> 10, then "Your
-- body and mind are no longer in harmony."), which is how this surfaced: the decay pattern ran to
-- a `$` anchor and the line is 128 characters, so Achaea's server-side wrap split it and the
-- pattern could never match. The build line is 94 and fitted -- so transcendence counted UP and
-- never came back down, and the round kept spending on a shatter the game had taken away.
describe("the transcendence lines the round depends on", function()
  local function slurp(p) local f = io.open(p); local s = f:read("*a"); f:close(); return s end
  local P = "src_new/triggers/levi_ataxia/for_levi/leviticus/psion/"

  it("neither pattern runs past the captured number, so a wrap cannot break it", function()
    local t = slurp(P .. "001_Transcendence_Set.lua")
    local pats = {}
    for line in t:gmatch("%- pattern: '([^']+)'") do pats[#pats + 1] = line end
    expect(#pats).toBe(2)
    for _, p in ipairs(pats) do
      expect(p:sub(1, 1)).toBe("^")                    -- still anchored at the START, which is safe
      -- still captures the percentage (the pattern text is read raw, so the backslash class is
      -- built rather than written -- a Lua string literal cannot carry a bare \d).
      expect(p:find("(" .. string.char(92) .. "d+)", 1, true) ~= nil).toBeTrue()
      expect(p:find("$", 1, true)).toBeNil()           -- the anchor that could never match
      expect(p:find("of the way", 1, true)).toBeNil()  -- ...and nothing from beyond the wrap
    end
  end)

  it("the decay line's own prefix is short enough to survive the wrap", function()
    local t = slurp(P .. "001_Transcendence_Set.lua")
    local decay = t:match("%- pattern: '(%^Your inaction[^']+)'")
    expect(decay ~= nil).toBeTrue()
    -- The user's paste broke after "of the way to " at column 114; the pattern must be satisfied
    -- well before that or it is the same bug again.
    local literal = decay:gsub("\\%:", ":"):gsub("%(%\\d%+%)", "60"):gsub("%^", "")
    expect(#literal < 114).toBeTrue()
  end)

  it("the bottom of the ladder zeroes the counter", function()
    local t = slurp(P .. "003_Transcendence_Dropped.lua")
    expect(t:find("Your body and mind are no longer in harmony.", 1, true) ~= nil).toBeTrue()
    expect(t:find("ataxiaTemp.transcendence = 0", 1, true) ~= nil).toBeTrue()
  end)
end)

-- =====================================================================================
describe("all three flags are wired where a boon flag must be", function()
  local function slurp(p) local f = io.open(p); local s = f:read("*a"); f:close(); return s end
  local S = "src_new/scripts/levi_ataxia/levi/ataxia/"
  local FLAGS = { "psionBloodletter", "psionRazorClarity", "psionMindbreak", "psionPsiwave" }

  it("the catalogue, under the names the game prints", function()
    local t = slurp(S .. "mnemosyne/004_Parsers.lua")
    expect(t:find('["Bloodletter\'s Fury"]', 1, true) ~= nil).toBeTrue()
    expect(t:find('["Razor Clarity"]', 1, true) ~= nil).toBeTrue()
    expect(t:find('["Mindbreak"]', 1, true) ~= nil).toBeTrue()
    expect(t:find('["Psiwave"]', 1, true) ~= nil).toBeTrue()
  end)

  it("both resets, for every one of them", function()
    local endT = slurp(S .. "mnemosyne/004_Parsers.lua")
    local startT = slurp("src_new/triggers/levi_ataxia/for_levi/leviticus/mnemosyne/001_Run_Start.lua")
    for _, f in ipairs(FLAGS) do
      expect(endT:find(f .. " = false", 1, true) ~= nil).toBeTrue()
      expect(startT:find(f .. " = false", 1, true) ~= nil).toBeTrue()
    end
  end)

  it("the claim line and a BOONS row each", function()
    local claim = slurp("src_new/aliases/levi_ataxia/for_levi/levi_062424/mnemosyne/002_Boon_Claim.lua")
    for _, f in ipairs(FLAGS) do
      expect(claim:find(f .. " = true", 1, true) ~= nil).toBeTrue()
    end
    local T = "src_new/triggers/levi_ataxia/for_levi/leviticus/mnemosyne/"
    expect(slurp(T .. "099_Bloodletters_Fury.lua"):find("psionBloodletter = true", 1, true) ~= nil).toBeTrue()
    expect(slurp(T .. "100_Razor_Clarity.lua"):find("psionRazorClarity = true", 1, true) ~= nil).toBeTrue()
    expect(slurp(T .. "101_Mindbreak.lua"):find("psionMindbreak = true", 1, true) ~= nil).toBeTrue()
  end)

  it("and the seed carries each description for the advisor", function()
    local t = slurp(S .. "mnemosyne/010_Boon_Seed.lua")
    expect(t:find("rupturesight defence", 1, true) ~= nil).toBeTrue()
    expect(t:find("emulation clarity defence", 1, true) ~= nil).toBeTrue()
    expect(t:find("shatter ability deals 500", 1, true) ~= nil).toBeTrue()
  end)
end)

-- =====================================================================================
-- ONE EQUILIBRIUM ACTION PER ROUND, across the whole Psion round (v4.7.351, deep review).
-- Roth, psi transcend and the two keepers all spend equilibrium; the priority is roth (the
-- emergency heal), then transcend (the shatter loop needs it), then the boon keepers.
describe("one equilibrium action per Psion round", function()
  local function count(s, needle)
    local n, i = 0, 1
    while true do
      local a = s:find(needle, i, true)
      if not a then return n end
      n, i = n + 1, a + 1
    end
  end
  local function eqActions(cmd)
    local n = count(cmd, "enact ") + count(cmd, "psi transcend")
    if (tonumber(ataxiaTemp.transcendence) or 0) < 100 then n = n + count(cmd, "psi shatter") end
    return n
  end

  it("psi transcend outranks the keepers, and they follow on the next round", function()
    reset()
    psionRazorClarity = true
    ataxia.defences.psitranscend = nil
    local first = ataxiaBasher_psionBashing()
    expect(first:find("psi transcend", 1, true) ~= nil).toBeTrue()
    expect(first:find("enact clarity", 1, true)).toBeNil()
    clock = clock + 3
    local second = ataxiaBasher_psionBashing()
    expect(second:find("enact clarity", 1, true) ~= nil).toBeTrue()
    expect(second:find("psi transcend", 1, true)).toBeNil()   -- still in its own hold
  end)

  it("a roth round spends nothing else, even with transcend and both boons down", function()
    reset()
    psionBloodletter, psionRazorClarity = true, true
    ataxia.defences.psitranscend = nil
    ataxia.vitals.hpp = 30
    local cmd = ataxiaBasher_psionBashing()
    expect(cmd:find("enact wrath", 1, true) ~= nil).toBeTrue()
    expect(eqActions(cmd)).toBe(1)
  end)

  it("never more than one, whatever is down", function()
    for _, hp in ipairs({ 100, 30 }) do
      for _, ts in ipairs({ true, false }) do
        reset()
        psionBloodletter, psionRazorClarity = true, true
        ataxia.vitals.hpp = hp
        ataxia.defences.psitranscend = ts or nil
        expect(eqActions(ataxiaBasher_psionBashing()) <= 1).toBeTrue()
      end
    end
  end)
end)


-- =====================================================================================
-- SHATTER ONLY AT FULL TRANSCENDENCE (v4.7.356). User: "Sorry, you keep using Psi shatter when we
-- should be using weavings. Therefore, we should only use PSI Shatter when at 100 transcendence!
-- PSI Shatter target;Weave deathblow target". v4.7.352-355 also sent a PAID shatter on idle
-- equilibrium; the queued round waits for equilibrium AND balance, so that held every weave back --
-- and weaves are what build transcendence.
describe("psi shatter only at full transcendence", function()
  local function has(cmd, s) return cmd:find(s, 1, true) ~= nil end
  local function count(cmd, s) local _, n = cmd:gsub(s, ""); return n end

  it("below full transcendence the round is the weave -- no shatter at all", function()
    for _, tr in ipairs({ 0, 50, 99 }) do
      reset()
      ataxiaTemp.transcendence = tr
      local cmd = ataxiaBasher_psionBashing()
      expect(has(cmd, "psi shatter")).toBeFalse()
      expect(has(cmd, "weave deathblow 44001")).toBeTrue()
    end
  end)

  it("at full transcendence: exactly the user's round -- shatter, then the weave", function()
    reset()
    ataxiaTemp.transcendence = 100
    local cmd = ataxiaBasher_psionBashing()
    expect(cmd:find("psi shatter 44001", 1, true)).toBe(1)
    expect(count(cmd, "psi shatter")).toBe(1)
    expect(cmd:find("psi shatter", 1, true) < cmd:find("weave deathblow 44001", 1, true)).toBeTrue()
  end)

  -- It needs equilibrium but spends none (v4.7.353), so it goes FIRST, ahead of what spends it.
  it("the free shatter goes ahead of a keeper that spends equilibrium", function()
    reset()
    psionRazorClarity = true
    ataxiaTemp.transcendence = 100
    local cmd = ataxiaBasher_psionBashing()
    expect(cmd:find("psi shatter", 1, true)).toBe(1)
    expect(cmd:find("psi shatter", 1, true) < cmd:find("enact clarity", 1, true)).toBeTrue()
  end)

  it("and ahead of roth", function()
    reset()
    ataxia.vitals.hpp = 30
    ataxiaTemp.transcendence = 100
    local cmd = ataxiaBasher_psionBashing()
    expect(cmd:find("psi shatter", 1, true) < cmd:find("enact wrath", 1, true)).toBeTrue()
  end)

  it("never on a shielded round -- the shield comes first, and transcendence waits", function()
    reset()
    ataxiaBasher.shielded = true
    ataxiaTemp.transcendence = 100
    expect(has(ataxiaBasher_psionBashing(), "psi shatter")).toBeFalse()
  end)

  it("rides a secondskin round -- secondskin spends balance", function()
    reset()
    ataxia.defences.secondskin = nil
    ataxiaTemp.psionSecondskinAttempted = nil
    ataxiaTemp.transcendence = 100
    local cmd = ataxiaBasher_psionBashing()
    expect(has(cmd, "weave secondskin")).toBeTrue()
    expect(has(cmd, "psi shatter 44001")).toBeTrue()
  end)

  it("a keeper still gets a round below full transcendence -- and nothing rides it", function()
    reset()
    psionRazorClarity = true
    local cmd = ataxiaBasher_psionBashing()
    expect(has(cmd, "enact clarity")).toBeTrue()
    expect(has(cmd, "psi shatter")).toBeFalse()
  end)
end)

-- =====================================================================================
-- BEHIND BY ONE ROUND AT FULL TRANSCENDENCE (v4.7.352). User: "Seems like we are behind one
-- attack on the transcendance, maybe a clearqueue is needed when we are at full." The round is
-- rebuilt on prompt/vitals events behind a 0.3s anti-spam flag, so the "achieved transcendence"
-- line could land after the last rebuild and the stale entry fired without the free shatter.
describe("the round is re-queued the moment transcendence fills", function()
  local AUTO = "src_new/scripts/levi_ataxia/levi/ataxia/genrunning/004_Autobashing_Functions.lua"
  local FULL = "src_new/triggers/levi_ataxia/for_levi/leviticus/psion/002_Transcendence_Full.lua"
  -- Globals the autobashing file defines; restored afterwards (one shared Lua state).
  local NAMES = { "ataxiaBasher_tryAttack", "ataxiaBasher_patterns", "ataxiaBasher_gmcpDispatch",
                  "ataxiaBasher_throttleCheck", "ataxiaBasher_requeueNow", "ataxiaBasher_gmcpDispatchHandler",
                  "ataxiaBasher_atk", "ataxiaBasher_atkTimer", "found_target" }

  local function withAuto(fn)
    local saved = {}
    for _, n in ipairs(NAMES) do saved[n] = _G[n] end
    local savedEnabled = ataxiaBasher.enabled
    local ok, err = pcall(function()
      dofile(AUTO)
      fn()
    end)
    for _, n in ipairs(NAMES) do _G[n] = saved[n] end
    ataxiaBasher.enabled = savedEnabled
    if not ok then error(err, 0) end
  end

  it("clears the anti-spam flag and re-queues through the normal gates", function()
    withAuto(function()
      local called = 0
      ataxiaBasher_tryAttack = function() called = called + 1; return true end
      ataxiaBasher.enabled, found_target, ataxiaBasher_atk = true, true, true
      expect(ataxiaBasher_requeueNow("test")).toBeTrue()
      expect(called).toBe(1)
      expect(ataxiaBasher_atk).toBeFalse()
    end)
  end)

  it("does nothing with no target, or with the basher off", function()
    withAuto(function()
      local called = 0
      ataxiaBasher_tryAttack = function() called = called + 1; return true end
      ataxiaBasher.enabled, found_target = true, false
      expect(ataxiaBasher_requeueNow("test")).toBeFalse()
      ataxiaBasher.enabled, found_target = false, true
      expect(ataxiaBasher_requeueNow("test")).toBeFalse()
      expect(called).toBe(0)
    end)
  end)

  it("the full-transcendence line re-queues -- once, on the change", function()
    local savedRq, savedDF, savedManual = ataxiaBasher_requeueNow, deleteFull, ataxiaBasher.manual
    local rq = 0
    ataxiaBasher_requeueNow = function() rq = rq + 1 end
    deleteFull = function() end
    ataxiaBasher.manual = true
    local ok, err = pcall(function()
      ataxiaTemp.transcendence = 70
      dofile(FULL)
      expect(ataxiaTemp.transcendence).toBe(100)
      expect(rq).toBe(1)
      dofile(FULL)                 -- "...transcendence is yours." again, already at 100
      expect(rq).toBe(1)
    end)
    ataxiaBasher_requeueNow, deleteFull, ataxiaBasher.manual = savedRq, savedDF, savedManual
    if not ok then error(err, 0) end
  end)
end)

-- =====================================================================================
-- PSIWAVE (v4.7.355). "Your psionics radiate ability now deals magic damage to all denizens in your
-- location." -- "When we have this boon please use this instead of shatter." Since v4.7.356, like
-- shatter, only at full transcendence.
describe("Psiwave: psi radiate instead of shatter, at full transcendence", function()
  local function count(cmd, s) local _, n = cmd:gsub(s, ""); return n end

  it("at full transcendence the free action is radiate, first, then the weave", function()
    reset()
    psionPsiwave = true
    ataxiaTemp.transcendence = 100
    local cmd = ataxiaBasher_psionBashing()
    expect(cmd:find("psi radiate", 1, true)).toBe(1)
    expect(count(cmd, "psi radiate")).toBe(1)
    expect(count(cmd, "psi shatter")).toBe(0)
    expect(cmd:find("weave deathblow 44001", 1, true) ~= nil).toBeTrue()
  end)

  it("radiate takes no target", function()
    reset()
    psionPsiwave = true
    ataxiaTemp.transcendence = 100
    expect(ataxiaBasher_psionBashing():find("psi radiate 44001", 1, true)).toBeNil()
  end)

  it("below full transcendence, neither radiate nor shatter", function()
    reset()
    psionPsiwave = true
    local cmd = ataxiaBasher_psionBashing()
    expect(cmd:find("psi radiate", 1, true)).toBeNil()
    expect(cmd:find("psi shatter", 1, true)).toBeNil()
  end)

  it("held on a shielded round, like shatter", function()
    reset()
    psionPsiwave = true
    ataxiaBasher.shielded = true
    ataxiaTemp.transcendence = 100
    expect(ataxiaBasher_psionBashing():find("psi radiate", 1, true)).toBeNil()
  end)

  -- The user's word is unconditional: radiate even with Mindbreak held.
  it("wins over Mindbreak", function()
    reset()
    psionPsiwave, psionMindbreak = true, true
    ataxiaTemp.transcendence = 100
    local cmd = ataxiaBasher_psionBashing()
    expect(cmd:find("psi radiate", 1, true) ~= nil).toBeTrue()
    expect(cmd:find("psi shatter", 1, true)).toBeNil()
  end)

  it("without the boon, shatter", function()
    reset()
    ataxiaTemp.transcendence = 100
    local cmd = ataxiaBasher_psionBashing()
    expect(cmd:find("psi shatter 44001", 1, true) ~= nil).toBeTrue()
    expect(cmd:find("psi radiate", 1, true)).toBeNil()
  end)

  it("the BOONS row carries the in-tower gate, and the seed knows the boon", function()
    local function slurp(p) local f = io.open(p); local s = f:read("*a"); f:close(); return s end
    local row = slurp("src_new/triggers/levi_ataxia/for_levi/leviticus/mnemosyne/102_Psiwave.lua")
    expect(row:find("if ataxiaBasher and ataxiaBasher.inMnemosyne then psionPsiwave = true end", 1, true) ~= nil).toBeTrue()
    expect(slurp("src_new/scripts/levi_ataxia/levi/ataxia/mnemosyne/010_Boon_Seed.lua")
      :find("radiate ability now deals magic damage", 1, true) ~= nil).toBeTrue()
  end)
end)

-- =====================================================================================
-- EARTHQUAKE (v4.7.357). "Your emulation upheaval ability deals significant blunt damage to all
-- denizens in the location when it summons rubble." ENACT UPHEAVAL: 2.30s of equilibrium, and it
-- piles rubble on some of our own exits.
describe("Earthquake: enact upheaval on idle equilibrium, in a crowd", function()
  local function has(cmd, s) return cmd:find(s, 1, true) ~= nil end
  local function count(cmd, s) local _, n = cmd:gsub(s, ""); return n end

  it("with the boon and a crowd, upheaval rides beside the weave -- once", function()
    reset()
    psionEarthquake, denizens = true, 3
    local cmd = ataxiaBasher_psionBashing()
    expect(count(cmd, "enact upheaval")).toBe(1)
    expect(has(cmd, "weave deathblow 44001")).toBeTrue()
  end)

  it("never without the boon", function()
    reset()
    denizens = 5
    expect(has(ataxiaBasher_psionBashing(), "enact upheaval")).toBeFalse()
  end)

  it("not for a single denizen -- the weave's job -- unless the threshold says so", function()
    reset()
    psionEarthquake, denizens = true, 1
    expect(has(ataxiaBasher_psionBashing(), "enact upheaval")).toBeFalse()
    reset()
    psionEarthquake, denizens = true, 1
    ataxiaBasher.upheavalAt = 1
    expect(has(ataxiaBasher_psionBashing(), "enact upheaval")).toBeTrue()
  end)

  -- Rubble blocks our own exits; the escape ladder fires at 35%.
  it("not below half health -- no more rubble on the doors we may need", function()
    reset()
    psionEarthquake, denizens = true, 4
    ataxia.vitals.hpp = 49
    ataxiaTemp.psionRothAt = clock -- roth on cooldown, so the equilibrium really is idle
    expect(has(ataxiaBasher_psionBashing(), "enact upheaval")).toBeFalse()
    reset()
    psionEarthquake, denizens = true, 4
    ataxia.vitals.hpp = 50
    expect(has(ataxiaBasher_psionBashing(), "enact upheaval")).toBeTrue()
  end)

  -- One equilibrium spender per round: whatever went first keeps it.
  it("waits for a keeper, transcend or roth that took the equilibrium", function()
    reset()
    psionEarthquake, denizens = true, 4
    psionRazorClarity = true
    local cmd = ataxiaBasher_psionBashing()
    expect(has(cmd, "enact clarity")).toBeTrue()
    expect(has(cmd, "enact upheaval")).toBeFalse()
    reset()
    psionEarthquake, denizens = true, 4
    ataxia.defences.psitranscend = nil
    cmd = ataxiaBasher_psionBashing()
    expect(has(cmd, "psi transcend")).toBeTrue()
    expect(has(cmd, "enact upheaval")).toBeFalse()
  end)

  it("not on a shielded round", function()
    reset()
    psionEarthquake, denizens = true, 4
    ataxiaBasher.shielded = true
    expect(has(ataxiaBasher_psionBashing(), "enact upheaval")).toBeFalse()
  end)

  -- The free shatter REQUIRES equilibrium without spending it, so it goes first and upheaval can
  -- still spend what is left on the same round.
  it("at full transcendence: the free shatter first, then upheaval, then the weave", function()
    reset()
    psionEarthquake, denizens = true, 4
    ataxiaTemp.transcendence = 100
    local cmd = ataxiaBasher_psionBashing()
    expect(cmd:find("psi shatter 44001", 1, true)).toBe(1)
    local u = cmd:find("enact upheaval", 1, true)
    expect(u ~= nil).toBeTrue()
    expect(cmd:find("psi shatter", 1, true) < u).toBeTrue()
    expect(u < cmd:find("weave deathblow 44001", 1, true)).toBeTrue()
  end)

  it("rides a secondskin round -- secondskin spends balance", function()
    reset()
    psionEarthquake, denizens = true, 4
    ataxia.defences.secondskin = nil
    ataxiaTemp.psionSecondskinAttempted = nil
    local cmd = ataxiaBasher_psionBashing()
    expect(has(cmd, "weave secondskin")).toBeTrue()
    expect(has(cmd, "enact upheaval")).toBeTrue()
  end)

  it("the BOONS row carries the in-tower gate, and the seed knows the boon", function()
    local function slurp(p) local f = io.open(p); local s = f:read("*a"); f:close(); return s end
    local row = slurp("src_new/triggers/levi_ataxia/for_levi/leviticus/mnemosyne/103_Earthquake.lua")
    expect(row:find("if ataxiaBasher and ataxiaBasher.inMnemosyne then psionEarthquake = true end", 1, true) ~= nil).toBeTrue()
    expect(slurp("src_new/scripts/levi_ataxia/levi/ataxia/mnemosyne/010_Boon_Seed.lua")
      :find("upheaval ability deals significant blunt damage", 1, true) ~= nil).toBeTrue()
  end)
end)

-- =====================================================================================
-- PROPHET OF CREATION (v4.7.359). "Your foresight ability now works against denizens and causes
-- the next attack against you to miss." User: "It should be psi foresight target." In game: the
-- prediction is the denizen's next attack, true in <0.3s, free, ~30s cooldown. A foresight that
-- does not come true STUNS us (AB), so only on a target at half health or more.
describe("Prophet of Creation: psi foresight <target>, one free dodge per cooldown", function()
  local TL = dofile("src_new/tests/trigger_lib.lua")
  local P = "src_new/triggers/levi_ataxia/for_levi/leviticus/psion/"
  local function has(cmd, s) return cmd:find(s, 1, true) ~= nil end
  local function ready(hp)
    reset()
    psionProphet = true
    gmcp.IRE.Target.Info = { hpperc = hp or "100%" }
  end

  it("never without the boon", function()
    reset()
    gmcp.IRE.Target.Info = { hpperc = "100%" }
    expect(has(ataxiaBasher_psionBashing(), "foresight")).toBeFalse()
  end)

  it("with the boon: `psi foresight <target>` -- no tree/shield -- first, and the weave still goes", function()
    ready()
    local cmd = ataxiaBasher_psionBashing()
    expect(cmd:find("psi foresight 44001;", 1, true)).toBe(1)
    expect(has(cmd, "shield")).toBeFalse()
    expect(has(cmd, "weave deathblow 44001")).toBeTrue()
  end)

  it("ahead of the free shatter at full transcendence", function()
    ready()
    ataxiaTemp.transcendence = 100
    local cmd = ataxiaBasher_psionBashing()
    expect(cmd:find("psi foresight", 1, true)).toBe(1)
    expect(cmd:find("psi foresight", 1, true) < cmd:find("psi shatter", 1, true)).toBeTrue()
  end)

  it("on a shielded round too -- a shielded denizen still swings", function()
    ready()
    ataxiaBasher.shielded = true
    expect(has(ataxiaBasher_psionBashing(), "psi foresight 44001")).toBeTrue()
  end)

  -- The stun: a target that dies before it swings leaves the prediction unfulfilled.
  it("only while the target is at half health or more, and never when that is unreadable", function()
    ready("49%")
    expect(has(ataxiaBasher_psionBashing(), "foresight")).toBeFalse()
    ready("50%")
    expect(has(ataxiaBasher_psionBashing(), "foresight")).toBeTrue()
    ready()
    gmcp.IRE.Target.Info = {}
    expect(has(ataxiaBasher_psionBashing(), "foresight")).toBeFalse()
  end)

  -- Rounds are rebuilt every 0.3s; the ones built while the cast line is on its way must not repeat it.
  it("a short in-flight hold, not the cooldown, until the game confirms the cast", function()
    ready()
    expect(has(ataxiaBasher_psionBashing(), "foresight")).toBeTrue()
    clock = clock + 1
    expect(has(ataxiaBasher_psionBashing(), "foresight")).toBeFalse()
    clock = clock + 1            -- the round carrying it was replaced before it fired: try again
    expect(has(ataxiaBasher_psionBashing(), "foresight")).toBeTrue()
  end)

  it("the cast line starts the ~30s cooldown", function()
    ready()
    ataxiaBasher_psionBashing()
    local line = "You direct your formidable mental might towards the task of piercing the very fabric of time "
      .. "itself, seeking out a situation in the near future where a halfling semi-soldier will act as you predict."
    local row = TL.wrap(line, 119)[1]
    expect(TL.anyMatches(TL.patterns(P .. "005_Foresight_Cast.lua"), row)).toBeTrue()
    dofile(P .. "005_Foresight_Cast.lua")
    clock = clock + 29
    expect(has(ataxiaBasher_psionBashing(), "foresight")).toBeFalse()
    clock = clock + 1
    expect(has(ataxiaBasher_psionBashing(), "foresight")).toBeTrue()
  end)

  it("the refusal retries in 5s instead of a whole fresh cooldown", function()
    ready()
    local line = "Your mind has not yet recovered enough to pierce the fabric of time once again."
    expect(TL.anyMatches(TL.patterns(P .. "006_Foresight_Refused.lua"), line)).toBeTrue()
    dofile(P .. "006_Foresight_Refused.lua")
    clock = clock + 4
    expect(has(ataxiaBasher_psionBashing(), "foresight")).toBeFalse()
    clock = clock + 1
    expect(has(ataxiaBasher_psionBashing(), "foresight")).toBeTrue()
  end)

  it("the BOONS row carries the in-tower gate, and the seed knows the boon", function()
    local function slurp(p) local f = io.open(p); local s = f:read("*a"); f:close(); return s end
    local row = slurp("src_new/triggers/levi_ataxia/for_levi/leviticus/mnemosyne/105_Prophet_of_Creation.lua")
    expect(row:find("if ataxiaBasher and ataxiaBasher.inMnemosyne then psionProphet = true end", 1, true) ~= nil).toBeTrue()
    expect(slurp("src_new/scripts/levi_ataxia/levi/ataxia/mnemosyne/010_Boon_Seed.lua")
      :find("foresight ability now works against denizens", 1, true) ~= nil).toBeTrue()
  end)
end)

-- =====================================================================================
-- ROTH (v4.7.360), the Psion combo boon (Razor Clarity + Bloodletter's Fury): "Your emulation
-- wrath ability now has a cooldown of 30 seconds, and only requires you to be under 75% of your
-- maximum health." And the command is ENACT WRATH -- the package sent `enact roth` until now.
describe("wrath, and the Roth combo boon", function()
  local function has(cmd, s) return cmd:find(s, 1, true) ~= nil end

  it("the command is `enact wrath` -- never the boon's name", function()
    reset()
    ataxia.vitals.hpp = 40
    local cmd = ataxiaBasher_psionBashing()
    expect(has(cmd, "enact wrath;")).toBeTrue()
    expect(has(cmd, "enact roth")).toBeFalse()
    -- and it is what the package's own alias sends
    local f = io.open("src_new/aliases/levi_ataxia/for_levi/levi_062424/emulation/007_Wrath.lua")
    local s = f:read("*a"); f:close()
    expect(s:find('send("enact wrath")', 1, true) ~= nil).toBeTrue()
  end)

  it("without the boon: only below half health", function()
    reset()
    ataxia.vitals.hpp = 60
    expect(has(ataxiaBasher_psionBashing(), "enact wrath")).toBeFalse()
  end)

  it("with Roth: below 75% health", function()
    reset()
    psionRoth = true
    ataxia.vitals.hpp = 74
    expect(has(ataxiaBasher_psionBashing(), "enact wrath")).toBeTrue()
    reset()
    psionRoth = true
    ataxia.vitals.hpp = 75
    expect(has(ataxiaBasher_psionBashing(), "enact wrath")).toBeFalse()
  end)

  it("with Roth: again after 30s, not 2 minutes (user)", function()
    reset()
    psionRoth = true
    ataxia.vitals.hpp = 60
    expect(has(ataxiaBasher_psionBashing(), "enact wrath")).toBeTrue()
    clock = clock + 29
    expect(has(ataxiaBasher_psionBashing(), "enact wrath")).toBeFalse()
    clock = clock + 1
    expect(has(ataxiaBasher_psionBashing(), "enact wrath")).toBeTrue()
  end)

  it("without it the lockout is 2 minutes (user: \"probably at 2 minutes\")", function()
    reset()
    ataxia.vitals.hpp = 40
    ataxiaBasher_psionBashing()
    clock = clock + 119
    expect(has(ataxiaBasher_psionBashing(), "enact wrath")).toBeFalse()
    clock = clock + 1
    expect(has(ataxiaBasher_psionBashing(), "enact wrath")).toBeTrue()
  end)

  it("the recipe, the combo marks and the BOONS row are wired", function()
    local M = ataxia.mnemosyne
    if M and M.BOON_COMBO_RECIPES then
      local r = M.BOON_COMBO_RECIPES["Roth"]
      expect(r ~= nil).toBeTrue()
      expect(table.concat(r.unlocksFrom, ",")).toBe("Razor Clarity,Bloodletter's Fury")
    end
    local function slurp(p) local f = io.open(p); local s = f:read("*a"); f:close(); return s end
    local seed = slurp("src_new/scripts/levi_ataxia/levi/ataxia/mnemosyne/010_Boon_Seed.lua")
    expect(seed:find('"Bloodletter\'s Fury", "Razor Clarity",', 1, true) ~= nil).toBeTrue()
    local row = slurp("src_new/triggers/levi_ataxia/for_levi/leviticus/mnemosyne/106_Roth.lua")
    expect(row:find("if ataxiaBasher and ataxiaBasher.inMnemosyne then psionRoth = true end", 1, true) ~= nil).toBeTrue()
  end)
end)

-- =====================================================================================
-- RUPTURE BY THE GAME'S LINES (v4.7.361). User: "With bloodletter we should be using enact rupture
-- every time it is available."
describe("Bloodletter's Fury: rupture tracked from its own lines", function()
  local TL = dofile("src_new/tests/trigger_lib.lua")
  local P = "src_new/triggers/levi_ataxia/for_levi/leviticus/psion/"
  local UP = "Your vision sharpens, allowing you to perceive the locations of every vein and artery that lies beneath the skin."
  local ALREADY = "Your blows will already rupture veins and arteries."
  local DOWN = "Distractions reassert themselves, your mental clarity returning to mundane levels."
  local function rupture() return keepers(false) == "enact rupture;" end

  it("the three lines match their triggers, as the server wraps them", function()
    expect(TL.anyMatches(TL.patterns(P .. "007_Rupture_Up.lua"), TL.wrap(UP, 119)[1])).toBeTrue()
    expect(TL.anyMatches(TL.patterns(P .. "007_Rupture_Up.lua"), ALREADY)).toBeTrue()
    expect(TL.anyMatches(TL.patterns(P .. "008_Rupture_Down.lua"), DOWN)).toBeTrue()
  end)

  it("the up line stands the keeper down even with no gmcp defence", function()
    reset(); psionBloodletter = true
    dofile(P .. "007_Rupture_Up.lua")
    expect(rupture()).toBeFalse()
  end)

  it("the down line re-enacts on the very next round -- no hold left over", function()
    reset(); psionBloodletter = true
    expect(rupture()).toBeTrue()          -- sent; the 4s hold is stamped
    dofile(P .. "007_Rupture_Up.lua")
    dofile(P .. "008_Rupture_Down.lua")
    expect(rupture()).toBeTrue()          -- same second: the hold was cleared with the belief
  end)

  it("the belief expires, so a missed down line cannot park the keeper", function()
    reset(); psionBloodletter = true
    dofile(P .. "007_Rupture_Up.lua")
    clock = clock + 19
    expect(rupture()).toBeFalse()
    clock = clock + 1
    expect(rupture()).toBeTrue()
  end)

  -- v4.7.364: "Please highlight the enact rupture lines with a bold bright color"
  it("all three lines are highlighted, both rows of the wrapped one included", function()
    local H = TL.patterns("src_new/triggers/levi_ataxia/for_levi/leviticus/highlighting/067_Rupture_Highlight.lua")
    for _, w in ipairs({ 80, 100, 119 }) do
      for _, row in ipairs(TL.wrap(UP, w)) do expect(TL.anyMatches(H, row)).toBeTrue() end
    end
    expect(TL.anyMatches(H, UP)).toBeTrue()
    expect(TL.anyMatches(H, ALREADY)).toBeTrue()
    expect(TL.anyMatches(H, DOWN)).toBeTrue()
  end)

  it("without the boon, the lines change nothing", function()
    reset()
    dofile(P .. "008_Rupture_Down.lua")
    expect(keepers(false)).toBe("")
  end)
end)

-- Restore shared state for whoever runs after us (test files share one Lua state).
ataxiaTemp.psionRuptureUpAt = nil
psionRoth = nil
psionProphet = nil
ataxiaTemp.psionForesightAt, ataxiaTemp.psionForesightTry = nil, nil
gmcp.IRE.Target.Info = {}
ataxia.mnemosyne._denizenCount = realDenizenCount
denizens = nil
psionEarthquake = nil
ataxiaBasher.upheavalAt = nil
getEpoch = realEpoch
tempTimer = realTempTimer
psionBloodletter, psionRazorClarity, psionMindbreak, psionPanoply = nil, nil, nil, nil
psionPsiwave = nil
ataxiaTemp.psionKeepAt, ataxiaTemp.psionTranscendAt = nil, nil
ataxiaTemp.psionRothAt, ataxiaTemp.transcendence = nil, nil
ataxiaTemp.psionSecondskinAttempted = nil
target = nil
