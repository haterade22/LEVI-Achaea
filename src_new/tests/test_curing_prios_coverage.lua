--- test_curing_prios_coverage.lua -- every curable affliction the game lists has a priority (v4.7.402)
--
-- The game's AFFLICTION LIST (203) held 85 afflictions our table never named. 71 cannot be cured
-- by SSC (they wear off, or have no cure). These 14 can, and are now set deliberately rather than
-- left on a server default that can drift unseen. The three that differ from the server's own
-- default are the decisions most worth pinning.

require("mock_mudlet")
assert(pcall(dofile, "src_new/scripts/levi_ataxia/levi/ataxia/ataxia/001_Default_Curing_Prios.lua"))
local P = ataxia_defaultCuringPrios()

describe("curing priorities: the game's other curable afflictions", function()
  it("all 14 are in the table", function()
    for _, aff in ipairs({ "latched", "icebound", "calcifiedskull", "calcifiedtorso", "grievouswounds",
      "dazed", "frostbite", "kkractlebrand", "dazzled", "internalbleeding", "earworm", "fulminated",
      "diminished", "tonguetied" }) do
      if P[aff] == nil then error("no priority for " .. aff) end
    end
  end)

  it("the kill routes sit in the lethal band, not the reserved slot 1", function()
    expect(P.latched).toBe(2)
    expect(P.icebound).toBe(2)
  end)

  it("tonguetied only guards stuttering, so it sits just above it and below a damaged head", function()
    expect(P.tonguetied).toBe(P.stuttering - 1)
    expect(P.tonguetied > P.damagedhead).toBeTrue()
  end)

  it("dazzled (halves damage resistance) is cured, and before the head salve's lesser uses", function()
    expect(P.dazzled).toBe(7)
  end)
end)
