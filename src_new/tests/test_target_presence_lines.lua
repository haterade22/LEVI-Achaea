--- test_target_presence_lines.lua -- three tracker faults from the 2026-11-07 Serpent spar (Saibel)
--
-- 1. Trigger 641 read a "not here" refusal of OUR OWN command ("order adder kill Saibel", no adder
--    out) as "the target left". It set targetIshere = false and started the 1.4 s TargetOutOfRoom
--    timer, which erased afflictions she still had and reset V3 twice. Now the refusal changes
--    nothing while GMCP lists the target in the room.
-- 2. In herbs/005 (bloodroot/magnesium) an `else` closed `if matches[2] == target`. So the target's
--    own eat never set targetIshere, the plant clock or the herb prediction, and ANYONE ELSE's eat
--    erased our target's paralysis or slickness.
-- 3. Trigger 433 read 2 of the 5 masochism lines in that spar.
--
-- The tests run the REAL trigger and timer bodies through the REAL public API (017) and the REAL
-- V3 tracker (007, 008). Fight-log rows are cited as
-- kb/raw/logs/ours/2026-11-07_164635_Saibel.log:<row>. Every global that the loaded files create
-- or change is restored at the end (one shared Lua state for all test files).

local mock = require("mock_mudlet")
local before = {}
for k, v in pairs(_G) do before[k] = v end
local savedContains = table.contains
local savedStarts = string.starts

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
  "src_new/scripts/levi_ataxia/levi/ataxia/curing/002_Wide_Groups.lua",
  "src_new/scripts/levi_ataxia/levi/ataxia/affliction_tracking_core/007_Branching_State_Tracker.lua",
  "src_new/scripts/levi_ataxia/levi/ataxia/affliction_tracking_core/008_V3_Integration.lua",
}) do
  local ok, err = pcall(dofile, f)
  if not ok then error("Failed to load " .. f .. ": " .. tostring(err)) end
end
-- The real isTargeted (016). world() puts in an exact-name stub; the part-name tests use this one.
local realIsTargeted = isTargeted

-- table.contains is a Mudlet extension (tarAffed uses it); restored at the end.
table.contains = table.contains or function(t, v)
  for _, x in pairs(t) do if x == v then return true end end
  return false
end
-- string.starts is a Mudlet extension (the real isTargeted uses it); restored at the end.
string.starts = string.starts or function(s, p) return s:sub(1, #p) == p end

local TL = dofile("src_new/tests/trigger_lib.lua")
local LEVI = "src_new/triggers/levi_ataxia/for_levi/leviticus/"
local NO_HERE = LEVI .. "641_Target_no_here.lua"
local BLOODROOT = LEVI .. "herbs/005_Bloodroot_TEST.lua"
local MASOCHISM = LEVI .. "433_Masochism.lua"
local OUT_OF_ROOM = "src_new/timers/levi_ataxia/for_levi/levi_062424/my_timers/003_TargetOutOfRoom.lua"

local function body(path)
  local fh = assert(io.open(path, "r"))
  local src = fh:read("*a"); fh:close()
  return assert((loadstring or load)(src:match("%]%]%-%-\r?\n(.*)$")))
end
local NO_HERE_BODY, BLOODROOT_BODY = body(NO_HERE), body(BLOODROOT)
local MASOCHISM_BODY, OUT_OF_ROOM_BODY = body(MASOCHISM), body(OUT_OF_ROOM)

-- The three refusals 641 reads (fight log rows 289, 797 and 1168 give one each).
local REFUSALS = {
  "You cannot see that being here.",
  "Ahh, I am truly sorry, but I do not see anyone by that name here.",
  "You detect nothing here by that name.",
}

-- The world the triggers run in. Only what the loaded files do not provide is stubbed.
local now, events, timersOn, predicted, colours = 1000, {}, {}, {}, {}
local function world()
  now, events, timersOn, predicted, colours = 1000, {}, {}, {}, {}
  mock.reset()                          -- no timer from an earlier test may fire into this one
  getEpoch = function() return now end
  target = "Saibel"
  isTargeted = function(n) return type(n) == "string" and n:lower() == "saibel" end
  raiseEvent = function(e, a) events[#events + 1] = { e, a } end
  checkTargetLocks = function() end     -- curing/003, not loaded
  ataxiaEcho, zgui = function() end, nil
  fg = function(c) colours[#colours + 1] = c end   -- not in the mock; 005 colours the eat line
  enableTimer = function(n) timersOn[n] = true; return true end
  disableTimer = function(n) timersOn[n] = false; return true end
  predictBal = function(bal, t) predicted[#predicted + 1] = { bal, t } end
  confirmAffV2 = function() end         -- V2 (affliction_tracking_core/001), not loaded
  gmcp = { Char = { Status = { class = "Serpent" } } }
  ataxia = { playersHere = { "Saibel" } }
  ataxiaTemp = { tarAffTimers = {} }
  tAffs, affTimers = {}, {}
  tBals = { tree = true, focus = true, plant = true, timers = {} }
  targetIshere = true
  serpent, strikingHigh, tdeliverance, anorexiaFailsafe, passiveFailsafe = nil, nil, nil, nil, nil
  pendingBloodrootV1, bloodrootApplyTimerV1 = nil, nil
  affConfigV3.enabled = true
  resetStatesV3()
  if resetCureBalancesV3 then resetCureBalancesV3() end
end

local function refuse(text)
  line = text
  matches = { text }
  NO_HERE_BODY()
end

-- "<who> eats a magnesium chip." (fight log rows 323, 415, 554 ... 2000 for Saibel)
local function eat(who)
  line = who .. " eats a magnesium chip."
  matches = { line, who, "magnesium chip" }
  BLOODROOT_BODY()
end

local P = function(a) return getAffProbabilityV3(a) end
local function cured()
  local out = {}
  for _, ev in ipairs(events) do
    if ev[1] == "target cured aff" then out[#out + 1] = ev[2] end
  end
  return out
end
-- The plant timer that 005 starts. Found by its ID: V3's own herb balance is also a 1.3 s timer.
local function plantTimer()
  return tBals.timers.plant and mock.active_timers[tBals.timers.plant]
end

local ok, err = pcall(function()
describe("641: a 'not here' refusal while GMCP lists the target (2026-11-07 spar)", function()
  it("each of the three texts is what the trigger matches", function()
    local pats = TL.patterns(NO_HERE)
    for _, text in ipairs(REFUSALS) do expect(TL.anyMatches(pats, text)).toBeTrue() end
  end)

  it("with the target listed, a refusal changes nothing and starts no timer", function()
    for _, text in ipairs(REFUSALS) do
      world()
      refuse(text)
      expect(targetIshere).toBeTrue()
      expect(timersOn.TargetOutOfRoom).toBeNil()
    end
  end)

  it("the name compare ignores case (target 'saibel', GMCP 'Saibel')", function()
    world()
    target = "saibel"
    refuse(REFUSALS[3])
    expect(targetIshere).toBeTrue()
    expect(timersOn.TargetOutOfRoom).toBeNil()
  end)

  it("a part-name target ('t sai') with 'Saibel' listed: nothing changes, the name is not completed", function()
    world()
    target = "Sai"
    refuse(REFUSALS[1])
    expect(targetIshere).toBeTrue()
    expect(timersOn.TargetOutOfRoom).toBeNil()
    expect(target).toBe("Sai")
  end)

  it("target Kaiden with only Kai listed: Kai is someone else, so she is gone", function()
    world()
    target = "Kaiden"
    ataxia.playersHere = { "Kai" }
    refuse(REFUSALS[1])
    expect(targetIshere).toBeFalse()
    expect(timersOn.TargetOutOfRoom).toBeTrue()
  end)

  it("with the target not listed, the old reading holds: gone, and the timer starts", function()
    world()
    ataxia.playersHere = { "Someone" }
    refuse(REFUSALS[2])
    expect(targetIshere).toBeFalse()
    expect(timersOn.TargetOutOfRoom).toBeTrue()
  end)

  it("with no GMCP list, or a denizen target (a number), the old reading holds", function()
    world()
    ataxia.playersHere = nil
    refuse(REFUSALS[1])
    expect(targetIshere).toBeFalse()
    expect(timersOn.TargetOutOfRoom).toBeTrue()

    world()
    target = 123456
    refuse(REFUSALS[1])
    expect(targetIshere).toBeFalse()
    expect(timersOn.TargetOutOfRoom).toBeTrue()
  end)

  it("a listed target keeps her afflictions: no timer tick erases the paralysis", function()
    world()
    tarAffed("paralysis")
    refuse(REFUSALS[3])
    -- The timer never started. A tick would see targetIshere and switch itself off.
    OUT_OF_ROOM_BODY()
    expect(P("paralysis")).toBe(1)
    expect(tAffs.paralysis).toBeTrue()
  end)
end)

describe("005: the target's own magnesium eat (2026-11-07 spar)", function()
  it("sets targetIshere, spends the plant clock, starts its 1.3 s timer and predicts the herb", function()
    world()
    targetIshere = false
    tarAffed("paralysis")
    eat("Saibel")
    expect(targetIshere).toBeTrue()
    expect(tBals.plant).toBeFalse()
    expect(plantTimer() ~= nil).toBeTrue()
    expect(plantTimer().delay).toBe(1.3)
    expect(#predicted).toBe(1)
    expect(predicted[1][1]).toBe("herb")
    expect(predicted[1][2]).toBe(1.55)
  end)

  it("still cures her paralysis (V3 and tAffs agree)", function()
    world()
    tarAffed("paralysis")
    eat("Saibel")
    expect(P("paralysis")).toBe(0)
    expect(tAffs.paralysis).toBeFalse()
  end)

  -- The V1 chain's own timers had these delays: 0.5 s (paralysis + slickness, wait for an apply)
  -- and 0.3 s (prone backtrack). V3's timers are 1.3 s and are left alone here.
  local function v1Timers()
    local n = 0
    for _, t in pairs(mock.active_timers) do
      if t.delay == 0.5 or t.delay == 0.3 then n = n + 1 end
    end
    return n
  end
  -- Cure reports for one affliction. Every eat also reports anorexia (eating proves it absent).
  local function curedOf(aff)
    local n = 0
    for _, a in ipairs(cured()) do if a == aff then n = n + 1 end end
    return n
  end

  it("one eat takes ONE of paralysis and slickness (V3 branches; the V1 erase no longer takes the other)", function()
    world()
    tarAffed("paralysis", "slickness")
    eat("Saibel")
    expect(pendingBloodrootV1).toBeNil()
    expect(v1Timers()).toBe(0)           -- the old 0.5 s timer erased paralysis after V3's cure
    expect(math.abs(P("paralysis") + P("slickness") - 1) < 1e-6).toBeTrue()
    expect(curedOf("paralysis") + curedOf("slickness")).toBe(0)   -- a branched cure is a guess
  end)

  it("a certain cure is still reported once (the fight log's -tar row)", function()
    world()
    tarAffed("paralysis")
    eat("Saibel")
    expect(curedOf("paralysis")).toBe(1)
    expect(curedOf("slickness")).toBe(0)
    world()
    tarAffed("slickness")
    eat("Saibel")
    expect(P("slickness")).toBe(0)
    expect(curedOf("slickness")).toBe(1)
  end)

  -- A reported cure needs an affliction the tracker held before the eat (in tAffs, or at 30% or
  -- more), as for the tree (curing/002) and the passive (008). Saibel's eats and the curare that
  -- landed between them, kb/raw/logs/ours/2026-11-07_164635_Saibel.log:1860, :1894, :1909, :1950.
  it("one eat over separate branches reports only what was held: a 0.22 guess leaves in silence", function()
    world()
    tarAffed("paralysis", "slickness")
    eat("Saibel")                        -- :1860, paralysis 1/3, slickness 2/3
    tarAffed("paralysis")                -- :1894
    eat("Saibel")                        -- :1909, {slickness} 4/9, {paralysis} 2/9, {} 3/9
    expect(math.abs(P("paralysis") - 2 / 9) < 1e-6).toBeTrue()
    expect(math.abs(P("slickness") - 4 / 9) < 1e-6).toBeTrue()
    expect(tAffs.paralysis == true).toBeFalse()
    expect(tAffs.slickness).toBeTrue()
    events = {}
    eat("Saibel")                        -- :1950
    expect(P("paralysis")).toBe(0)
    expect(P("slickness")).toBe(0)
    expect(curedOf("paralysis")).toBe(0)
    expect(curedOf("slickness")).toBe(1)
  end)

  it("two held afflictions in separate branches both report (Saibel:1483, 0.32 and 0.68)", function()
    world()
    tarAffed("paralysis", "slickness")
    eat("Saibel")
    events = {}
    eat("Saibel")
    expect(curedOf("paralysis")).toBe(1)
    expect(curedOf("slickness")).toBe(1)
  end)

  it("prone starts no backtrack, so no slickness that was never there is added", function()
    world()
    tarAffed("paralysis", "prone")
    eat("Saibel")
    expect(v1Timers()).toBe(0)
    expect(P("paralysis")).toBe(0)
    expect(P("slickness")).toBe(0)
  end)

  it("the plant timer gives the clock back", function()
    world()
    eat("Saibel")
    local t = plantTimer()
    local run = type(t.callback) == "string" and assert((loadstring or load)(t.callback)) or t.callback
    run()
    expect(tBals.plant).toBeTrue()
    expect(tBals.timers.plant).toBeNil()
  end)

  it("stops the TargetOutOfRoom chain: the next tick erases nothing and switches off", function()
    world()
    ataxia.playersHere = {}             -- a refusal with her not listed starts the timer
    tarAffed("paralysis", "asthma")
    refuse(REFUSALS[1])
    expect(timersOn.TargetOutOfRoom).toBeTrue()
    eat("Saibel")                        -- takes the paralysis, and proves her here
    OUT_OF_ROOM_BODY()                   -- the 1.4 s tick
    expect(timersOn.TargetOutOfRoom).toBeFalse()
    expect(P("asthma")).toBe(1)          -- the tick would have erased asthma next
    expect(tAffs.asthma).toBeTrue()
  end)

  it("a part-name target ('t sai') still gets the eat, and the name is completed (real isTargeted)", function()
    world()
    isTargeted = realIsTargeted
    target = "Sai"
    targetIshere = false
    tarAffed("paralysis")
    eat("Saibel")
    expect(target).toBe("Saibel")
    expect(P("paralysis")).toBe(0)
    expect(tAffs.paralysis).toBeFalse()
    expect(targetIshere).toBeTrue()
    expect(tBals.plant).toBeFalse()
    expect(#predicted).toBe(1)
  end)

  it("the eat line is red, the target's as before (no peru that the red replaces)", function()
    world()
    eat("Saibel")
    expect(#colours).toBe(1)
    expect(colours[1]).toBe("red")
    world()
    eat("Someone")
    expect(#colours).toBe(1)
    expect(colours[1]).toBe("red")
  end)
end)

describe("005: someone else's magnesium eat", function()
  it("leaves our target's paralysis, her presence and her plant clock alone", function()
    world()
    targetIshere = false
    tarAffed("paralysis")
    eat("Someone")
    expect(P("paralysis")).toBe(1)
    expect(tAffs.paralysis).toBeTrue()
    expect(targetIshere).toBeFalse()
    expect(tBals.plant).toBeTrue()
    expect(#predicted).toBe(0)
    expect(#cured()).toBe(0)
  end)

  it("leaves our target's slickness alone", function()
    world()
    tarAffed("slickness")
    eat("Someone")
    expect(P("slickness")).toBe(1)
    expect(tAffs.slickness).toBeTrue()
    expect(#cured()).toBe(0)
  end)
end)

describe("433: the masochism lines (2026-11-07 spar and older logs)", function()
  -- Lines 1-3 are verbatim from the spar: gut at fight log rows 1329 and 1556, stomp at 1952, jaw
  -- at 1657 and 1810. Line 4 is verbatim from
  -- kb/raw/logs/2026-11-01_nikita_depthswalker-vs-serpent_win_X8pRorzR.txt:6502.
  -- Lines 5 and 6 are CONSTRUCTED (no log has them): the male forms of the jaw and gut lines, to
  -- test the \w+ pronoun slots. They are not captured game text.
  local LINES = {
    "Saibel drives a clenched fist into her gut.",
    "Saibel uses her right foot to stomp on her left as hard as possible.",
    "Saibel smiles as she rams her fist into her jaw.",
    "Archaeon uses his right foot to stomp on his left as hard as possible.",
    "Archaeon smiles as he rams his fist into his jaw.",       -- constructed
    "Archaeon drives a clenched fist into his gut.",           -- constructed
  }

  -- What the trigger captures as matches[2]. A real pattern of the trigger must match the line
  -- (else this raises), and that pattern's one capture is the first word, or the word after
  -- "The face of". trigger_lib does not return captures, so this rule reads them from the pattern.
  local function capture(l)
    for _, p in ipairs(TL.patterns(MASOCHISM)) do
      if TL.matches(p.pat, p.type, l) then
        if p.pat:sub(1, 7) == "^(\\w+) " then return l:match("^(%w+) ") end
        if p.pat:sub(1, 19) == "^The face of (\\w+) " then return l:match("^The face of (%w+) ") end
        error("no capture rule for the pattern " .. p.pat)
      end
    end
    error("no pattern matches: " .. l)
  end

  it("a pattern of the trigger matches each line", function()
    local pats = TL.patterns(MASOCHISM)
    for _, l in ipairs(LINES) do
      if not TL.anyMatches(pats, l) then error("no pattern matches: " .. l) end
    end
  end)

  it("no pattern matches our own first-person lines", function()
    local pats = TL.patterns(MASOCHISM)
    expect(TL.anyMatches(pats, "You drive a clenched fist into your gut.")).toBeFalse()
    expect(TL.anyMatches(pats, "You use your right foot to stomp on your left as hard as possible.")).toBeFalse()
  end)

  it("the target's gut, stomp and jaw lines record masochism (captures from the real patterns)", function()
    for _, l in ipairs({ LINES[1], LINES[2], LINES[3] }) do
      world()
      line = l
      matches = { l, capture(l) }
      expect(matches[2]).toBe("Saibel")
      MASOCHISM_BODY()
      expect(P("masochism")).toBe(1)
      expect(tAffs.masochism).toBeTrue()
    end
  end)

  it("only the current target counts", function()
    world()
    line = LINES[4]
    matches = { line, capture(line) }
    expect(matches[2]).toBe("Archaeon")
    MASOCHISM_BODY()
    expect(P("masochism")).toBe(0)
    expect(tAffs.masochism).toBeNil()
  end)
end)
end)

mock.reset()
table.contains = savedContains
string.starts = savedStarts
-- Restore the shared Lua state: drop every global the loaded files created and put back every
-- one they replaced.
for k in pairs(_G) do
  if before[k] == nil then _G[k] = nil end
end
for k, v in pairs(before) do _G[k] = v end
if not ok then error(err) end
