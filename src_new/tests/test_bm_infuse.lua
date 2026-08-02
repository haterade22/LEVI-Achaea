--- test_bm_infuse.lua -- Blademaster infuse vs damage-suppression affixes (v4.7.186)
--
-- The tower can suppress a damage type for a whole ripple ("Null Magic: All magic damage you
-- deal is reduced by 33%."). Shindo INFUSE chooses which damage type our slashes deal, so
-- unlike most affixes this one can simply be stepped around.
--
-- The trap the mapping exists to avoid: VOID deals MAGIC and ICE deals COLD. A "Null Magic"
-- ripple must move us off VOID -- not off some element called "magic", which does not exist.

require("mock_mudlet")

target = 7
ataxia = { settings = { separator = ";" }, vitals = { rage = 0, class = 10 }, defences = {} }
ataxiaBasher = { shielded = false, rageraze = false,
                 battlerage = { Blademaster = { raze = "shin shatter 7" } } }
ataxiaTemp = {}
gmcp = { Room = { Info = { area = "", num = 5 } },
         Char = { Status = { class = "Blademaster", level = "80 " } } }
function ataxiaEcho() end
-- The Bard path runs the shared battlerage assembler, which reads a pile of login-time
-- globals we do not care about here. Stub it, exactly as test_basher_runewarden.lua does.
-- Declared AFTER the dofile below would be too late for load order, so it is re-asserted
-- there: an earlier test file dofile-ing 001_Bashing_Functions.lua replaces this stub with
-- the real function, and files share one Lua state.
function ataxiaBasher_assembleBattlerage() return "" end

-- Minimal mnemosyne surface: the picker asks by damage TYPE, never by affix name.
ataxia.mnemosyne = {
  damageNulled = function(t)
    local n = ataxiaTemp and ataxiaTemp.mnemNulled
    return n and t and n[t:lower()] or nil
  end,
}

local ok = pcall(dofile, "src_new/scripts/levi_ataxia/levi/ataxia/basher/002_Class_Bashing.lua")
if not ok then error("Failed to load class-bashing file") end
-- Re-assert after the load (see above): whichever test file ran first may have pulled in
-- the real assembler, and we want the stub for the Bard command-shape assertions.
function ataxiaBasher_assembleBattlerage() return "" end

local function nullify(...)
  ataxiaTemp.mnemNulled = {}
  for _, t in ipairs({...}) do ataxiaTemp.mnemNulled[t] = 33 end
end

local function reset()
  ataxiaTemp = {}
  ataxiaBasher.bmInfusePrefs = nil
end

describe("ataxiaBasher_bmInfuse -- stepping around a suppressed damage type", function()
  it("uses FIRE on a clean ripple -- unchanged from the hardcoded behaviour it replaced", function()
    reset()
    expect(ataxiaBasher_bmInfuse()).toBe("fire")
  end)

  it("ignores an affix that suppresses a type we were not using", function()
    reset(); nullify("magic")
    expect(ataxiaBasher_bmInfuse()).toBe("fire")
  end)

  it("moves off FIRE when fire damage is the suppressed type", function()
    reset(); nullify("fire")
    expect(ataxiaBasher_bmInfuse()).toBe("lightning")
  end)

  it("knows VOID deals MAGIC -- the mapping that makes this non-obvious", function()
    reset(); nullify("fire", "electricity", "cold")
    -- Only void is left, and it must be found by its DAMAGE TYPE, not its name.
    expect(ataxiaBasher_bmInfuse()).toBe("void")
    reset(); nullify("fire", "electricity", "cold", "magic")
    expect(ataxiaBasher_bmInfuse()).toBe("fire") -- all suppressed: fall back, never nil
  end)

  it("knows ICE deals COLD", function()
    reset(); nullify("fire", "electricity")
    expect(ataxiaBasher_bmInfuse()).toBe("ice")
  end)

  it("accepts the wording synonyms, since only 'magic' has been seen live", function()
    for _, word in ipairs({"electricity", "electric", "lightning"}) do
      reset(); nullify("fire", word)
      expect(ataxiaBasher_bmInfuse()).toBe("ice")
    end
    for _, word in ipairs({"cold", "ice", "frost"}) do
      reset(); nullify("fire", "electricity", word)
      expect(ataxiaBasher_bmInfuse()).toBe("void")
    end
    for _, word in ipairs({"magic", "void"}) do
      reset(); nullify("fire", "electricity", "cold", word)
      expect(ataxiaBasher_bmInfuse()).toBe("fire") -- nothing left; falls back
    end
  end)

  it("is case-insensitive about the captured type", function()
    reset(); nullify("FIRE")
    expect(ataxiaBasher_bmInfuse()).toBe("fire") -- table key is lower-cased by the parser
    reset()
    ataxiaTemp.mnemNulled = { fire = 33 }
    expect(ataxiaBasher_bmInfuse()).toBe("lightning")
  end)

  it("honours a custom preference order", function()
    reset()
    ataxiaBasher.bmInfusePrefs = { "ice", "fire" }
    expect(ataxiaBasher_bmInfuse()).toBe("ice")
    nullify("cold")
    expect(ataxiaBasher_bmInfuse()).toBe("fire")
  end)

  it("never returns nil -- an empty infuse would break the attack string", function()
    reset()
    ataxiaBasher.bmInfusePrefs = {}
    expect(ataxiaBasher_bmInfuse()).toBe("fire")
    ataxiaBasher.bmInfusePrefs = { "nonsense" }
    expect(ataxiaBasher_bmInfuse()).toBe("fire")
  end)

  it("survives the mnemosyne module being absent entirely (out of the tower)", function()
    reset()
    local saved = ataxia.mnemosyne
    ataxia.mnemosyne = nil
    expect(ataxiaBasher_bmInfuse()).toBe("fire")
    ataxia.mnemosyne = saved
  end)
end)


-- ---------------------------------------------------------------------------
-- The Bard twin: FLICK is psychic, PUNCTUATE is not, so a psychic-nulling
-- ripple should flip the same branch the manual toggle already used.
-- ---------------------------------------------------------------------------
describe("Bard flick vs punctuate under a psychic-nulling affix (v4.7.187)", function()
  local function bardAtk()
    gmcp.Char.Status.class = "Bard"
    ataxia.bardStuff = ataxia.bardStuff or {}
    return ataxiaBasher_bardBashing()
  end
  local function reset2()
    ataxiaTemp = {}
    ataxia.bardStuff = { bashPunctuate = false }
    bardWarmarch = false
    ataxiaBasher.shielded = false
  end

  it("flicks by default -- psychic is fine on a clean ripple", function()
    reset2()
    local cmd = bardAtk()
    expect(cmd:find("blade flick", 1, true) ~= nil).toBeTrue()
  end)

  it("switches to PUNCTUATE when psychic damage is suppressed", function()
    reset2(); nullify("psychic")
    local cmd = bardAtk()
    expect(cmd:find("blade punctuate", 1, true) ~= nil).toBeTrue()
    expect(cmd:find("blade flick", 1, true)).toBe(nil)
  end)

  it("overrides the Warmarch flick, whose whole value is +100% PSYCHIC", function()
    reset2(); bardWarmarch = true
    expect(bardAtk():find("blade flick", 1, true) ~= nil).toBeTrue()
    nullify("psychic")
    expect(bardAtk():find("blade punctuate", 1, true) ~= nil).toBeTrue()
    bardWarmarch = false
  end)

  it("ignores an affix suppressing some OTHER damage type", function()
    reset2(); nullify("magic", "fire")
    expect(bardAtk():find("blade flick", 1, true) ~= nil).toBeTrue()
  end)

  it("leaves the manual toggle authoritative", function()
    reset2(); ataxia.bardStuff.bashPunctuate = true
    expect(bardAtk():find("blade punctuate", 1, true) ~= nil).toBeTrue()
  end)
end)


describe("Divine Thunder Cataclysm -- the EQ room nuke that rides the swing (v4.7.190)", function()
  local shin = 100
  local function setup(n)
    ataxiaTemp = {}
    ataxiaBasher.shielded = false
    ataxiaBasher.thunderstormAt, ataxiaBasher.thunderstormReserve = nil, nil
    mnemDivineThunder = true
    shin = 100
    blademaster = { getShin = function() return shin end }
    ataxia.mnemosyne._denizenCount = function() return n end
  end

  it("does nothing without the boon", function()
    setup(5); mnemDivineThunder = false
    expect(ataxiaBasher_bmThunderstorm(";")).toBe("")
  end)

  it("needs THREE denizens -- higher than the balance-spending crowd swings", function()
    setup(2)
    expect(ataxiaBasher_bmThunderstorm(";")).toBe("")
    setup(3)
    expect(ataxiaBasher_bmThunderstorm(";")).toBe("shin thunderstorm;")
  end)

  it("needs the 30 shin, and honours a reserve for infuse/augment", function()
    setup(4); shin = 29
    expect(ataxiaBasher_bmThunderstorm(";")).toBe("")
    setup(4); shin = 30
    expect(ataxiaBasher_bmThunderstorm(";")).toBe("shin thunderstorm;")
    setup(4); shin = 30; ataxiaBasher.thunderstormReserve = 10
    expect(ataxiaBasher_bmThunderstorm(";")).toBe("")
  end)

  it("honours its 4s cooldown, and the fire line restamps it from the LANDED moment", function()
    setup(4)
    expect(ataxiaBasher_bmThunderstorm(";")).toBe("shin thunderstorm;")
    expect(ataxiaBasher_bmThunderstorm(";")).toBe("")  -- still cooling
    ataxiaTemp.bmThunderstormAt = (getEpoch() - 5)      -- window elapsed
    expect(ataxiaBasher_bmThunderstorm(";")).toBe("shin thunderstorm;")
    ataxiaBasher_bmThunderstormConfirm()                -- trigger 054's strike line
    expect(ataxiaTemp.bmThunderstormAt).toBe(getEpoch())
  end)

  it("yields on a shielded round", function()
    setup(5); ataxiaBasher.shielded = true
    expect(ataxiaBasher_bmThunderstorm(";")).toBe("")
  end)

  it("RIDES the swing rather than replacing it -- it is equilibrium, not balance", function()
    setup(4)
    gmcp.Char.Status.class = "Blademaster"
    local cmd = ataxiaBasher_blademasterBashing()
    expect(cmd:find("shin thunderstorm", 1, true) ~= nil).toBeTrue()
    expect(cmd:find("drawslash", 1, true) ~= nil).toBeTrue()   -- the balance swing survives
    expect(cmd:find("shin thunderstorm") < cmd:find("drawslash")).toBeTrue()
  end)
end)


describe("the affix sentence pattern tolerates wording variation (v4.7.191)", function()
  -- Mirrors trigger mnemosyne/053. Lua patterns cannot express the real PCRE regex, so this
  -- asserts the DECISION the captured type drives, using the types the live rows yield.
  it("STEEL SKIN suppresses physical -- and physical is not an infusable type", function()
    reset(); nullify("physical")
    -- None of fire/magic/electricity/cold is nulled, so the infuse pick is untouched.
    expect(ataxiaBasher_bmInfuse()).toBe("fire")
  end)

  it("physical alongside an infusable type still moves the infuse", function()
    reset(); nullify("physical", "fire")
    expect(ataxiaBasher_bmInfuse()).toBe("lightning")
  end)

  it("records every member of the family independently", function()
    reset(); nullify("magic", "psychic", "physical")
    local M = ataxia.mnemosyne
    expect(M.damageNulled("magic")).toBe(33)
    expect(M.damageNulled("psychic")).toBe(33)
    expect(M.damageNulled("physical")).toBe(33)
    expect(M.damageNulled("fire")).toBe(nil)
  end)
end)


describe("the four affixes seen live, by name (v4.7.192)", function()
  -- Null Magic (magic) / Blank Mind (psychic) / Steel Skin (physical) / Iceproof (cold).
  -- Only two of the four touch an infusable damage type, and that asymmetry is the point.
  it("ICEPROOF moves the infuse off ICE -- the first affix that actually hits the picker", function()
    reset(); nullify("cold")
    expect(ataxiaBasher_bmInfuse()).toBe("fire")     -- fire still first and unaffected
    reset(); nullify("fire", "cold")
    expect(ataxiaBasher_bmInfuse()).toBe("lightning")
    reset(); nullify("fire", "electricity", "cold")
    expect(ataxiaBasher_bmInfuse()).toBe("void")     -- must not fall back to the nulled ice
  end)

  it("NULL MAGIC moves it off VOID, not off some element named magic", function()
    reset(); nullify("fire", "electricity", "cold", "magic")
    expect(ataxiaBasher_bmInfuse()).toBe("fire")     -- everything nulled: falls back
    reset(); nullify("fire", "electricity", "magic")
    expect(ataxiaBasher_bmInfuse()).toBe("ice")
  end)

  it("STEEL SKIN and BLANK MIND do not touch the infuse -- neither type is infusable", function()
    reset(); nullify("physical", "psychic")
    expect(ataxiaBasher_bmInfuse()).toBe("fire")
  end)
end)

-- Restore shared state for whoever runs after us (files share one Lua state).
target = nil
ataxiaTemp = {}
bardWarmarch = false
mnemDivineThunder = false
blademaster = nil
