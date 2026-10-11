--- test_infernal_group_lock.lua -- what the Infernal group lock sends (v4.7.407)
--
-- Two faults fixed together:
--  * An "impatience" step sent euphorbia, which gives NAUSEA. No venom gives impatience and
--    infestation no longer does (user, 2026-10-11), so it looped on euphorbia forever.
--  * The class lock "venom" was getLockingAffliction's SHORTHAND ("plague", "reckless", ...),
--    so against a Priest the lock envenomed with "plague". LOCK_DELIVERY now maps the lock
--    affliction to a venom or a Hellforge investment.
-- Globals are restored at the end.

local saved = {}
for _, k in ipairs({ "target", "tAffs", "affConfigV3", "getLockingAffliction", "knightSendAttack",
  "envenomList", "envenomListTwo", "cecho" }) do saved[k] = _G[k] end

ataxia = ataxia or {}
ataxia.settings = ataxia.settings or {}
assert(pcall(dofile, "src_new/scripts/levi_ataxia/levi/levi_scripts/dwc/002_Infernal_Group_Lock.lua"))

local LOCK = { Priest = "voyria", Depthswalker = "recklessness", Magi = "haemophilia",
  Psion = "confusion", Monk = "weariness", Alchemist = "stupidity", Shaman = "paralysis" }
local CLASS = "Priest"
getLockingAffliction = function(kind)
  if kind == "name" then return LOCK[CLASS] end
  return ({ voyria = "plague", recklessness = "reckless", stupidity = "stupid", paralysis = "paralyse" })[LOCK[CLASS]]
    or LOCK[CLASS]
end
affConfigV3 = nil
local sentAtk
knightSendAttack = function(a) sentAtk = a end
cecho = function() end

local function onTarget(cls, affs)
  CLASS, target, tAffs = cls, "Xarthus", {}
  for _, a in ipairs(affs or {}) do tAffs[a] = true end
end

local SOFT = { "asthma", "slickness", "anorexia" }

local ok, err = pcall(function()
describe("Infernal group lock", function()
  it("builds the softlock first: kalmia, then gecko, then slike", function()
    onTarget("Priest", {})
    expect((infernalGroupLock.selectVenoms())).toBe("kalmia")
    onTarget("Priest", { "asthma" })
    expect((infernalGroupLock.selectVenoms())).toBe("gecko")
    onTarget("Priest", { "asthma", "slickness" })
    expect((infernalGroupLock.selectVenoms())).toBe("slike")
  end)

  it("never sends euphorbia for impatience: after the softlock comes the class lock", function()
    onTarget("Priest", SOFT)   -- no impatience
    local v1, v2 = infernalGroupLock.selectVenoms()
    expect(v1).toBe("voyria")
    expect(v2).toBe("curare")
  end)

  it("sends a real venom, never getLockingAffliction's shorthand", function()
    for cls, want in pairs({ Priest = "voyria", Depthswalker = "eurypteria", Alchemist = "aconite" }) do
      onTarget(cls, SOFT)
      expect((infernalGroupLock.selectVenoms())).toBe(want)
    end
  end)

  it("uses Hellforge for weariness (exploit) and haemophilia (torture)", function()
    onTarget("Monk", SOFT)
    local v1, _, hf = infernalGroupLock.selectVenoms()
    expect(v1).toBe("exploit"); expect(hf).toBeTrue()
    onTarget("Magi", SOFT)
    v1, _, hf = infernalGroupLock.selectVenoms()
    expect(v1).toBe("torture"); expect(hf).toBeTrue()
  end)

  it("Psion's confusion has no delivery: it reinforces asthma instead", function()
    onTarget("Psion", SOFT)
    expect((infernalGroupLock.selectVenoms())).toBe("kalmia")
  end)

  it("the attack invests the right Hellforge and names it in the DSL", function()
    onTarget("Magi", SOFT)
    sentAtk = nil
    infernalGroupLockAttack()
    expect(sentAtk:find("hellforge invest torture;dsl Xarthus torture curare", 1, true) ~= nil).toBeTrue()
  end)
end)
end)

for k, v in pairs(saved) do _G[k] = v end
if not ok then error(err) end
