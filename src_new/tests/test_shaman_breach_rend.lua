-- test_shaman_breach_rend.lua -- Shaman "breach + soulrend" fashion burst (shamanOffense.canBreachRend)
--
-- Tip from ANOTHER PLAYER (Zax, log mtfwoA4F; unconfirmed by our logs): with manaleech + asthma up the
-- target cannot smoke manaleech off, so CURSE <t> BREACH INVOKE SOULREND (breach is the fast curse and
-- also charges jinx) piles up doll fashions. The burst replaces the regular "curse + invoke" slots only;
-- curseward stays first and a charged jinx still wins.
--
-- Loads the real 028_Shaman_Offense.lua. Files share ONE Lua state: every global touched here is saved
-- at the top and restored at the bottom (including the globals the file itself defines).

require("mock_mudlet")

local before = {}
for k, v in pairs(_G) do before[k] = v end

local saved = {
  target = target, shaman = shaman, ataxiaTemp = ataxiaTemp, tAffs = tAffs, tBals = tBals,
  curseCharge = curseCharge, combatQueue = combatQueue, haveAff = haveAff,
  haveAffV3 = haveAffV3, affConfigV3 = affConfigV3, shamanOffense = shamanOffense,
}

shamanOffense = nil -- load the file fresh
local ok, err = pcall(dofile, "src_new/scripts/levi_ataxia/levi/levi_scripts/shaman/028_Shaman_Offense.lua")
if not ok then error("Failed to load 028_Shaman_Offense.lua: " .. tostring(err)) end

local affs
local function reset(opts)
  opts = opts or {}
  target = "Nikolais"
  affs = { manaleech = true, asthma = true }
  for k, v in pairs(opts.affs or {}) do affs[k] = v end
  tAffs = {}
  tBals = {}
  affConfigV3, haveAffV3 = nil, nil
  haveAff = function(a) return affs[a] and true or false end
  combatQueue = function() return "" end
  curseCharge = 0
  ataxiaTemp = { canJinx = opts.canJinx }
  local bound = opts.bound or { maligus = true }
  shaman = { spiritisbound = function(s) return bound[s] and true or false end }
  shamanOffense.state.mode = opts.mode or "lock"
  shamanOffense.state.strategy = opts.strategy or "lock"
  shamanOffense.state.dollTarget = "Nikolais"
  shamanOffense.state.swiftFired = false
  shamanOffense.state.jinxUsedThisCycle = false
  shamanOffense.state.relapseTarget = nil
end

local BURST = "curse Nikolais breach invoke soulrend"

describe("Shaman breach + soulrend burst", function()
  it("fires at the lock slot with manaleech + asthma + maligus", function()
    reset({ strategy = "lock" })
    expect(shamanOffense.buildAttack()).toBe(BURST)
  end)

  it("fires at the pressure (group strategy) slot when the mode is not group", function()
    reset({ strategy = "group", mode = "lock" })
    curseCharge = nil -- the group slot is reached only when neither swiftcurse branch took the round
    expect(shamanOffense.buildAttack()).toBe(BURST)
  end)

  it("fires at the bleed slot", function()
    reset({ strategy = "bleed", mode = "bleed" })
    expect(shamanOffense.buildAttack()).toBe(BURST)
  end)

  it("does not need paralysis", function()
    reset({ affs = { paralysis = false } })
    expect(shamanOffense.canBreachRend()).toBeTrue()
  end)

  it("lock slot still resets the cycle state before the burst", function()
    reset()
    shamanOffense.state.swiftFired = true
    shamanOffense.state.jinxUsedThisCycle = true
    shamanOffense.buildAttack()
    expect(shamanOffense.state.swiftFired).toBeFalse()
    expect(shamanOffense.state.jinxUsedThisCycle).toBeFalse()
  end)

  it("asthma missing -> the normal curse", function()
    reset({ affs = { asthma = false } })
    expect(shamanOffense.canBreachRend()).toBeFalse()
    local atk = shamanOffense.buildAttack()
    expect(atk:find("breach", 1, true)).toBeNil()
    expect(atk:find("^curse Nikolais ") ~= nil).toBeTrue()
  end)

  it("manaleech missing -> the normal curse", function()
    reset({ affs = { manaleech = false } })
    expect(shamanOffense.canBreachRend()).toBeFalse()
    expect(shamanOffense.buildAttack():find("breach", 1, true)).toBeNil()
  end)

  it("maligus not bound -> no burst", function()
    reset({ bound = {} })
    expect(shamanOffense.canBreachRend()).toBeFalse()
    expect(shamanOffense.buildAttack():find("breach", 1, true)).toBeNil()
  end)

  it("group mode -> the normal curse (no doll, swiftcurse-first)", function()
    reset({ mode = "group", strategy = "group" })
    shamanOffense.state.dollTarget = "Nikolais"
    expect(shamanOffense.canBreachRend()).toBeFalse()
    expect(shamanOffense.buildAttack():find("breach", 1, true)).toBeNil()
  end)

  it("no doll on this target -> fashion first, not the burst", function()
    reset()
    shamanOffense.state.dollTarget = "Someone"
    expect(shamanOffense.canBreachRend()).toBeFalse()
    expect(shamanOffense.buildAttack()).toBe("fashion doll of Nikolais")
  end)

  it("curseward up -> plain curse breach", function()
    reset({ affs = { curseward = true } })
    expect(shamanOffense.buildAttack()).toBe("curse Nikolais breach")
  end)

  it("a charged jinx in the lock strategy still wins over the burst", function()
    reset({ canJinx = true })
    local atk = shamanOffense.buildAttack()
    expect(atk:find("jinx ", 1, true) ~= nil).toBeTrue()
    expect(atk:find("invoke soulrend", 1, true)).toBeNil()
  end)
end)

-- Restore
for k in pairs(_G) do
  if before[k] == nil then _G[k] = nil end
end
for k, v in pairs(before) do _G[k] = v end
target, shaman, ataxiaTemp, tAffs, tBals = saved.target, saved.shaman, saved.ataxiaTemp, saved.tAffs, saved.tBals
curseCharge, combatQueue, haveAff = saved.curseCharge, saved.combatQueue, saved.haveAff
haveAffV3, affConfigV3, shamanOffense = saved.haveAffV3, saved.affConfigV3, saved.shamanOffense
