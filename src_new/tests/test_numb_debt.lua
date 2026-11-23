--- test_numb_debt.lua -- the numbness debt (basher/016_Numb_Debt.lua, v4.7.512)
--
-- Loads the real module, the real basher functions and the real triggers. Every game line is
-- copied from kb/raw/live/kaido-numbness-cycles_2026-11-23.txt (the row is beside each line).
-- The health figures of the main scenario are the cycle of 11:14:54 in that file: 8 absorbed
-- hits, then 20041 -> 11450 in one blow.

local mock = require("mock_mudlet")
local TL = dofile("src_new/tests/trigger_lib.lua")

local TRIG = "src_new/triggers/levi_ataxia/for_levi/leviticus/highlighting/"
local T_UP, T_FADE = TRIG .. "060_Numb.lua", TRIG .. "074_Numb_Faded.lua"
local T_HIT, T_RECOVER = TRIG .. "075_Numb_Absorbed_Hit.lua", TRIG .. "076_Numb_Recovery.lua"

local L_UP = "You grit your teeth and will your pain out of existence."                 -- row 2
local L_HIT = "You smile as the blow falls painlessly on you."                           -- row 11
local L_FADE = "You cry out in agony as the effects of your numbness fade away and you feel your wounds once more." -- row 200
local L_READY = "You have recovered enough to numb your body once again."                -- row 266
local L_REFUSED = "You may not numb again so soon."                                      -- row 760

-- Everything this file replaces, restored at the end of the file.
local real = {
  getEpoch = getEpoch, ataxiaEcho = ataxiaEcho, recordIncoming = ataxiaBasher_recordIncoming,
  ataxia = ataxia, ataxiaTemp = ataxiaTemp, ataxiaBasher = ataxiaBasher, gmcp = gmcp, line = line,
  get_Battlerage = get_Battlerage, tableContains = table.contains,
  dmgSamples = ataxiaBasher_dmgSamples, incSamples = ataxiaBasher_incSamples,
}

local clock = 50000
getEpoch = function() return clock end
local echoes = {}
ataxiaEcho = function(s) echoes[#echoes + 1] = s end
get_Battlerage = get_Battlerage or function() end
table.contains = table.contains or function(t, v)
  if type(t) ~= "table" then return false end
  for _, x in pairs(t) do if x == v then return true end end
  return false
end

ataxia = { settings = { separator = ";" }, vitals = {}, afflictions = {}, defences = {} }
ataxiaBasher = {}
ataxiaTemp = {}
gmcp = { Room = { Info = { area = "Test Bashing Area" } } }

dofile("src_new/scripts/levi_ataxia/levi/ataxia/basher/001_Bashing_Functions.lua")
dofile("src_new/scripts/levi_ataxia/levi/ataxia/basher/016_Numb_Debt.lua")
local realIncoming = ataxiaBasher_recordIncoming

local fed
local function reset()
  clock = clock + 1000 -- every reading of an earlier test is older than SOURCE_AGE
  ataxiaTemp = {}
  echoes, fed = {}, {}
  mock.active_timers = {}
  ataxia.vitals = { hp = 20041, maxhp = 20061, hpp = 99 }
  ataxia.afflictions, ataxia.defences = {}, {}
  ataxiaBasher.enabled = true
  ataxiaBasher.fleeThresholdPct, ataxiaBasher.shieldThresholdPct, ataxiaBasher.dangerTTL = 25, 40, 6
  ataxiaBasher_dmgSamples, ataxiaBasher_incSamples = {}, {}
  ataxiaBasher_recordIncoming = function(n) fed[#fed + 1] = n; realIncoming(n) end
end

-- Run a trigger's real script on a real line. The mock has no `fg` or `deselect`: both are
-- display calls, stubbed for the one call and put back.
local function fire(path, text)
  local realFg, realDeselect = fg, deselect
  fg, deselect = function() end, function() end
  line = text
  local ok, err = pcall(dofile, path)
  fg, deselect = realFg, realDeselect
  if not ok then error(err, 0) end
end

describe("numbness debt: the size of one absorbed hit", function()
  it("is 60% of the mean of our typed hits; bleeding (raw) is no reading", function()
    reset()
    expect(ataxia_numbHitEstimate()).toBeNil()
    ataxia_numbNoteTyped(1000, "fire")
    ataxia_numbNoteTyped(2000, "physical cutting")
    expect(ataxia_numbHitEstimate()).toBe(900)
    ataxia_numbNoteTyped(50, "raw")
    expect(ataxia_numbHitEstimate()).toBe(900)
  end)

  it("a reading older than 120 s is not used", function()
    reset()
    ataxia_numbNoteTyped(1500, "fire")
    clock = clock + 121
    expect(ataxia_numbHitEstimate()).toBeNil()
  end)

  it("takes the larger of the typed reading and the last blow per hit", function()
    reset()
    ataxia_numbNoteTyped(1500, "fire")          -- 900 a hit
    ataxia_numbRaised()
    ataxia_numbAbsorbed(); ataxia_numbAbsorbed()
    ataxia_numbNoteDrop(3000, 20041, 17041)     -- the blow: 1500 a hit
    ataxia_numbFaded()
    expect(ataxia_numbHitEstimate()).toBe(1500)
  end)
end)

describe("numbness debt: a cycle", function()
  it("each absorbed hit is owed, and goes to the rate watchdog when it lands", function()
    reset()
    ataxia_numbNoteTyped(1500, "fire")
    ataxia_numbRaised()
    expect(ataxia_numbDebt()).toBe(0)
    ataxia_numbAbsorbed()
    ataxia_numbAbsorbed()
    expect(ataxia_numbDebt()).toBe(1800)
    expect(#fed).toBe(2)
    expect(fed[1]).toBe(900)
    expect(ataxia_numbDebtNote()).toBe(" [numb debt ~1800 HP]")
  end)

  it("the safeties read health minus the debt, and plain health with no debt", function()
    reset()
    expect(ataxia_effHp()).toBe(20041)
    expect(ataxia_effHpp()).toBe(99)
    ataxia_numbNoteTyped(1500, "fire")
    ataxia_numbRaised()
    ataxia_numbAbsorbed(); ataxia_numbAbsorbed()
    expect(ataxia_effHp()).toBe(18241)
    expect(ataxia_effHpp()).toBe(90)
    expect(ataxiaBasher_safeHp()).toBe(18241)
    expect(ataxiaBasher_safeHpp()).toBe(90)
  end)

  it("a debt above our health reads 1, never 0; an unknown reading stays unknown", function()
    reset()
    ataxia_numbNoteTyped(30000, "fire")
    ataxia_numbRaised()
    ataxia_numbAbsorbed(); ataxia_numbAbsorbed()
    expect(ataxia_effHp()).toBe(1)
    expect(ataxia_effHpp()).toBe(1)
    ataxia.vitals.hp, ataxia.vitals.hpp = 0, 0   -- blackout: 0 means "unknown"
    expect(ataxia_effHp()).toBe(0)
    expect(ataxia_effHpp()).toBe(0)
  end)

  it("the fall of health pays the debt: only the part it does not explain is new damage", function()
    reset()
    ataxia_numbNoteTyped(1500, "fire")
    ataxia_numbRaised()
    ataxia_numbAbsorbed(); ataxia_numbAbsorbed()
    expect(ataxia_numbNoteDrop(2000, 20041, 18041)).toBe(200)
    expect(ataxia_numbDebt()).toBe(0)
  end)

  it("outside a cycle a fall of health is all new damage", function()
    reset()
    expect(ataxia_numbNoteDrop(2000, 20041, 18041)).toBe(2000)
  end)

  it("a hit with no reading is unknown: no debt, and its blow goes to the net feed whole", function()
    reset()
    ataxia_numbRaised()
    ataxia_numbAbsorbed()
    local debt, unknown = ataxia_numbDebt()
    expect(debt).toBe(0)
    expect(unknown).toBe(1)
    expect(#fed).toBe(0)
    expect(ataxia_numbDebtNote()).toBe(" [numb debt unknown: 1 absorbed]")
    expect(ataxia_numbNoteDrop(900, 20041, 19141)).toBe(900)
  end)

  it("a typed line inside a cycle gives back what its fall of health paid", function()
    reset()
    ataxia_numbNoteTyped(1500, "fire")
    ataxia_numbRaised()
    ataxia_numbAbsorbed(); ataxia_numbAbsorbed()
    expect(ataxia_numbNoteDrop(50, 20041, 19991)).toBe(0) -- a bleeding tick, GMCP first
    expect(ataxia_numbDebt()).toBe(1750)
    ataxia_numbNoteTyped(50, "raw")                        -- "Health lost: 50 (raw)."
    expect(ataxia_numbDebt()).toBe(1800)
  end)

  it("an absorbed hit with no up line starts a cycle", function()
    reset()
    ataxia_numbNoteTyped(1500, "fire")
    ataxia_numbAbsorbed()
    expect(ataxia_numbDebt()).toBe(900)
  end)

  it("a cycle whose fade line never came ends after 12 s", function()
    reset()
    ataxia_numbNoteTyped(1500, "fire")
    ataxia_numbRaised()
    ataxia_numbAbsorbed()
    clock = clock + 11
    expect(ataxia_numbDebt()).toBe(900)
    clock = clock + 2
    expect(ataxia_numbDebt()).toBe(0)
    expect(ataxia_effHp()).toBe(20041)
  end)
end)

describe("numbness debt: the fade", function()
  it("the logged cycle, through the real triggers: health falls first, then the line", function()
    reset()
    ataxia_numbNoteTyped(1500, "fire")
    fire(T_UP, L_UP)
    for _ = 1, 8 do fire(T_HIT, L_HIT) end
    expect(ataxia_numbDebt()).toBe(7200)
    clock = clock + 9.7
    expect(ataxia_numbNoteDrop(8591, 20041, 11450)).toBe(1391)
    ataxia.vitals.hp, ataxia.vitals.hpp = 11450, 57
    expect(ataxia_effHp()).toBe(11450) -- between Char.Vitals and the line the debt is not counted twice
    fire(T_FADE, L_FADE)
    expect(#echoes).toBe(1)
    expect(echoes[1]).toBe("<orange_red>NUMB WORE OFF: -8591 HP<NavajoWhite> (20041 -> 11450, 42% of max)"
      .. " from 8 absorbed hits. Estimate was 7200.")
    expect(ataxia_numbDebt()).toBe(0)
  end)

  it("the line first, then the fall of health: the debt stands until it is paid", function()
    reset()
    ataxia_numbNoteTyped(1500, "fire")
    ataxia_numbRaised()
    ataxia_numbAbsorbed(); ataxia_numbAbsorbed()
    ataxia_numbFaded()
    expect(#echoes).toBe(0)
    expect(ataxia_numbDebt()).toBe(1800)
    expect(ataxia_numbNoteDrop(2000, 20041, 18041)).toBe(200)
    expect(#echoes).toBe(1)
    expect(echoes[1]).toBe("<orange_red>NUMB WORE OFF: -2000 HP<NavajoWhite> (20041 -> 18041, 9% of max)"
      .. " from 2 absorbed hits. Estimate was 1800.")
    expect(ataxia_numbDebt()).toBe(0)
    mock.fire_timers() -- the settled fade leaves no timer that speaks again
    expect(#echoes).toBe(1)
  end)

  it("a bleeding tick in the same second is not taken for the blow", function()
    reset()
    ataxia_numbNoteTyped(1500, "fire")
    ataxia_numbRaised()
    ataxia_numbAbsorbed(); ataxia_numbAbsorbed()
    ataxia_numbNoteDrop(2000, 20041, 18041)
    clock = clock + 0.2
    ataxia_numbNoteDrop(40, 18041, 18001)
    ataxia_numbFaded()
    expect(echoes[1]:find("-2000 HP", 1, true) ~= nil).toBeTrue()
  end)

  -- Review, v4.7.512: with the line first, a bleeding tick of the last second was taken for the
  -- blow; the cycle closed and the real blow went to the net feed whole.
  it("the line first, a bleeding tick just before it: the cycle waits for the real blow", function()
    reset()
    ataxia_numbNoteTyped(1500, "fire")
    ataxia_numbRaised()
    ataxia_numbAbsorbed(); ataxia_numbAbsorbed()
    expect(ataxia_numbNoteDrop(40, 20041, 20001)).toBe(0)
    clock = clock + 0.3
    ataxia_numbFaded()
    expect(#echoes).toBe(0)
    expect(ataxia_numbDebt()).toBe(1760)
    expect(ataxia_numbNoteDrop(2000, 20001, 18001)).toBe(240)
    expect(echoes[1]).toBe("<orange_red>NUMB WORE OFF: -2000 HP<NavajoWhite> (20001 -> 18001, 9% of max)"
      .. " from 2 absorbed hits. Estimate was 1800.")
  end)

  it("a fade with no fall of health says so after 1 s, and the debt ends", function()
    reset()
    ataxia_numbNoteTyped(1500, "fire")
    ataxia_numbRaised()
    ataxia_numbAbsorbed()
    ataxia_numbFaded()
    expect(#echoes).toBe(0)
    mock.fire_timers()
    expect(echoes[1]).toBe("<orange_red>NUMB WORE OFF<NavajoWhite>: 1 absorbed hit, but no fall of health seen within 1s.")
    expect(ataxia_numbDebt()).toBe(0)
  end)

  it("a fade with nothing absorbed says that too", function()
    reset()
    ataxia_numbRaised()
    ataxia_numbFaded()
    mock.fire_timers()
    expect(echoes[1]).toBe("<orange_red>NUMB WORE OFF<NavajoWhite>: nothing was absorbed, no health lost.")
  end)

  it("a hit with no estimate is named in the echo", function()
    reset()
    ataxia_numbRaised()
    ataxia_numbAbsorbed()
    ataxia_numbNoteDrop(900, 20041, 19141)
    ataxia_numbFaded()
    expect(echoes[1]).toBe("<orange_red>NUMB WORE OFF: -900 HP<NavajoWhite> (20041 -> 19141, 4% of max)"
      .. " from 1 absorbed hit. 1 had no estimate.")
  end)
end)

describe("numbness debt: the basher's alarm", function()
  -- The cycle of 11:14:54: one absorbed hit a second for 8 s, then 8591 health in one prompt.
  local function cycle()
    reset()
    ataxia_numbNoteTyped(1500, "fire")
    ataxia_numbRaised()
    for _ = 1, 8 do clock = clock + 1; ataxia_numbAbsorbed() end
    clock = clock + 1.7
  end

  it("the blow recorded whole reads as 4 s to live and trips the alarm (the old path)", function()
    cycle()
    ataxiaTemp.numb = nil                -- no debt known: the health falls as plain damage
    ataxiaBasher_recordDamage(8591)
    ataxia.vitals.hp, ataxia.vitals.hpp = 11450, 57
    expect(ataxiaBasher_isDamageRateExtreme()).toBeTrue()
    expect(ataxiaBasher_dangerLevel()).toBe("flee")
  end)

  it("through the debt the same blow is not an alarm, and the basher attacks", function()
    cycle()
    ataxiaBasher_recordDamage(ataxia_numbNoteDrop(8591, 20041, 11450))
    ataxia.vitals.hp, ataxia.vitals.hpp = 11450, 57
    expect(ataxiaBasher_isDamageRateExtreme()).toBeFalse()
    expect(ataxiaBasher_dangerLevel()).toBe("attack")
  end)

  it("a debt near our health is an alarm while the prompt still shows full health", function()
    reset()
    ataxia_numbNoteTyped(4000, "fire")   -- 2400 a hit
    ataxia_numbRaised()
    for _ = 1, 8 do clock = clock + 1; ataxia_numbAbsorbed() end
    expect(ataxia.vitals.hpp).toBe(99)
    expect(ataxia_effHp()).toBe(841)
    expect(ataxiaBasher_isDamageRateExtreme()).toBeTrue()
    expect(ataxiaBasher_dangerLevel()).toBe("flee")
  end)

  it("a debt alone, with no hit in the last 5 s, still gives the low-health answer", function()
    reset()
    ataxia_numbNoteTyped(8000, "fire")   -- 4800 a hit
    ataxia_numbRaised()
    for _ = 1, 4 do ataxia_numbAbsorbed() end
    clock = clock + 6
    expect(ataxiaBasher_isDamageRateExtreme()).toBeFalse()
    expect(ataxia_effHpp()).toBe(4)
    expect(ataxiaBasher_dangerLevel()).toBe("flee")
  end)

  it("with no numbness the alarm reads plain health as before", function()
    reset()
    ataxia.vitals.hp, ataxia.vitals.hpp = 4000, 20
    expect(ataxiaBasher_dangerLevel()).toBe("flee")
    ataxia.vitals.hp, ataxia.vitals.hpp = 20041, 99
    expect(ataxiaBasher_dangerLevel()).toBe("attack")
  end)
end)

describe("numb recovery", function()
  it("our own NUMB starts the recovery; the ready line ends it", function()
    reset()
    expect(ataxia_numbCooling()).toBeFalse()
    fire(T_UP, L_UP)
    expect(ataxia_numbCooling()).toBeTrue()
    clock = clock + 12
    expect(ataxia_numbCooling()).toBeTrue()
    fire(T_RECOVER, L_READY)
    expect(ataxia_numbCooling()).toBeFalse()
  end)

  it("a ready line that never came is given up 14 s after the up line", function()
    reset()
    ataxia_numbRaised(true)
    clock = clock + 13.9
    expect(ataxia_numbCooling()).toBeTrue()
    clock = clock + 0.2
    expect(ataxia_numbCooling()).toBeFalse()
  end)

  it("a refusal with no up line seen holds for 3 s", function()
    reset()
    fire(T_RECOVER, L_REFUSED)
    expect(ataxia_numbCooling()).toBeTrue()
    clock = clock + 2.9
    expect(ataxia_numbCooling()).toBeTrue()
    clock = clock + 0.2
    expect(ataxia_numbCooling()).toBeFalse()
  end)

  it("numbness from another source starts no recovery", function()
    reset()
    ataxia_numbRaised()
    expect(ataxia_numbCooling()).toBeFalse()
  end)
end)

describe("numb triggers: each pattern matches its own line and no other", function()
  local lines = { up = L_UP, hit = L_HIT, fade = L_FADE, ready = L_READY, refused = L_REFUSED }
  local owns = {
    [T_UP] = { up = true }, [T_HIT] = { hit = true }, [T_FADE] = { fade = true },
    [T_RECOVER] = { ready = true, refused = true },
  }
  for path, mine in pairs(owns) do
    it(path:match("([^/]+)$"), function()
      local pats = TL.patterns(path)
      for name, text in pairs(lines) do
        expect(TL.anyMatches(pats, text)).toBe(mine[name] == true)
      end
    end)
  end
end)

-- Restore (all test files share one Lua state).
pcall(function()
  getEpoch, ataxiaEcho, ataxiaBasher_recordIncoming = real.getEpoch, real.ataxiaEcho, realIncoming
  ataxia, ataxiaTemp, ataxiaBasher, gmcp, line = real.ataxia, real.ataxiaTemp, real.ataxiaBasher, real.gmcp, real.line
  get_Battlerage, table.contains = real.get_Battlerage, real.tableContains
  ataxiaBasher_dmgSamples, ataxiaBasher_incSamples = real.dmgSamples or {}, real.incSamples or {}
  mock.active_timers = {}
end)
