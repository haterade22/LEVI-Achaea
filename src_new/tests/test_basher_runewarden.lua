--- test_basher_runewarden.lua -- Runewarden PvE bashing + its Mnemosyne boons (v4.7.163)
-- Covers the Hammer and NAIL sowulu rune (2+ denizens, once per room, free queue so it
-- rides ahead of the swing) and the Falconer's Tactics falcon-rake cooldown scaling.
-- The Homebound raido sketch lives in the explorer (mnemosyne/008) and is validated live.

require("mock_mudlet")

target = 7
ataxia = {
  settings = { separator = ";" },
  vitals = { rage = 0, knight = "Sword and Board" },
  defences = {},
}
ataxiaBasher = {
  shielded = false, rageraze = false, falconRakeReady = true,
  battlerage = { Runewarden = { raze = "shiver 7" } },
}
ataxiaTemp = {}
gmcp = {
  Room = { Info = { area = "", num = 5 } },
  Char = { Status = { class = "Runewarden", level = "80 " }, Vitals = { ep = 100, maxep = 100 } },
  IRE = { Target = { Info = {} } },
}
function ataxiaEcho() end
function ataxiaBasher_assembleBattlerage() return "" end
function ataxiaBasher_rageAfford(rage, cost)
  return (tonumber(rage) or 0) >= (cost + (tonumber(ataxiaBasher.rageFloor) or 0))
end
local denizenAffs = {}
function ataxiaBasher_dsHasAff(id, aff) return denizenAffs[aff] == true end
local _epoch = getEpoch
local clock = 800000
getEpoch = function() return clock end

local denizens = 0
ataxia.mnemosyne = { _denizenCount = function() return denizens end }

local ok = pcall(dofile, "src_new/scripts/levi_ataxia/levi/ataxia/basher/002_Class_Bashing.lua")
if not ok then error("Failed to load class-bashing file") end

local function has(cmd, needle) return cmd:find(needle, 1, true) ~= nil end

local function reset()
  ataxiaBasher.shielded, ataxiaBasher.rageraze = false, false
  ataxiaBasher.falconRakeReady = true
  ataxiaBasher.sowuluAt = nil
  ataxia.vitals.rage, ataxia.vitals.knight = 0, "Sword and Board"
  ataxiaTemp = {}
  mnemHammerAndNail, mnemFalconersTactics = false, false
  mnemThunderclap = false
  ataxiaBasher.bisectAt = nil
  gmcp.Room.Info.num = 5
  gmcp.Room.Info.area = ""
  gmcp.IRE.Target.Info = {}
  ataxiaBasher.cullingBlade, ataxiaBasher.rageConserveThreshold = nil, nil
  ataxiaBasher.rageFloor = nil
  denizenAffs = {}
  denizens = 0
  clock = clock + 200
end

describe("Hammer and Nail -- the sowulu splash rune", function()
  it("does nothing without the boon", function()
    reset(); denizens = 3
    expect(ataxiaBasher_rwSowulu(";")).toBe("")
  end)

  it("needs a SECOND denizen -- the rune splashes onto another mob", function()
    reset(); mnemHammerAndNail = true; denizens = 1
    expect(ataxiaBasher_rwSowulu(";")).toBe("")
    reset(); mnemHammerAndNail = true; denizens = 2
    expect(ataxiaBasher_rwSowulu(";")).toBe("sketch sowulu on ground;")
  end)

  it("is once per ROOM -- the rune sits on this room's ground", function()
    reset(); mnemHammerAndNail = true; denizens = 3
    expect(ataxiaBasher_rwSowulu(";")).toBe("sketch sowulu on ground;")
    expect(ataxiaBasher_rwSowulu(";")).toBe("")   -- already sketched here
    gmcp.Room.Info.num = 6
    expect(ataxiaBasher_rwSowulu(";")).toBe("sketch sowulu on ground;")
  end)

  it("is laid BEFORE the swing, and does not displace it", function()
    reset(); mnemHammerAndNail = true; denizens = 3
    local cmd = ataxiaBasher_runewardenBashing()
    expect(has(cmd, "sketch sowulu on ground")).toBeTrue()
    expect(has(cmd, "combination 7 slice smash")).toBeTrue() -- SnB swing still happens
    expect(cmd:find("sketch") < cmd:find("combination")).toBeTrue()
  end)

  it("yields on a shielded round", function()
    reset(); mnemHammerAndNail = true; denizens = 3
    ataxiaBasher.shielded = true
    expect(ataxiaBasher_rwSowulu(";")).toBe("")
  end)

  it("honours a custom threshold", function()
    reset(); mnemHammerAndNail = true; denizens = 2
    ataxiaBasher.sowuluAt = 3
    expect(ataxiaBasher_rwSowulu(";")).toBe("")
    denizens = 3
    expect(ataxiaBasher_rwSowulu(";")).toBe("sketch sowulu on ground;")
  end)
end)

describe("ataxiaBasher_rwBattlerage -- the owned rotation", function()
  it("BULWARK first and with NO target gate -- it is Self, and the class's mitigation", function()
    reset(); ataxia.vitals.rage = 100; denizens = 1
    expect(ataxiaBasher_rwBattlerage(";")).toBe("bulwark;") -- solo mob: still fires
  end)

  it("ONSLAUGHT now fires at all -- it never could under the shared assembler", function()
    reset(); ataxia.vitals.rage = 100
    ataxiaTemp.rwBrAt = { bulwark = clock } -- bulwark held
    expect(has(ataxiaBasher_rwBattlerage(";"), "onslaught 7")).toBeTrue()
  end)

  it("falls to COLLIDE when onslaught is unaffordable", function()
    reset(); ataxia.vitals.rage = 20
    ataxiaTemp.rwBrAt = { bulwark = clock }
    expect(has(ataxiaBasher_rwBattlerage(";"), "collide 7")).toBeTrue()
  end)

  it("ETCH only when the denizen carries aeon or stun (it consumes one)", function()
    reset(); ataxia.vitals.rage = 100
    ataxiaTemp.rwBrAt = { bulwark = clock }
    expect(has(ataxiaBasher_rwBattlerage(";"), "etch rune at")).toBeFalse()
    reset(); ataxia.vitals.rage = 100; denizenAffs.aeon = true
    ataxiaTemp.rwBrAt = { bulwark = clock }
    expect(has(ataxiaBasher_rwBattlerage(";"), "etch rune at 7")).toBeTrue()
    reset(); ataxia.vitals.rage = 100; denizenAffs.stun = true
    ataxiaTemp.rwBrAt = { bulwark = clock }
    expect(has(ataxiaBasher_rwBattlerage(";"), "etch rune at 7")).toBeTrue()
  end)

  it("honours the AB cooldowns (bulwark 45s, onslaught/etch 23s, collide 16s)", function()
    reset(); ataxia.vitals.rage = 100
    expect(has(ataxiaBasher_rwBattlerage(";"), "bulwark")).toBeTrue()
    clock = clock + 4
    expect(has(ataxiaBasher_rwBattlerage(";"), "onslaught")).toBeTrue()
    clock = clock + 4
    expect(has(ataxiaBasher_rwBattlerage(";"), "collide")).toBeTrue()
    clock = clock + 4
    expect(ataxiaBasher_rwBattlerage(";")).toBe("") -- all stamped
    clock = clock + 20  -- collide (16s from t+8) and onslaught (23s from t+4) back
    expect(has(ataxiaBasher_rwBattlerage(";"), "onslaught")).toBeTrue()
    clock = clock + 30  -- 45s past the bulwark stamp
    expect(has(ataxiaBasher_rwBattlerage(";"), "bulwark")).toBeTrue()
  end)

  it("owns culling: reap outranks the rotation and ignores the rage floor", function()
    reset(); ataxia.vitals.rage = 36; ataxiaBasher.cullingBlade = true
    ataxiaBasher.rageFloor = 40
    expect(has(ataxiaBasher_rwBattlerage(";"), "reap 7")).toBeTrue()
  end)

  it("replays the pick across the re-queue loop", function()
    reset(); ataxia.vitals.rage = 100
    local first = ataxiaBasher_rwBattlerage(";")
    clock = clock + 1
    expect(ataxiaBasher_rwBattlerage(";")).toBe(first)
    expect(ataxiaTemp.rwBrAt.onslaught).toBe(nil)
  end)

  it("ETCH's own fire line releases the replay -- it had none, and cost two cycles", function()
    -- Live 2026-07-30: etch fired, then the 3s replay re-queued it twice and the
    -- server rejected both ("You must wait a short time before you can use a
    -- battlerage ability again."). Trigger 375 now confirms it from
    -- "You trace the outline of a rune in the air with <weapon>."
    reset(); ataxia.vitals.rage = 100; denizenAffs.stun = true
    ataxiaTemp.rwBrAt = { bulwark = clock }
    expect(has(ataxiaBasher_rwBattlerage(";"), "etch rune at 7")).toBeTrue()
    clock = clock + 1
    ataxiaBasher_rwConfirm("etch")
    expect(ataxiaTemp.rwBrPending).toBe(nil)
    expect(ataxiaTemp.rwBrAt.etch).toBe(clock)
  end)

  it("fire-line confirmation restamps bulwark from the LANDED moment", function()
    reset(); ataxia.vitals.rage = 100
    expect(has(ataxiaBasher_rwBattlerage(";"), "bulwark")).toBeTrue()
    clock = clock + 2
    ataxiaBasher_rwConfirm("bulwark")
    expect(ataxiaTemp.rwBrPending).toBe(nil)
    expect(ataxiaTemp.rwBrAt.bulwark).toBe(clock)
  end)
end)

describe("falcon rake -- rides every spec, and Falconer's Tactics shortens it", function()
  it("prepends the rake while it is off cooldown", function()
    reset()
    expect(has(ataxiaBasher_runewardenBashing(), "falcon rake 7")).toBeTrue()
    reset(); ataxiaBasher.falconRakeReady = false
    expect(has(ataxiaBasher_runewardenBashing(), "falcon rake")).toBeFalse()
  end)

  it("scales the missed-line safety timer 30s -> ~10s under the boon", function()
    local okc = pcall(dofile, "src_new/scripts/levi_ataxia/levi/ataxia/basher/005_Falcon_Cooldowns.lua")
    expect(okc).toBeTrue()
    if not okc then return end
    local seen
    local realTempTimer = tempTimer
    tempTimer = function(secs, _) seen = secs; return 1 end

    mnemFalconersTactics = false
    ataxiaBasher_falconRakeCooldown()
    expect(seen).toBe(30)

    mnemFalconersTactics = true
    ataxiaBasher_falconRakeCooldown()
    expect(math.floor(seen * 10 + 0.5) / 10).toBe(10.2) -- 30 * 0.34, -66%

    tempTimer = realTempTimer
    mnemFalconersTactics = false
  end)
end)


-- ---------------------------------------------------------------------------
-- Own-denizen matching: the substring rule cuts both ways (v4.7.169).
-- ---------------------------------------------------------------------------
describe("ataxiaBasher_isOwnDenizen -- pets vs real denizens that share a word", function()
  local okOwn = pcall(dofile, "src_new/scripts/levi_ataxia/levi/ataxia/basher/001_Bashing_Functions.lua")

  it("still shields the actual pets by keyword", function()
    if not okOwn then return end
    ataxiaBasher.ownDenizens = {"falcon", "baalzadeen", "ashbeast", "hyena"}
    ataxiaBasher.notOwnDenizens = {}
    expect(ataxiaBasher_isOwnDenizen("a razor-beaked falcon")).toBeTrue()
    expect(ataxiaBasher_isOwnDenizen("a daemonic hyena")).toBeTrue()
    expect(ataxiaBasher_isOwnDenizen("a blazing ashbeast")).toBeTrue()
  end)

  it("WOULD have shielded a real denizen -- this is the bug", function()
    if not okOwn then return end
    ataxiaBasher.ownDenizens = {"hyena"}
    ataxiaBasher.notOwnDenizens = {}
    expect(ataxiaBasher_isOwnDenizen("a slope-backed hyena")).toBeTrue() -- pre-fix behaviour
  end)

  it("the exemption WINS over the pet keyword", function()
    if not okOwn then return end
    ataxiaBasher.ownDenizens = {"hyena"}
    ataxiaBasher.notOwnDenizens = {"a slope-backed hyena"}
    expect(ataxiaBasher_isOwnDenizen("a slope-backed hyena")).toBeFalse() -- targetable again
    expect(ataxiaBasher_isOwnDenizen("a daemonic hyena")).toBeTrue()      -- the pet is untouched
  end)

  it("an exempt denizen survives the target-list purge", function()
    if not okOwn then return end
    ataxiaBasher.ownDenizens = {"hyena"}
    ataxiaBasher.notOwnDenizens = {"a slope-backed hyena"}
    ataxiaBasher.targetList = { ["Mnemosyne"] = {"a slope-backed hyena", "a daemonic hyena"} }
    local removed = ataxiaBasher_purgeOwnFromTargets()
    expect(removed).toBe(1)
    expect(ataxiaBasher.targetList["Mnemosyne"][1]).toBe("a slope-backed hyena")
  end)
end)

describe("mounts on the own-denizen list (v4.7.174)", function()
  local okOwn = pcall(dofile, "src_new/scripts/levi_ataxia/levi/ataxia/basher/001_Bashing_Functions.lua")
  local MOUNTS = { "black dardanic stallion", "lean grizzly bear", "war elephant",
                   "massive dire wolf", "withered crypt worm" }

  it("shields every mount by its full name", function()
    if not okOwn then return end
    ataxiaBasher.ownDenizens = MOUNTS
    ataxiaBasher.notOwnDenizens = {}
    expect(ataxiaBasher_isOwnDenizen("A black Dardanic stallion")).toBeTrue()
    expect(ataxiaBasher_isOwnDenizen("A lean grizzly bear")).toBeTrue()
    expect(ataxiaBasher_isOwnDenizen("A war elephant")).toBeTrue()
    expect(ataxiaBasher_isOwnDenizen("A massive dire wolf")).toBeTrue()
    expect(ataxiaBasher_isOwnDenizen("A withered crypt worm")).toBeTrue()
  end)

  it("does NOT shadow the bestiary -- the whole reason the keywords are full names", function()
    if not okOwn then return end
    ataxiaBasher.ownDenizens = MOUNTS
    ataxiaBasher.notOwnDenizens = {}
    -- Bare creature nouns as keywords would have shielded all of these.
    expect(ataxiaBasher_isOwnDenizen("a grizzly bear")).toBeFalse()
    expect(ataxiaBasher_isOwnDenizen("a dire wolf")).toBeFalse()
    expect(ataxiaBasher_isOwnDenizen("a crypt worm")).toBeFalse()
    expect(ataxiaBasher_isOwnDenizen("a rabid wolf")).toBeFalse()
    expect(ataxiaBasher_isOwnDenizen("a cave bear")).toBeFalse()
  end)

  it("stays exemptable if a real denizen ever does share a full name", function()
    if not okOwn then return end
    ataxiaBasher.ownDenizens = MOUNTS
    ataxiaBasher.notOwnDenizens = { "a wild war elephant" }
    expect(ataxiaBasher_isOwnDenizen("a wild war elephant")).toBeFalse() -- exemption wins
    expect(ataxiaBasher_isOwnDenizen("A war elephant")).toBeTrue()       -- the mount is safe
  end)
end)

describe("Thunderclap -- bisect becomes the crowd swing (v4.7.181)", function()
  it("does nothing without the boon, however many denizens", function()
    reset(); denizens = 5
    expect(ataxiaBasher_rwBisect(";")).toBe(nil)
  end)

  it("needs a SECOND denizen -- the third strike is what pays for the 4s balance", function()
    reset(); mnemThunderclap = true; denizens = 1
    expect(ataxiaBasher_rwBisect(";")).toBe(nil)
    reset(); mnemThunderclap = true; denizens = 2
    expect(ataxiaBasher_rwBisect(";")).toBe("bisect 7")
  end)

  it("honours a custom threshold", function()
    reset(); mnemThunderclap = true; denizens = 2
    ataxiaBasher.bisectAt = 3
    expect(ataxiaBasher_rwBisect(";")).toBe(nil)
    denizens = 3
    expect(ataxiaBasher_rwBisect(";")).toBe("bisect 7")
  end)

  it("yields on a shielded round -- bisect bypasses rebounding, not shields", function()
    reset(); mnemThunderclap = true; denizens = 4
    ataxiaBasher.shielded = true
    expect(ataxiaBasher_rwBisect(";")).toBe(nil)
  end)

  it("is inert in PvP (non-numeric target)", function()
    reset(); mnemThunderclap = true; denizens = 4
    target = "Somebody"
    expect(ataxiaBasher_rwBisect(";")).toBe(nil)
    target = 7
  end)

  it("REPLACES the swing (both spend balance) but keeps the free falcon rake", function()
    reset(); mnemThunderclap = true; denizens = 3
    local cmd = ataxiaBasher_runewardenBashing()
    expect(has(cmd, "bisect 7")).toBeTrue()
    expect(has(cmd, "combination 7 slice smash")).toBeFalse() -- the swing is displaced
    expect(has(cmd, "falcon rake 7")).toBeTrue()              -- a FREE pet order is not
  end)

  it("leaves the normal swing alone below the threshold", function()
    reset(); mnemThunderclap = true; denizens = 1
    local cmd = ataxiaBasher_runewardenBashing()
    expect(has(cmd, "combination 7 slice smash")).toBeTrue()
    expect(has(cmd, "bisect")).toBeFalse()
  end)
end)

-- Restore shared state for whoever runs after us (files share one Lua state).
mnemHammerAndNail, mnemFalconersTactics = false, false
mnemThunderclap = false
getEpoch = _epoch
target = nil
