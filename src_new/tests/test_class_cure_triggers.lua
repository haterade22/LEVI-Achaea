--- test_class_cure_triggers.lua -- enemy class-cure triggers tell V3 the right thing (2026-10-10)
-- Found by cross-checking the triggers against the game's class-cure HELP file
-- (kb/afflictions/class-cures.md): Magi Harmony and Paladin Healing were gated to the wrong
-- class, Dragonheal erased two afflictions it does not prove absent, and Fire Lord Slough erased
-- weariness (its blocker is prone) behind a pattern too long to survive the server's wrap.
-- These tests run the REAL trigger bodies and patterns. Every global they stub is restored.

local TL = dofile("src_new/tests/trigger_lib.lua")
local DIR = "src_new/triggers/levi_ataxia/for_levi/leviticus/passive_active/"

-- Run a trigger body as Mudlet would for `ln`, with the target's class and V3 beliefs stubbed.
-- Returns every onClassCureV3 call and every passive cooldown started.
local function fire(file, ln, name, class, affs)
  local fh = assert(io.open(DIR .. file, "r"))
  local body = fh:read("*a"):match("%]%]%-%-\r?\n(.*)$")
  fh:close()
  local cures, cooldowns = {}, {}
  local stubs = {
    matches = { ln, name },
    line = ln,
    isTargeted = function(n) return n == name end,
    ataxiaNDB_getClass = function() return class end,
    haveAff = function(a) return (affs or {})[a] == true end,
    onClassCureV3 = function(specific, n) cures[#cures + 1] = { specific = specific, n = n } end,
    startPassiveCooldownV3 = function(k) cooldowns[#cooldowns + 1] = k end,
    selectString = function() end, fg = function() end, resetFormat = function() end,
    ataxiaTemp = {}, pariah = false, targetIshere = false,
  }
  local saved = {}
  for k, v in pairs(stubs) do saved[k] = _G[k]; _G[k] = v end
  local ok, err = pcall(assert((loadstring or load)(body)))
  for k in pairs(stubs) do _G[k] = saved[k] end
  if not ok then error(err) end
  return cures, cooldowns
end

local function patterns(file) return TL.patterns(DIR .. file) end

describe("Magi Harmony is tracked (029)", function()
  local CHIME = "A soft chiming emanates from Aegoth."

  it("the chiming line belongs to the Magi trigger, not the Bard one", function()
    expect(TL.anyMatches(patterns("029_Harmony_(Magi).lua"), CHIME)).toBeTrue()
    expect(TL.anyMatches(patterns("025_Hallelujah_(Bard).lua"), CHIME)).toBeFalse()
  end)

  it("a Magi's Harmony cures one random affliction and starts its cooldown", function()
    local cures, cds = fire("029_Harmony_(Magi).lua", CHIME, "Aegoth", "Magi", {})
    expect(#cures).toBe(1)
    expect(cures[1].specific).toBeNil()
    expect(cures[1].n).toBe(1)
    expect(cds[1]).toBe("passive_harmony")
  end)

  it("it takes voyria first, like every passive", function()
    local cures = fire("029_Harmony_(Magi).lua", CHIME, "Aegoth", "Magi", { voyria = true })
    expect(cures[1].specific[1]).toBe("voyria")
  end)

  it("the cooldown key exists, so the cooldown is actually recorded", function()
    local fh = assert(io.open("src_new/scripts/levi_ataxia/levi/ataxia/affliction_tracking_core/007_Branching_State_Tracker.lua"))
    local src = fh:read("*a"); fh:close()
    local tbl = src:match("passiveCooldownTimingsV3 = (%b{})")
    expect(tbl:match("\n%s+passive_harmony = %d") ~= nil).toBeTrue()
  end)

  it("a non-Magi chiming does nothing", function()
    local cures = fire("029_Harmony_(Magi).lua", CHIME, "Aegoth", "Bard", {})
    expect(#cures).toBe(0)
  end)
end)

describe("Paladin Healing is tracked (024)", function()
  local GLOW = "A gentle glow surrounds Alyzar."
  local ANGEL = "The guardian angel of Alyzar shimmers and he gives a sigh of relief."

  it("a Paladin's gentle glow is a passive cure", function()
    local cures, cds = fire("024_Healing_Rite_(Priest).lua", GLOW, "Alyzar", "Paladin", {})
    expect(#cures).toBe(1)
    expect(cures[1].n).toBe(1)
    expect(cds[1]).toBe("passive_healingrite")
  end)

  it("Angel Care stays Priest-only", function()
    expect(#fire("024_Healing_Rite_(Priest).lua", ANGEL, "Alyzar", "Paladin", {})).toBe(0)
    expect(#fire("024_Healing_Rite_(Priest).lua", ANGEL, "Alyzar", "Priest", {})).toBe(1)
  end)

  it("a Priest's glow is unchanged", function()
    expect(#fire("024_Healing_Rite_(Priest).lua", GLOW, "Alyzar", "Priest", {})).toBe(1)
  end)
end)

describe("Dragonheal proves 'not both', never 'neither' (005)", function()
  local KEEN = "Lii lets out a great keening, casting the impurities from her form."

  it("removes no specific affliction: weariness and recklessness block it only together", function()
    local cures = fire("005_Dragonheal.lua", KEEN, "Lii", "Dragon", { weariness = true })
    expect(#cures).toBe(1)
    expect(cures[1].specific).toBeNil()
  end)

  it("cures three, or one while prone", function()
    expect(fire("005_Dragonheal.lua", KEEN, "Lii", "Dragon", {})[1].n).toBe(3)
    expect(fire("005_Dragonheal.lua", KEEN, "Lii", "Dragon", { prone = true })[1].n).toBe(1)
  end)
end)

describe("Fire Lord Slough (016)", function()
  local FULL = "The fiery outer layers of Ignis fall away, turning to dust as they drift to the ground. "
    .. "Though Ignis seems diminished for an instant, his fires soon rage with fury once more."

  it("matches the first physical row of the wrapped line, at every measured width", function()
    local pats = patterns("016_Slough_(Fire_Lord).lua")
    for _, w in ipairs({ 100, 119, 124 }) do
      expect(TL.anyMatches(pats, TL.wrap(FULL, w)[1])).toBeTrue()
    end
  end)

  it("proves the target is not prone (its blocker), not that weariness is gone", function()
    local cures = fire("016_Slough_(Fire_Lord).lua", TL.wrap(FULL, 119)[1], "Ignis", "Firelord", {})
    expect(cures[1].specific[1]).toBe("prone")
    expect(#cures[1].specific).toBe(1)
    expect(cures[1].n).toBe(1)
  end)
end)
