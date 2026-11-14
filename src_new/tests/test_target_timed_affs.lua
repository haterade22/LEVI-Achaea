--- test_target_timed_affs.lua -- timed afflictions expire from the target (v4.7.405)
--
-- Several timed afflictions never left the target in our tracking: the hamstring, airfist and
-- voidfist timers wrote `tAffs.x = nil`, which V3 copies its own belief back over; hellsight,
-- dazzle, muddled and resonance scalded had no timer; and three fade lines removed a name that
-- nothing sets (vinewreathe, bonds) or checked one (airfisted). Globals are restored at the end.

local saved = {}
for _, k in ipairs({ "tarAffed", "erAff", "tempTimer", "killTimer", "target", "isTargeted",
  "blademaster", "partyrelay", "matches" }) do saved[k] = _G[k] end
ataxia = ataxia or {}
ataxia.settings = ataxia.settings or {}
ataxia.afflictions = ataxia.afflictions or {}
local savedArtefacts = ataxia.settings.artefacts

assert(pcall(dofile, "src_new/scripts/levi_ataxia/levi/ataxia/017_Affliction_Management.lua"))
assert(pcall(dofile, "src_new/scripts/levi_ataxia/levi/ataxia/misc_scripts/033_Artefacts.lua"))

local added, erased, timers, killed = {}, {}, {}, {}
tarAffed = function(a) added[#added + 1] = a end
erAff = function(a) erased[#erased + 1] = a end
tempTimer = function(d, fn) timers[#timers + 1] = { d = d, fn = fn }; return #timers end
killTimer = function(id) killed[id] = true end

local function reset()
  added, erased, timers, killed = {}, {}, {}, {}
  ataxiaTemp = ataxiaTemp or {}
  ataxiaTemp.tarAffTimers = {}
  target = "Xarthus"
end

local function fire(i)
  if not killed[i] then timers[i].fn() end
end

local TRG = "src_new/triggers/levi_ataxia/for_levi/leviticus/"
local function src(f)
  local fh = assert(io.open(TRG .. f)); local s = fh:read("*a"); fh:close()
  return s:match("%]%]%-%-\r?\n(.*)$")
end

local ok, err = pcall(function()
describe("timed afflictions on the target", function()
  it("gives the affliction and expires it after the game's duration", function()
    reset()
    ataxia_tarAffTimed("hamstring")
    expect(added[1]).toBe("hamstring")
    expect(timers[1].d).toBe(10)
    fire(1)
    expect(erased[1]).toBe("hamstring")
  end)

  it("a repeat restarts the clock", function()
    reset()
    ataxia_tarAffTimed("dazzled")
    ataxia_tarAffTimed("dazzled")
    expect(killed[1]).toBeTrue()
    fire(1)
    expect(#erased).toBe(0)
    fire(2)
    expect(erased[1]).toBe("dazzled")
  end)

  -- 2026-11-08 deep review (F41): dazzle went in under the key "dazzle", a name neither the tree
  -- pool nor the head salve list knows, so no cure could ever take it. priest/003 now passes the
  -- game's word (test_v3_core_fixes pins that) and no shipped caller passes the old key. The
  -- rename is kept, and pinned here.
  it("the old key dazzle gives the game's dazzled, on the 60 s clock", function()
    reset()
    ataxia_tarAffTimed("dazzle")
    expect(added[1]).toBe("dazzled")
    expect(timers[1].d).toBe(60)
    fire(1)
    expect(erased[1]).toBe("dazzled")
  end)

  it("does not remove anything from a target we have since switched away from", function()
    reset()
    ataxia_tarAffTimed("hellsight")
    target = "Someoneelse"
    fire(1)
    expect(#erased).toBe(0)
  end)

  it("an explicit duration wins (waterbond depends on how cold the target is)", function()
    reset()
    ataxia_tarAffTimed("waterbond", 45)
    expect(timers[1].d).toBe(45)
  end)

  it("a fade line removes it now and cancels the clock", function()
    reset()
    ataxia_tarAffTimed("hamstring")
    ataxia_tarAffFaded("hamstring")
    expect(erased[1]).toBe("hamstring")
    expect(killed[1]).toBeTrue()
  end)

  it("the triggers use the helper, and add and remove the SAME name", function()
    expect(src("striking/002_Hamstring.lua"):find('ataxia_tarAffTimed("hamstring"', 1, true) ~= nil).toBeTrue()
    expect(src("striking/001_Hamstring_Fade.lua"):find('ataxia_tarAffFaded("hamstring")', 1, true) ~= nil).toBeTrue()
    expect(src("697_Vinewreathe.lua"):find('ataxia_tarAffTimed("vinewreathed")', 1, true) ~= nil).toBeTrue()
    expect(src("696_Vinewreathe_Poofed.lua"):find('ataxia_tarAffFaded("vinewreathed")', 1, true) ~= nil).toBeTrue()
    expect(src("other_things_fading/001_Water_Lord_Bonds.lua"):find('ataxia_tarAffFaded("waterbond")', 1, true) ~= nil).toBeTrue()
    for _, f in ipairs({ "464_Airfist.lua", "465_Voidfist.lua", "priest/006_Hellsight.lua", "priest/003_Dazzle.lua" }) do
      expect(src(f):find("ataxia_tarAffTimed", 1, true) ~= nil).toBeTrue()
      expect(src(f):find("tAffs%.%w+ = nil") == nil).toBeTrue()
    end
  end)
end)

-- v4.7.501: OUR hamstring lasts 10 + 5 s with the Blademaster eagle feather (power enhanced_shin;
-- the user, 2026-11-14). Another Blademaster's keeps the game's 10 s: we do not know their artefacts.
-- The trigger body runs as shipped; the scan record is the shape `aconfig artefact scan` saves.
describe("our hamstring with the eagle feather (striking/002)", function()
  local body = assert(loadstring(src("striking/002_Hamstring.lua")))
  local applied
  local function run(line, name, feather)
    reset()
    ataxia.settings.artefacts = { override = {}, powers = feather
      and { enhanced_shin = { id = "1", name = "an ethereal lightning eagle feather", level = "-" } } or {} }
    applied = "unset"
    blademaster = { onHamstringApplied = function(s) applied = s end }
    partyrelay = nil
    isTargeted = function(n) return n == target end
    target = name
    matches = { line, name }
    body()
  end
  -- kb/raw/logs/2026-08-19_leviticus_blademaster-vs-sentinel_loss_Sentinel.txt
  local OURS = "Ducking behind him, you strike at Grulk's hamstring with a rigid, practised grip."
  -- kb/raw/logs/2026-10-27_shikudo-group-mhaldor.txt
  local THEIRS = "Ducking behind her, Makaeyla strikes at Sadey's hamstring with a rigid, practised grip."

  it("our strike with the feather lasts 15 s, and the offence is told 15", function()
    run(OURS, "Grulk", true)
    expect(added[1]).toBe("hamstring")
    expect(timers[1].d).toBe(15)
    expect(applied).toBe(15)
  end)

  it("our strike without the feather lasts the game's 10 s", function()
    run(OURS, "Grulk", false)
    expect(timers[1].d).toBe(10)
    expect(applied).toBe(10)
  end)

  it("another Blademaster's strike lasts 10 s, though we own the feather", function()
    run(THEIRS, "Sadey", true)
    expect(timers[1].d).toBe(10)
    expect(applied).toBeNil()
  end)

  it("the feather switched off with aconfig artefact gives 10 s", function()
    run(OURS, "Grulk", true)
    reset()
    ataxia.settings.artefacts.override.enhanced_shin = "off"
    target = "Grulk"; matches = { OURS, "Grulk" }
    body()
    expect(timers[1].d).toBe(10)
  end)
end)

-- The Blademaster offence re-hamstrings when its own clock says the last one ran out.
describe("blademaster.selectPrepStrike uses the length it was told", function()
  it("a 15 s hamstring is not re-struck after 12 s; a 10 s one is", function()
    local savedBm, savedTime = blademaster, os.time
    local okb, errb = pcall(function()
      blademaster = nil
      dofile("src_new/scripts/levi_ataxia/levi/levi_scripts/blademaster/005_CC_BM_Ice.lua")
      blademaster.hasAff = function(a) return a == "hamstring" end
      local t = 1000
      os.time = function() return t end
      blademaster.onHamstringApplied(15)
      t = 1012
      expect(blademaster.selectPrepStrike() ~= "hamstring").toBeTrue()
      t = 1000
      blademaster.onHamstringApplied(nil)
      t = 1012
      expect(blademaster.selectPrepStrike()).toBe("hamstring")
    end)
    blademaster, os.time = savedBm, savedTime
    if not okb then error(errb) end
  end)
end)
end)

ataxia.settings.artefacts = savedArtefacts
for k, v in pairs(saved) do _G[k] = v end
if ataxiaTemp then ataxiaTemp.tarAffTimers = nil end
if not ok then error(err) end
