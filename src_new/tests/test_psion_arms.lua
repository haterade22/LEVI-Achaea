--- test_psion_arms.lua -- the Psion offence with both of OUR arms out (2026-11-13).
-- Every Weaving record but PREPARE, and every Emulation record, says `Requires arms: 1`: the attacker needs at
-- least one unbroken arm (the user). No Psionics record states an arm, so the round is the transcend alone.
-- Loads the real psion/001_Levi_Psion_Logic.lua.

require("mock_mudlet")

local file = "src_new/scripts/levi_ataxia/levi/levi_scripts/psion/001_Levi_Psion_Logic.lua"

local saved = { target = target, pm = pm, ataxia = ataxia, haveAff = haveAff, tAffs = tAffs,
                combatQueue = combatQueue, lightbind = lightbind, send = send }

local held, sent = {}, {}
target = "Saibel"
pm = 100
tAffs = {}
lightbind = false
combatQueue = nil
ataxia = { settings = { separator = ";" }, afflictions = {} }  -- no playersHere: the presence check is not under test
haveAff = function(aff) return held[aff] or false end
send = function(cmd) sent[#sent + 1] = cmd end

-- The arm test is the shared ataxia_selfArmsOut, so load its real file first.
local limbOk, limbErr = pcall(dofile, "src_new/scripts/levi_ataxia/levi/ataxia/self_limb_tracking/002_Track_The_Damage.lua")
if not limbOk then error("Failed to load the limb file: " .. tostring(limbErr)) end

local ok, err = pcall(dofile, file)
if not ok then error("Failed to load the Psion file: " .. tostring(err)) end

local function has(cmd, needle) return cmd:find(needle, 1, true) ~= nil end

local function reset(affs)
  held, sent = {}, {}
  pm = 100
  ataxia.afflictions = affs or {}
  psion.state.mode = "mind"
end

describe("psion.armsOut", function()
  it("is false with one arm working", function()
    reset({ brokenleftarm = true })
    expect(psion.armsOut()).toBeFalse()
  end)

  it("is true when both arms are broken, damaged or mangled", function()
    reset({ brokenleftarm = true, mangledrightarm = true })
    expect(psion.armsOut()).toBeTrue()
    reset({ damagedleftarm = true, brokenrightarm = true })
    expect(psion.armsOut()).toBeTrue()
  end)
end)

describe("psion.buildAttack with both arms out", function()
  it("sends the transcend alone, with no weave", function()
    reset({ brokenleftarm = true, brokenrightarm = true })
    local cmd = psion.buildAttack()
    expect(has(cmd, "psi transcend ")).toBeTrue()
    expect(has(cmd, "weave")).toBeFalse()
  end)

  it("sends no cleave into a shield", function()
    reset({ brokenleftarm = true, brokenrightarm = true })
    held.shield = true
    local cmd = psion.buildAttack()
    expect(has(cmd, "weave cleave")).toBeFalse()
    expect(has(cmd, "psi transcend ")).toBeTrue()
  end)

  it("still excises at 30% mana or less", function()
    reset({ brokenleftarm = true, brokenrightarm = true })
    pm = 25
    local cmd = psion.buildAttack()
    expect(has(cmd, "psi transcend excise Saibel")).toBeTrue()
    expect(has(cmd, "psi excise Saibel")).toBeTrue()
  end)

  it("leaves out the shield wield and lightbind", function()
    reset({ brokenleftarm = true, brokenrightarm = true })
    psion.sendAttack(psion.buildAttack())
    local all = table.concat(sent, "\n")
    expect(has(all, "wield right shield")).toBeFalse()
    expect(has(all, "enact lightbind")).toBeFalse()
    expect(has(all, "contemplate Saibel")).toBeTrue()
  end)
end)

describe("psion.buildAttack with one arm working", function()
  it("keeps the weave round", function()
    reset({ brokenleftarm = true })
    local cmd = psion.buildAttack()
    expect(has(cmd, "weave prepare")).toBeTrue()
  end)

  it("cleaves a shield", function()
    reset({ brokenrightarm = true })
    held.shield = true
    expect(has(psion.buildAttack(), "weave cleave Saibel")).toBeTrue()
  end)

  it("sends the shield wield and lightbind", function()
    reset({})
    psion.sendAttack(psion.buildAttack())
    local all = table.concat(sent, "\n")
    expect(has(all, "wield right shield")).toBeTrue()
    expect(has(all, "enact lightbind Saibel")).toBeTrue()
  end)
end)

-- Test files share one Lua state.
target, pm, ataxia, haveAff, tAffs = saved.target, saved.pm, saved.ataxia, saved.haveAff, saved.tAffs
combatQueue, lightbind, send = saved.combatQueue, saved.lightbind, saved.send
