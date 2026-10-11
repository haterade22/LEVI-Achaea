--- test_target_timed_affs.lua -- timed afflictions expire from the target (v4.7.405)
--
-- Several timed afflictions never left the target in our tracking: the hamstring, airfist and
-- voidfist timers wrote `tAffs.x = nil`, which V3 copies its own belief back over; hellsight,
-- dazzle, muddled and resonance scalded had no timer; and three fade lines removed a name that
-- nothing sets (vinewreathe, bonds) or checked one (airfisted). Globals are restored at the end.

local saved = {}
for _, k in ipairs({ "tarAffed", "erAff", "tempTimer", "killTimer", "target" }) do saved[k] = _G[k] end

assert(pcall(dofile, "src_new/scripts/levi_ataxia/levi/ataxia/017_Affliction_Management.lua"))

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
    ataxia_tarAffTimed("dazzle")
    ataxia_tarAffTimed("dazzle")
    expect(killed[1]).toBeTrue()
    fire(1)
    expect(#erased).toBe(0)
    fire(2)
    expect(erased[1]).toBe("dazzle")
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
    expect(src("striking/002_Hamstring.lua"):find('ataxia_tarAffTimed("hamstring")', 1, true) ~= nil).toBeTrue()
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
end)

for k, v in pairs(saved) do _G[k] = v end
if ataxiaTemp then ataxiaTemp.tarAffTimers = nil end
if not ok then error(err) end
