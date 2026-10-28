--- test_prompt_targetinfo.lua -- the prompt's targetinfo tag with a partial IRE.Target.Info (v4.7.466)
--
-- IRE.Target.Info can arrive without hpperc. The old guard was `hpperc ~= "-1"`, which is true for
-- nil, so every prompt threw "attempt to concatenate field 'hpperc' (a nil value)".

require("mock_mudlet")

local savedTarget, savedGmcp, savedTemp = target, gmcp, ataxiaTemp
gmcp = gmcp or {}
ataxiaTemp = ataxiaTemp or {}

local ok, err = pcall(dofile, "src_new/scripts/levi_ataxia/levi/ataxia/012_Prompt_Substitution.lua")
if not ok then print("load error: " .. tostring(err)) end

describe("targetinfo prompt tag", function()
  it("does not throw when Target.Info has no hpperc", function()
    target = "rat"
    gmcp.IRE = { Target = { Info = {} } }
    ataxiaTemp.mobhealth = 1
    local ok2, out = pcall(ataxiaPromptTags["targetinfo"])
    expect(ok2).toBe(true)
    expect(out).toBe("<DimGrey>(<white>rat<DimGrey>)")
  end)

  it("shows hpperc when present", function()
    target = "rat"
    gmcp.IRE = { Target = { Info = { hpperc = "40%" } } }
    ataxiaTemp.mobhealth = 1
    expect(ataxiaPromptTags["targetinfo"]()).toBe("<DimGrey>(<white>rat<DimGrey>|<white>40%<DimGrey>)")
  end)

  it("hides a -1 reading", function()
    target = "rat"
    gmcp.IRE = { Target = { Info = { hpperc = "-1" } } }
    ataxiaTemp.mobhealth = 1
    expect(ataxiaPromptTags["targetinfo"]()).toBe("<DimGrey>(<white>rat<DimGrey>)")
  end)
end)

-- Restore shared state for whoever runs after us (files share one Lua state).
target, gmcp, ataxiaTemp = savedTarget, savedGmcp, savedTemp
