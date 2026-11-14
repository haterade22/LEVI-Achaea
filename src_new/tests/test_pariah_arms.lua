--- test_pariah_arms.lua -- the Pariah offence with both of OUR arms out (2026-11-13).
-- Every Memorium record and the swarm commands STING, BURROW, INFEST, SCOURGE and LATENCY say `Requires arms: 1`:
-- the attacker needs at least one unbroken arm (the user). VIRULENCE states `Requires arms: 0` with Pre checks.
-- Loads the real self_limb_tracking/002 (ataxia_selfArmsOut), ataxia/007_Pariah_things and pariah/001_Pariah_Logic.

require("mock_mudlet")

local LIMB = "src_new/scripts/levi_ataxia/levi/ataxia/self_limb_tracking/002_Track_The_Damage.lua"
local THINGS = "src_new/scripts/levi_ataxia/levi/ataxia/ataxia/007_Pariah_things.lua"
local LOGIC = "src_new/scripts/levi_ataxia/levi/levi_scripts/pariah/001_Pariah_Logic.lua"

local saved = { target = target, ataxia = ataxia, ataxiaTemp = ataxiaTemp, haveAff = haveAff, tAffs = tAffs,
                combatQueue = combatQueue, send = send, checkAffList = checkAffList, cecho = cecho,
                getLockingAffliction = getLockingAffliction, checkTargetLocks = checkTargetLocks,
                getEpoch = getEpoch, reboundHold = reboundHold, taccelerates = taccelerates,
                pariah = pariah }

local held, sent, echoes, clock = {}, {}, {}, 1000
target = "Saibel"
pariah = nil  -- test_runner.lua sets pariah = "", and 007 starts with `pariah = pariah or {}`
tAffs = { bleed = 0 }
reboundHold = nil
ataxiaTemp = {}
ataxia = { settings = { separator = ";" }, afflictions = {}, vitals = { epitaph = 0 } }
haveAff = function(aff) return held[aff] or false end
checkAffList = function(list, n)
  local c = 0
  for _, a in ipairs(list) do if held[a] then c = c + 1 end end
  return c >= n
end
combatQueue = function() return "stand;" end
getLockingAffliction = function() end
checkTargetLocks = function() end
getEpoch = function() return clock end
send = function(cmd) sent[#sent + 1] = cmd end
cecho = function(s) echoes[#echoes + 1] = s end

for _, f in ipairs({ LIMB, THINGS, LOGIC }) do
  local ok, err = pcall(dofile, f)
  if not ok then error("Failed to load " .. f .. ": " .. tostring(err)) end
end

local function has(cmd, needle) return cmd:find(needle, 1, true) ~= nil end

local function reset(affs, onTarget)
  sent, echoes = {}, {}
  ataxia.afflictions = affs or {}
  held = onTarget or {}
  ataxiaTemp = {}
  pariah.state.virulenceTimer = nil
  pariah.state.bladePrepared = true
  taccelerates = 0
end

describe("ataxia_selfArmsOut", function()
  it("needs both arms, and counts broken, damaged and mangled", function()
    reset({ brokenleftarm = true })
    expect(ataxia_selfArmsOut()).toBeFalse()
    reset({ brokenleftarm = true, mangledrightarm = true })
    expect(ataxia_selfArmsOut()).toBeTrue()
    reset({ damagedleftarm = true, brokenrightarm = true })
    expect(ataxia_selfArmsOut()).toBeTrue()
    reset({ damagedleftleg = true, damagedrightleg = true })
    expect(ataxia_selfArmsOut()).toBeFalse()
  end)
end)

describe("pariah.dispatch with both arms out", function()
  local ARMS = { brokenleftarm = true, brokenrightarm = true }

  it("sends VIRULENCE alone when its plagues are up", function()
    reset(ARMS, { rebbies = true, sandfever = true, flushings = true, shield = true })
    pariah.dispatch()
    expect(#sent).toBe(1)
    expect(has(sent[1], "virulence Saibel")).toBeTrue()
    expect(has(sent[1], "trace")).toBeFalse()
    expect(has(sent[1], "swarm")).toBeFalse()
    expect(has(sent[1], "wield")).toBeFalse()
  end)

  it("sends nothing while VIRULENCE is on its delay, and says why", function()
    reset(ARMS, { rebbies = true, sandfever = true, flushings = true })
    pariah.state.virulenceTimer = 1
    pariah.dispatch()
    expect(#sent).toBe(0)
    expect(#echoes).toBe(1)
    expect(has(echoes[1], "delay")).toBeTrue()
  end)

  it("sends nothing without the plagues, and echoes at most once in 3 s", function()
    reset(ARMS, {})
    pariah.dispatch()
    pariah.dispatch()
    expect(#sent).toBe(0)
    expect(#echoes).toBe(1)
    clock = clock + 3.5
    pariah.dispatch()
    expect(#echoes).toBe(2)
  end)
end)

describe("pariah.dispatch with one arm out", function()
  it("keeps the normal round", function()
    reset({ brokenleftarm = true }, {})
    pariah.dispatch()
    expect(#sent).toBe(1)
    expect(has(sent[1], "wield left knife")).toBeTrue()
  end)
end)

for k, v in pairs(saved) do _G[k] = v end
