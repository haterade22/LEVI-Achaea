-- test_magi_hellfumes.lua -- Evocation of Fire (Mnemosyne boon): Magi bashing casts HELLFUMES when the
-- boon's once-per-30-s proc is ready and the room has a crowd (basher/002 ataxiaBasher_magiHellfumes).
--
-- The two clocks are stamped by triggers on the game's lines (magi_offense_tracking/019 cast line,
-- 020 proc line), never at build time. The REAL trigger bodies are run through their REAL patterns
-- (trigger_lib). The real 002 is loaded; the battlerage assembler, storm prep and bloodboil gate
-- (other files) are stubbed with markers. One shared Lua state: every global is restored at the end.

require("mock_mudlet")

local before = {}
for k, v in pairs(_G) do before[k] = v end

local TL = dofile("src_new/tests/trigger_lib.lua")
local TRG = "src_new/triggers/levi_ataxia/for_levi/leviticus/magi_offense_tracking/"
local CAST_FILE, PROC_FILE = TRG .. "019_Hellfumes_Cast.lua", TRG .. "020_Evocation_Fire_Proc.lua"
local CAST_LINE = "You coax an absolutely foul-smelling cloud of air from the bowels of the earth."
local PROC_LINE = "Elemental Fire manifests in a searing plume of Kkractle's wrath, scorching all around you in deadly smoke."

local clock = 1000000
getEpoch = function() return clock end

target = "manticore"
ataxia = { settings = { separator = ";" }, vitals = {}, defences = {} }
ataxiaBasher = { shielded = false }
ataxiaTemp = {}
local denizens = 0
ataxia.mnemosyne = { _denizenCount = function() return denizens end }
function ataxiaBasher_assembleBattlerage() return "BRAGE" end
function ataxiaBasher_magiStormPrep() end
function ataxiaBasher_magiShouldBloodboil() return false end

local loadErr
local okLoad, errLoad = pcall(dofile, "src_new/scripts/levi_ataxia/levi/ataxia/basher/002_Class_Bashing.lua")
if not okLoad then loadErr = tostring(errLoad) end

-- Defined in the other basher files (001); 002 calls them at run time. Set AFTER the load, which
-- redefines some of them.
ataxiaBasher_stormhammer = function() end
ataxiaBasher_magiStormPrep = function() end
ataxiaBasher_magiShouldBloodboil = function() return false end

local function body(file)
  local fh = assert(io.open(file, "r"))
  local src = fh:read("*a"); fh:close()
  return assert((loadstring or load)(assert(src:match("%]%]%-%-\r?\n(.*)$"), "no header: " .. file), file))
end
-- Deliver a game line through the trigger's real pattern; run its real body when it matches.
local function deliver(file, line)
  if TL.anyMatches(TL.patterns(file), line) then body(file)(); return true end
  return false
end
local function has(s, part) return s:find(part, 1, true) ~= nil end
local function world(flag, n)
  clock = 1000000
  mnemEvocationFire = flag
  denizens = n
  ataxiaBasher.shielded = false
  ataxiaBasher.hellfumesAt = nil
  ataxiaTemp = {}
  mnemWintersHeart, magiKkractle = false, false
end

local ok, err = pcall(function()
if loadErr then error(loadErr, 0) end

describe("Evocation of Fire: hellfumes in the Magi bashing round", function()
  it("no boon -> no hellfumes", function()
    world(false, 5)
    expect(ataxiaBasher_magiHellfumes(";")).toBe("")
    expect(has(ataxiaBasher_magiBashing(), "hellfumes")).toBe(false)
  end)

  it("one denizen -> none; two -> cast hellfumes in the round", function()
    world(true, 1)
    expect(ataxiaBasher_magiHellfumes(";")).toBe("")
    denizens = 2
    expect(ataxiaBasher_magiHellfumes(";")).toBe("cast hellfumes;")
    expect(ataxiaBasher_magiBashing()).toBe("BRAGE;cast hellfumes")
  end)

  it("a shielded denizen -> erode wins", function()
    world(true, 3)
    ataxiaBasher.shielded = true
    expect(ataxiaBasher_magiHellfumes(";")).toBe("")
    expect(has(ataxiaBasher_magiBashing(), "cast erode at manticore")).toBe(true)
  end)

  it("it outranks deepfreeze and elemental surge while the proc is ready", function()
    world(true, 3)
    mnemWintersHeart, magiKkractle = true, true
    expect(has(ataxiaBasher_magiBashing(), "hellfumes")).toBe(true)
    deliver(PROC_FILE, PROC_LINE)
    expect(has(ataxiaBasher_magiBashing(), "deepfreeze")).toBe(true)
  end)

  it("the proc 10 s ago -> none; 31 s ago -> yes", function()
    world(true, 3)
    expect(deliver(PROC_FILE, PROC_LINE)).toBe(true)
    clock = clock + 10
    expect(ataxiaBasher_magiHellfumes(";")).toBe("")
    clock = clock + 21
    expect(ataxiaBasher_magiHellfumes(";")).toBe("cast hellfumes;")
  end)

  it("a cast with no new proc holds the next one for 10 s", function()
    world(true, 3)
    deliver(PROC_FILE, PROC_LINE)
    clock = clock + 40
    expect(ataxiaBasher_magiHellfumes(";")).toBe("cast hellfumes;")
    expect(deliver(CAST_FILE, CAST_LINE)).toBe(true)   -- cast landed; no proc line followed
    clock = clock + 5
    expect(ataxiaBasher_magiHellfumes(";")).toBe("")
    clock = clock + 6
    expect(ataxiaBasher_magiHellfumes(";")).toBe("cast hellfumes;")
  end)

  it("a cast that procs does not hold: the proc line follows the cast line", function()
    world(true, 3)
    deliver(CAST_FILE, CAST_LINE)
    deliver(PROC_FILE, PROC_LINE)
    clock = clock + 31
    expect(ataxiaBasher_magiHellfumes(";")).toBe("cast hellfumes;")
  end)

  it("the real lines fire only their own trigger", function()
    expect(TL.anyMatches(TL.patterns(CAST_FILE), CAST_LINE)).toBe(true)
    expect(TL.anyMatches(TL.patterns(PROC_FILE), CAST_LINE)).toBe(false)
    expect(TL.anyMatches(TL.patterns(PROC_FILE), PROC_LINE)).toBe(true)
    expect(TL.anyMatches(TL.patterns(CAST_FILE), PROC_LINE)).toBe(false)
  end)

  it("the boon's BOONS row latches mnemEvocationFire through the generic table", function()
    local f = assert(io.open("src_new/scripts/levi_ataxia/levi/ataxia/mnemosyne/004_Parsers.lua", "r"))
    local src = f:read("*a"); f:close()
    expect(src:find('%["Evocation of Fire"%]%s*=%s*"mnemEvocationFire"') ~= nil).toBe(true)
  end)
end)

end)

for k in pairs(_G) do
  if before[k] == nil then _G[k] = nil end
end
for k, v in pairs(before) do _G[k] = v end
if not ok then error(err) end
