--- test_berserkers_edge.lua -- the Berserker's Edge Mnemosyne boon (v4.7.296)
--
-- "Your attacks deal 1% extra damage for each point of battlerage you possess, up to a maximum
-- of 100 rage." User: "we should keep our battlerage and not use it to maximize it."
--
-- Not a new system: this is `ataxiaBasher.rageFloor` (v4.7.141), pinned at the boon's own cap.
-- `ataxiaBasher_rageAfford` already gates all 37 rotation call sites, so setting the floor lands
-- the hold on every class with no per-rotation change. What these tests pin is the REVERT, since
-- this is a per-run boon mutating persistent config (the Borrowed Power shape, v4.7.204: "a
-- per-run boon that mutates persistent state needs its revert designed before its effect").

require("mock_mudlet")

target = 7
ataxia = { settings = { separator = ";" }, vitals = { rage = 0 }, defences = {}, afflictions = {} }
ataxiaBasher = { enabled = true, battlerage = {} }
ataxiaTemp = {}
gmcp = {
  Room = { Info = { area = "", num = 5 } },
  Char = { Status = { class = "Runewarden" }, Vitals = {} },
  IRE = { Target = { Info = {} } },
}
function ataxiaEcho() end
function bashConsoleEcho() end

local ok = pcall(dofile, "src_new/scripts/levi_ataxia/levi/ataxia/basher/001_Bashing_Functions.lua")
if not ok then error("Failed to load bashing functions") end

local function reset()
  ataxiaBasher.rageFloor = nil
  ataxiaBasher.rageFloorPreBerserkersEdge = nil
  ataxiaBasher.rageFloorSavedForBerserkersEdge = nil
  ataxiaTemp = {}
end

describe("Berserker's Edge pins the rage floor at the boon's own cap", function()
  it("sets the floor to 100 on apply", function()
    reset()
    ataxiaBasher_berserkersEdgeApply()
    expect(ataxiaBasher.rageFloor).toBe(100)
  end)

  -- The mechanism IS rageAfford: at 100 rage, any ability with a real cost needs rage >=
  -- cost + 100, which nothing can reach -- exactly "hold it, do not spend it".
  it("makes every non-exempt battlerage unaffordable while held", function()
    reset()
    ataxiaBasher_berserkersEdgeApply()
    expect(ataxiaBasher_rageAfford(100, 14)).toBeFalse()
    expect(ataxiaBasher_rageAfford(100, 36)).toBeFalse()
    expect(ataxiaBasher_rageAfford(100, 1)).toBeFalse()
  end)

  -- Culling stays exempt by the pre-existing, unrelated `floorCulling` toggle -- this boon
  -- neither touches nor needs to touch that decision.
  it("does not change culling's existing exemption", function()
    reset()
    ataxiaBasher_berserkersEdgeApply()
    expect(ataxiaBasher_cullAfford(36, 36)).toBeTrue()  -- exempt by default, unaffected
  end)
end)

describe("the revert restores exactly what was there before", function()
  it("restores an EXISTING floor a user had already set", function()
    reset()
    ataxiaBasher.rageFloor = 30
    ataxiaBasher_berserkersEdgeApply()
    expect(ataxiaBasher.rageFloor).toBe(100)
    ataxiaBasher_berserkersEdgeRevert()
    expect(ataxiaBasher.rageFloor).toBe(30)
  end)

  it("restores to OFF (nil) when there was no floor before", function()
    reset()
    ataxiaBasher_berserkersEdgeApply()
    ataxiaBasher_berserkersEdgeRevert()
    expect(ataxiaBasher.rageFloor).toBeNil()
  end)

  -- A second confirm -- the BOONS row after the claim, a mid-run `BOON CLAIMED` re-latch --
  -- must NOT overwrite the saved value with the boon's own 100. Getting this wrong means the
  -- revert restores 100 instead of the user's real prior setting.
  it("a second apply does not clobber the saved pre-boon value", function()
    reset()
    ataxiaBasher.rageFloor = 30
    ataxiaBasher_berserkersEdgeApply()   -- saves 30, sets 100
    ataxiaBasher_berserkersEdgeApply()   -- must NOT re-save (100) as the "pre-boon" value
    ataxiaBasher_berserkersEdgeRevert()
    expect(ataxiaBasher.rageFloor).toBe(30)
  end)

  -- Revert with nothing to revert (boon never held this run) must be a no-op, not an error and
  -- not a spurious floor change -- this is what makes it safe to call unconditionally at every
  -- run start as a defensive backstop.
  it("is a safe no-op when the boon was never applied", function()
    reset()
    ataxiaBasher.rageFloor = 30
    ataxiaBasher_berserkersEdgeRevert()
    expect(ataxiaBasher.rageFloor).toBe(30)
  end)

  it("is idempotent -- reverting twice does not error or change anything further", function()
    reset()
    ataxiaBasher.rageFloor = 30
    ataxiaBasher_berserkersEdgeApply()
    ataxiaBasher_berserkersEdgeRevert()
    local ok2 = pcall(ataxiaBasher_berserkersEdgeRevert)
    expect(ok2).toBeTrue()
    expect(ataxiaBasher.rageFloor).toBe(30)
  end)
end)

reset()
