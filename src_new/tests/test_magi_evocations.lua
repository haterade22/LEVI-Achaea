-- test_magi_evocations.lua -- Evocation of Earth (quake) and Master of Four (simultaneity) in the
-- Magi bashing round (basher/002 ataxiaBasher_magiQuake, ataxiaBasher_magiMasterOfFour).
-- Clocks are stamped on the game's cast lines: 012_Fortify (simultaneity) and
-- magi_offense_tracking/021 (quake), run through their REAL patterns. One shared Lua state:
-- every global is restored at the end.

require("mock_mudlet")

local before = {}
for k, v in pairs(_G) do before[k] = v end

local TL = dofile("src_new/tests/trigger_lib.lua")
local LEV = "src_new/triggers/levi_ataxia/for_levi/leviticus/"
local QUAKE_FILE, FORT_FILE = LEV .. "magi_offense_tracking/021_Quake_Cast.lua", LEV .. "general/012_Fortify.lua"
local QUAKE_LINE = "Calling upon Garash, you summon a quake to sunder the ground beneath your feet."
local SIM_LINE = "You forge a channel through to the elemental skein of the universe."

local clock = 1000000
getEpoch = function() return clock end
target = "manticore"
ataxia = { settings = { separator = ";", sipping = { manause = 30 } },
           vitals = { mp = 10000, maxmp = 10000 }, defences = {} }
ataxiaBasher = { shielded = false }
ataxiaTemp = {}
local denizens = 0
ataxia.mnemosyne = { _denizenCount = function() return denizens end }
local sent = {}
send = function(c) sent[#sent + 1] = c end
function ataxiaBasher_assembleBattlerage() return "BRAGE" end

local loadErr
local okLoad, errLoad = pcall(dofile, "src_new/scripts/levi_ataxia/levi/ataxia/basher/002_Class_Bashing.lua")
if not okLoad then loadErr = tostring(errLoad) end
ataxiaBasher_stormhammer = function() end
ataxiaBasher_magiStormPrep = function() end
ataxiaBasher_magiShouldBloodboil = function() return false end

local function body(file)
  local fh = assert(io.open(file, "r"))
  local src = fh:read("*a"); fh:close()
  return assert((loadstring or load)(assert(src:match("%]%]%-%-\r?\n(.*)$"), "no header: " .. file), file))
end
local function deliver(file, line)
  if TL.anyMatches(TL.patterns(file), line) then body(file)(); return true end
  return false
end
local function has(s, part) return s:find(part, 1, true) ~= nil end
local function world(n)
  clock = 1000000
  mnemEvocationEarth, mnemMasterOfFour, mnemEvocationFire = true, true, false
  mnemWintersHeart, magiKkractle = false, false
  denizens = n
  ataxiaBasher = { shielded = false }
  ataxiaTemp = {}
  ataxia.vitals.mp, ataxia.vitals.maxmp = 10000, 10000
  sent = {}
end

local ok, err = pcall(function()
if loadErr then error(loadErr, 0) end

describe("Evocation of Earth: quake", function()
  it("no flag, one denizen, shielded -> none; two -> cast quake", function()
    world(2); mnemEvocationEarth = false
    expect(ataxiaBasher_magiQuake(";")).toBe("")
    world(1)
    expect(ataxiaBasher_magiQuake(";")).toBe("")
    world(3); ataxiaBasher.shielded = true
    expect(ataxiaBasher_magiQuake(";")).toBe("")
    world(2); mnemMasterOfFour = false
    expect(ataxiaBasher_magiQuake(";")).toBe("cast quake;")
    expect(ataxiaBasher_magiBashing()).toBe("BRAGE;cast quake")
  end)
  it("cast 10 s ago -> none; 31 s ago -> quake", function()
    world(2)
    expect(deliver(QUAKE_FILE, QUAKE_LINE)).toBe(true)
    clock = clock + 10
    expect(ataxiaBasher_magiQuake(";")).toBe("")
    clock = clock + 21
    expect(ataxiaBasher_magiQuake(";")).toBe("cast quake;")
  end)
  it("the real line fires only the quake pattern", function()
    expect(TL.anyMatches(TL.patterns(QUAKE_FILE), SIM_LINE)).toBe(false)
    expect(TL.anyMatches(TL.patterns(QUAKE_FILE), "The water flooding the location rapidly drains away into the cracks in the ground.")).toBe(false)
  end)
end)

describe("Master of Four: simultaneity", function()
  it("no flag, one denizen, shielded -> none; two -> simultaneity", function()
    world(2); mnemMasterOfFour = false
    expect(ataxiaBasher_magiMasterOfFour(";")).toBe("")
    world(1)
    expect(ataxiaBasher_magiMasterOfFour(";")).toBe("")
    world(3); ataxiaBasher.shielded = true
    expect(ataxiaBasher_magiMasterOfFour(";")).toBe("")
    world(2)
    expect(ataxiaBasher_magiMasterOfFour(";")).toBe("simultaneity;")
    expect(ataxiaBasher_magiBashing()).toBe("BRAGE;simultaneity")
  end)
  it("cast 10 s ago -> none; 31 s ago -> yes (stamped by the real 012_Fortify)", function()
    world(2)
    expect(deliver(FORT_FILE, SIM_LINE)).toBe(true)
    clock = clock + 10
    expect(ataxiaBasher_magiMasterOfFour(";")).toBe("")
    clock = clock + 21
    expect(ataxiaBasher_magiMasterOfFour(";")).toBe("simultaneity;")
  end)
  it("mana floor: 1000 mana may not take us below manause", function()
    world(2)
    ataxia.vitals.mp = 3999   -- 2999 left < 30% of 10000
    expect(ataxiaBasher_magiMasterOfFour(";")).toBe("")
    ataxia.vitals.mp = 4000
    expect(ataxiaBasher_magiMasterOfFour(";")).toBe("simultaneity;")
  end)
end)

describe("order and 012_Fortify", function()
  it("all three ready: simultaneity, then hellfumes, then quake", function()
    world(3); mnemEvocationFire = true
    expect(ataxiaBasher_magiBashing()).toBe("BRAGE;simultaneity")
    ataxiaTemp.simultaneityCastAt = clock
    expect(ataxiaBasher_magiBashing()).toBe("BRAGE;cast hellfumes")
    ataxiaTemp.evocationFireAt = clock
    expect(ataxiaBasher_magiBashing()).toBe("BRAGE;cast quake")
    ataxiaTemp.quakeCastAt = clock
    expect(has(ataxiaBasher_magiBashing(), "quake")).toBe(false)
  end)
  it("shielded: erode wins over all three", function()
    world(3); mnemEvocationFire = true; ataxiaBasher.shielded = true
    expect(has(ataxiaBasher_magiBashing(), "cast erode")).toBe(true)
  end)
  it("fortify and bind are skipped while autobash runs, sent otherwise", function()
    world(2); ataxiaBasher.enabled = true
    deliver(FORT_FILE, SIM_LINE)
    expect(#sent).toBe(0)
    expect(ataxia.defences.simultaneity).toBe(true)
    ataxiaBasher.enabled = false
    deliver(FORT_FILE, SIM_LINE)
    expect(sent[1]).toBe("queue add eqbal fortify all")
    expect(sent[2]).toBe("queue add eqbal bind all")
  end)
end)

end)

for k in pairs(_G) do
  if before[k] == nil then _G[k] = nil end
end
for k, v in pairs(before) do _G[k] = v end
if not ok then error(err) end
