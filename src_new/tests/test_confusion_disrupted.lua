--- test_confusion_disrupted.lua -- confused AND disrupted: cure confusion first, then concentrate
--- (v4.7.373)
--
-- User: "When we have the affliction confusion and are disrupted. We need to priority cure confusion
-- and concentrate right after curing it. Or else we never get EQ back." -- "CURING PRIOAFF <aff>".

require("mock_mudlet")

ataxia = ataxia or {}
ataxiaTemp = ataxiaTemp or {}
local realEcho, realSend, realEpoch, realAffs = ataxiaEcho, send, getEpoch, ataxia.afflictions
local sent, NOW = {}, 50000
ataxiaEcho = function() end
send = function(c) sent[#sent + 1] = c end
getEpoch = function() return NOW end

dofile("src_new/scripts/levi_ataxia/levi/ataxia/curing/004_Confusion_Disrupted.lua")

local function reset(affs)
  sent = {}
  NOW = NOW + 100
  ataxia.afflictions = affs or {}
  ataxiaTemp.conDisPrioAt, ataxiaTemp.conDisConcAt = nil, nil
end
local function count(cmd)
  local n = 0
  for _, c in ipairs(sent) do if c == cmd then n = n + 1 end end
  return n
end

describe("confused and disrupted (v4.7.373)", function()
  it("disrupted on top of confusion: prioaff confusion", function()
    reset({ confusion = true, disrupted = true })
    raiseEvent("aff gained", "disrupted")
    expect(count("curing prioaff confusion")).toBe(1)
  end)

  it("confusion on top of disrupted: the same", function()
    reset({ confusion = true, disrupted = true })
    raiseEvent("aff gained", "confusion")
    expect(count("curing prioaff confusion")).toBe(1)
  end)

  it("either one alone: nothing -- SSC handles it", function()
    reset({ disrupted = true })
    raiseEvent("aff gained", "disrupted")
    reset({ confusion = true })
    raiseEvent("aff gained", "confusion")
    expect(#sent).toBe(0)
  end)

  it("other afflictions arriving do not re-send it", function()
    reset({ confusion = true, disrupted = true, asthma = true })
    raiseEvent("aff gained", "asthma")
    expect(#sent).toBe(0)
  end)

  it("throttled: the full affliction list re-raises everything", function()
    reset({ confusion = true, disrupted = true })
    raiseEvent("aff gained", "confusion")
    raiseEvent("aff gained", "disrupted")
    expect(count("curing prioaff confusion")).toBe(1)
    NOW = NOW + 2
    raiseEvent("aff gained", "confusion")
    expect(count("curing prioaff confusion")).toBe(2)
  end)

  it("confusion cured while still disrupted: concentrate", function()
    reset({ disrupted = true })      -- the table is updated before "aff cured" is raised
    raiseEvent("aff cured", "confusion")
    expect(count("concentrate")).toBe(1)
  end)

  it("confusion cured and no longer disrupted: nothing", function()
    reset({})
    raiseEvent("aff cured", "confusion")
    expect(#sent).toBe(0)
  end)

  it("another cure while disrupted does not concentrate", function()
    reset({ disrupted = true, confusion = true })
    raiseEvent("aff cured", "asthma")
    expect(#sent).toBe(0)
  end)

  it("a cured stack (0) does not count as held", function()
    reset({ confusion = true, disrupted = 0 })
    raiseEvent("aff gained", "confusion")
    expect(#sent).toBe(0)
  end)
end)

-- Restore shared state for whoever runs after us (test files share one Lua state).
ataxiaEcho, send, getEpoch, ataxia.afflictions = realEcho, realSend, realEpoch, realAffs
ataxiaTemp.conDisPrioAt, ataxiaTemp.conDisConcAt = nil, nil
