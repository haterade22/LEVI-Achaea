--- test_reckless_prio.lua -- recklessness is cured first while bashing (2026-11-20)
--
-- From a death (2026-11-20, a manifested nightmare, Mnemosyne): recklessness made the prompt and
-- GMCP read full health (15696/100% while ~2743/17% was true). `gotUnknownAff` predicted it, but the
-- bash set cured pacifism (prio 3) before recklessness (prio 6), so the truth came out only at 17%.
-- While the basher is on, a believed recklessness now sends `curing prioaff recklessness` (a one-shot
-- server reordering that stores nothing), at most once per RECKLESS_PRIO_GAP seconds.
--
-- Loads the real 004_Aff_gains_losses. Every global set here is put back at the end (one Lua state).

require("mock_mudlet")

local SAVED = {}
local function setGlobal(name, value)
  if SAVED[name] == nil then SAVED[name] = { v = _G[name] } end
  _G[name] = value
end

local clock = 1000
local sent = {}
setGlobal("getEpoch", function() return clock end)
setGlobal("send", function(cmd) sent[#sent + 1] = cmd end)
setGlobal("tempLineTrigger", function() end)
table.contains = table.contains or function(t, val)
  for _, v in pairs(t) do if v == val then return true end end
  return false
end

-- 004's dependencies, as test_afflictions.lua stubs them.
setGlobal("Algedonic", {
  ApplySwaps = function() end, RestoreSwaps = function() end, Prioritize = function() end,
  Stack_My_Affs = function() end, Count_My_Affs = function() return 0 end, AffCount = 0,
})
for name, fn in pairs({
  ataxiaNDB_getClass = function() return "" end,
  ataxia_lockBreak = function() end,
  ataxia_boxEcho = function() end,
  ataxia_isClass = function() return false end,
  ataxia_tryVultureTalon = function() end,
  ataxia_facingClass = function() return "" end,
  retardationOn = function() end,
  ataxiaEcho = function() end,
  checkDamnationThreat = function() end,
  raiseEvent = function() end,
}) do setGlobal(name, fn) end
for _, name in ipairs({ "zgui", "mnemTruthseeker", "RECKLESS_PRIO_GAP" }) do setGlobal(name, nil) end

setGlobal("ataxia", { settings = { separator = ";" }, vitals = {}, afflictions = {}, defences = {} })
setGlobal("ataxiaBasher", { enabled = true })
setGlobal("ataxiaTemp", {})
setGlobal("ataxiaTables", {})
setGlobal("gmcp", { Char = { Afflictions = { Add = { name = "" } } } })

local okLoad, errLoad = pcall(dofile, "src_new/scripts/levi_ataxia/levi/ataxia/004_Aff_gains_losses.lua")

local PRIO = "curing prioaff recklessness"
local function count(cmd)
  local n = 0
  for _, c in ipairs(sent) do if c == cmd then n = n + 1 end end
  return n
end
local function reset()
  sent = {}
  clock = clock + 100
  ataxiaTemp = {}
  ataxia.afflictions = {}
  ataxiaBasher.enabled = true
end
local function gain(name)
  gmcp.Char.Afflictions.Add = { name = name }
  gotAff()
end

describe("2026-11-20 -- recklessness is cured first while bashing", function()
  it("loads the real 004", function()
    if not okLoad then error(tostring(errLoad), 0) end
  end)

  it("a GMCP gain of recklessness prioritises its cure, once per gap", function()
    reset()
    gain("recklessness")
    expect(count(PRIO)).toBe(1)
    clock = clock + 1
    gain("recklessness")
    expect(count(PRIO)).toBe(1)
    clock = clock + 4
    gain("recklessness")
    expect(count(PRIO)).toBe(2)
  end)

  it("the full-vitals prediction prioritises it too", function()
    reset()
    ataxia.vitals = { hp = 15696, maxhp = 15696, mp = 9000, maxmp = 9000 }
    gotUnknownAff()
    expect(count("curing predict recklessness")).toBe(1)
    expect(count(PRIO)).toBe(1)
    clock = clock + 0.5
    gotUnknownAff()                                       -- the next hidden affliction
    expect(count("curing predict recklessness")).toBe(2)
    expect(count(PRIO)).toBe(1)
  end)

  it("sends nothing with the basher off, and says why", function()
    reset()
    ataxiaBasher.enabled = false
    gain("recklessness")
    expect(count(PRIO)).toBe(0)
    local ok, why = ataxia_prioRecklessness("test")
    expect(ok).toBeFalse()
    expect(why).toBe("the basher is off")
  end)

  it("other afflictions do not prioritise it", function()
    reset()
    gain("pacifism")
    expect(count(PRIO)).toBe(0)
  end)
end)

for name, rec in pairs(SAVED) do _G[name] = rec.v end
