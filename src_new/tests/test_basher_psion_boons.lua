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

local function reset()
  clock = clock + 500
  timers = {}
  ataxia.defences = {}
  ataxia.vitals.hpp, ataxia.vitals.rage = 100, 0
  ataxiaBasher.shielded, ataxiaBasher.rageraze = false, false
  ataxiaBasher.psionKeepHold = nil
  psionBloodletter, psionRazorClarity, psionMindbreak = false, false, false
  psionPanoply = false
  ataxiaTemp.psionKeep_clarity, ataxiaTemp.psionKeep_rupturesight = nil, nil
  ataxiaTemp.psionRothAt = nil
  ataxiaTemp.psionTranscendAttempted, ataxiaTemp.psionSecondskinAttempted = true, true
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

  it("both boons together enact both, clarity first", function()
    reset()
    psionBloodletter, psionRazorClarity = true, true
    local out = keepers(false)
    expect(out).toBe("enact clarity;enact rupture;")
  end)
end)

describe("the keepers do not spam, and do not waste roth's free grant", function()
  it("holds after a send, and re-arms when the hold expires", function()
    reset()
    psionRazorClarity = true
    expect(keepers(false)).toBe("enact clarity;")
    expect(keepers(false)).toBe("")          -- still in flight
    fireTimers()
    expect(keepers(false)).toBe("enact clarity;")
  end)

  it("gives rupturesight a SHORTER hold -- it may be a three-blow charge, not a defence", function()
    reset()
    local holds = {}
    psionBloodletter, psionRazorClarity = true, true
    keepers(false)
    for _, t in ipairs(timers) do
      holds[#holds + 1] = t.at
    end
    table.sort(holds)
    expect(#holds).toBe(2)
    expect(holds[1] < holds[2]).toBeTrue()   -- the uncertain one is guarded for less time
  end)

  it("an explicit hold overrides both", function()
    reset()
    psionBloodletter, psionRazorClarity = true, true
    ataxiaBasher.psionKeepHold = 3
    keepers(false)
    for _, t in ipairs(timers) do expect(t.at).toBe(3) end
  end)

  -- ENACT ROTH grants clarity AND rupture free. Enacting them beside it spends equilibrium on
  -- something already on its way.
  it("stands down entirely on a round that fired roth", function()
    reset()
    psionBloodletter, psionRazorClarity = true, true
    expect(keepers(true)).toBe("")
    expect(ataxiaTemp.psionKeep_clarity).toBeNil()   -- and burns no hold doing it
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
    expect(cmd:find("enact roth", 1, true) ~= nil).toBeTrue()
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

  it("and the boon does not conjure a shatter below full transcendence", function()
    reset()
    psionMindbreak = true
    ataxiaTemp.transcendence = 90
    expect(ataxiaBasher_psionBashing():find("psi shatter", 1, true)).toBeNil()
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
  local FLAGS = { "psionBloodletter", "psionRazorClarity", "psionMindbreak" }

  it("the catalogue, under the names the game prints", function()
    local t = slurp(S .. "mnemosyne/004_Parsers.lua")
    expect(t:find('["Bloodletter\'s Fury"]', 1, true) ~= nil).toBeTrue()
    expect(t:find('["Razor Clarity"]', 1, true) ~= nil).toBeTrue()
    expect(t:find('["Mindbreak"]', 1, true) ~= nil).toBeTrue()
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

-- Restore shared state for whoever runs after us (test files share one Lua state).
getEpoch = realEpoch
tempTimer = realTempTimer
psionBloodletter, psionRazorClarity, psionMindbreak, psionPanoply = nil, nil, nil, nil
ataxiaTemp.psionKeep_clarity, ataxiaTemp.psionKeep_rupturesight = nil, nil
ataxiaTemp.psionRothAt, ataxiaTemp.transcendence = nil, nil
ataxiaTemp.psionTranscendAttempted, ataxiaTemp.psionSecondskinAttempted = nil, nil
target = nil
