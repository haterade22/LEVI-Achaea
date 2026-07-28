--- test_basher_dragon.lua -- Golden Dragon battlerage (v4.7.129 control rotation)
-- Verifies ataxiaBasher_goldenDragonBattlerage: Deaden/Psidaze control priority with
-- AB cooldowns (35s/41s), rage BANKING when a control cast is off cooldown but
-- unaffordable (the fillers must not starve it), Psiblast/Overwhelm damage fillers,
-- culling ownership, rage conservation -- and that ataxiaBasher_dragonBashing routes
-- Golden Dragon to it while other colours keep the generic assembler.

require("mock_mudlet")

-- Globals the dragon bashing path reads at call time.
target = "manticore"
ataxia = { settings = { separator = ";" }, vitals = { rage = 0 }, defences = {} }
ataxiaBasher = { shielded = false, rageraze = false,
                 battlerage = {
                   ["Golden Dragon"] = { raze = "psishatter " .. target },
                   ["Blue Dragon"]   = { raze = "glaciate " .. target },
                 } }
ataxiaTemp = {}
gmcp = {
  Room = { Info = { area = "" } },
  Char = { Status = { class = "Golden Dragon", level = "100 " } },
  IRE = { Target = { Info = {} } },
}
function ataxiaEcho() end

-- Controllable clock for the send-side cooldown stamps; restored at EOF (test files
-- share one Lua state).
local _epoch = getEpoch
local clock = 700000
getEpoch = function() return clock end

-- The generic assembler lives in 001 (loaded by an earlier test file) -- stub it with
-- a marker so we can PROVE which path each colour takes; restored at EOF.
local _assemble = ataxiaBasher_assembleBattlerage
local _breath = getDragonBreath
function ataxiaBasher_assembleBattlerage() return "GENERIC_BRAGE;" end
local breath = nil -- per-test breath element (nil disables the blast weave)
function getDragonBreath() return breath end

local file = "src_new/scripts/levi_ataxia/levi/ataxia/basher/002_Class_Bashing.lua"
local ok, err = pcall(dofile, file)
if not ok then error("Failed to load class-bashing file: " .. tostring(err)) end

local function has(cmd, needle) return cmd:find(needle, 1, true) ~= nil end

local function reset()
  ataxiaBasher.shielded, ataxiaBasher.rageraze = false, false
  ataxiaBasher.cullingBlade, ataxiaBasher.rageConserveThreshold = nil, nil
  ataxiaBasher.dragonBlast = nil
  ataxia.vitals.rage = 0
  ataxia.defences = {}
  ataxiaTemp = {}
  gmcp.IRE.Target.Info = {}
  gmcp.Room.Info.area = ""
  gmcp.Char.Status.class = "Golden Dragon"
  dragonMightSycaerunax = false
  breath = nil
  clock = 700000
end

describe("ataxiaBasher_goldenDragonBattlerage -- control-first rotation", function()
  it("fires Deaden > Psidaze > Psiblast > Overwhelm by priority (one pick per balance round)", function()
    reset(); ataxia.vitals.rage = 100
    expect(has(ataxiaBasher_goldenDragonBattlerage(";"), "deaden " .. target)).toBeTrue()
    clock = clock + 4 -- past the in-flight hold: the rotation may advance
    expect(has(ataxiaBasher_goldenDragonBattlerage(";"), "psidaze " .. target)).toBeTrue()
    clock = clock + 4
    expect(has(ataxiaBasher_goldenDragonBattlerage(";"), "psiblast " .. target)).toBeTrue()
    clock = clock + 4
    expect(has(ataxiaBasher_goldenDragonBattlerage(";"), "overwhelm " .. target)).toBeTrue()
    clock = clock + 4 -- t16: everything stamped and on cooldown
    expect(ataxiaBasher_goldenDragonBattlerage(";")).toBe("")
  end)

  it("replays the SAME pick across the 0.3s re-queue loop (review HIGH: no phantom burn)", function()
    reset(); ataxia.vitals.rage = 100
    local first = ataxiaBasher_goldenDragonBattlerage(";")
    expect(has(first, "deaden")).toBeTrue()
    clock = clock + 1 -- the basher re-assembles while balance is down...
    expect(ataxiaBasher_goldenDragonBattlerage(";")).toBe(first)
    clock = clock + 1
    expect(ataxiaBasher_goldenDragonBattlerage(";")).toBe(first)
    expect(ataxiaTemp.gdragonBrAt.psidaze).toBe(nil) -- ...and the rotation did NOT advance
    clock = clock + 4 -- hold expired: next pick
    expect(has(ataxiaBasher_goldenDragonBattlerage(";"), "psidaze")).toBeTrue()
  end)

  it("honours the AB cooldowns (deaden 35s, psidaze 41s, psiblast 23s, overwhelm 16s)", function()
    reset(); ataxia.vitals.rage = 100
    -- Stamp all four, one per simulated balance round: t0/t4/t8/t12.
    for _ = 1, 4 do ataxiaBasher_goldenDragonBattlerage(";"); clock = clock + 4 end
    expect(ataxiaBasher_goldenDragonBattlerage(";")).toBe("") -- t16: all on cd
    clock = clock + 13 -- t29: overwhelm (stamped t12, 16s) back first
    expect(has(ataxiaBasher_goldenDragonBattlerage(";"), "overwhelm")).toBeTrue()
    clock = clock + 4 -- t33: psiblast (t8 + 23s) back, controls still down
    expect(has(ataxiaBasher_goldenDragonBattlerage(";"), "psiblast")).toBeTrue()
    clock = clock + 6 -- t39: deaden (t0 + 35s) back and outranks everything
    expect(has(ataxiaBasher_goldenDragonBattlerage(";"), "deaden")).toBeTrue()
    clock = clock + 6 -- t45: psidaze (t4 + 41s) back
    expect(has(ataxiaBasher_goldenDragonBattlerage(";"), "psidaze")).toBeTrue()
  end)

  it("BANKS rage while a control cast waits (no Overwhelm at 20 rage with Deaden ready)", function()
    reset(); ataxia.vitals.rage = 20
    expect(ataxiaBasher_goldenDragonBattlerage(";")).toBe("")
    -- Once both controls are on cooldown the fillers may spend again.
    ataxiaTemp.gdragonBrAt = { deaden = clock, psidaze = clock }
    expect(has(ataxiaBasher_goldenDragonBattlerage(";"), "overwhelm")).toBeTrue()
  end)

  it("respects rage floors (psidaze fires at 30 when deaden is down)", function()
    reset(); ataxia.vitals.rage = 30
    ataxiaTemp.gdragonBrAt = { deaden = clock }
    expect(has(ataxiaBasher_goldenDragonBattlerage(";"), "psidaze")).toBeTrue()
    -- 25 rage, controls down, psiblast (36) unaffordable -> overwhelm filler
    reset(); ataxia.vitals.rage = 25
    ataxiaTemp.gdragonBrAt = { deaden = clock, psidaze = clock }
    expect(has(ataxiaBasher_goldenDragonBattlerage(";"), "overwhelm")).toBeTrue()
  end)

  it("owns culling: reap outranks the rotation at 36 rage", function()
    reset(); ataxia.vitals.rage = 100
    ataxiaBasher.cullingBlade = true
    expect(has(ataxiaBasher_goldenDragonBattlerage(";"), "reap " .. target)).toBeTrue()
    ataxiaTemp.bladeCooldown = true
    expect(has(ataxiaBasher_goldenDragonBattlerage(";"), "deaden")).toBeTrue()
  end)

  it("conserves rage on nearly-dead mobs, parsing percent-suffixed hpperc", function()
    reset(); ataxia.vitals.rage = 100
    ataxiaBasher.rageConserveThreshold = 15
    gmcp.IRE.Target.Info.hpperc = "10%" -- live shape (gsub multi-return regression)
    expect(ataxiaBasher_goldenDragonBattlerage(";")).toBe("")
  end)

  it("fire-line confirmation restamps the cooldown and releases the pick hold", function()
    reset(); ataxia.vitals.rage = 100
    ataxiaTemp.gdragonBrAt = { deaden = clock } -- deaden down: psidaze picks first
    expect(has(ataxiaBasher_goldenDragonBattlerage(";"), "psidaze")).toBeTrue()
    clock = clock + 2 -- the cast lands mid-hold (trigger highlighting/028 fires)
    ataxiaBasher_gdragonConfirm("psidaze")
    expect(ataxiaTemp.gdragonBrPending).toBe(nil)
    expect(ataxiaTemp.gdragonBrAt.psidaze).toBe(clock) -- cooldown from the LANDED moment
    -- The next rebuild advances immediately instead of replaying the landed cast.
    expect(has(ataxiaBasher_goldenDragonBattlerage(";"), "psiblast")).toBeTrue()
  end)
end)

describe("ataxiaBasher_dragonBashing -- per-colour battlerage routing", function()
  it("Golden Dragon uses its own rotation, not the generic assembler", function()
    reset(); ataxia.vitals.rage = 100
    local cmd = ataxiaBasher_dragonBashing()
    expect(has(cmd, "deaden " .. target)).toBeTrue()
    expect(has(cmd, "GENERIC_BRAGE")).toBeFalse()
    expect(has(cmd, "gut " .. target)).toBeTrue() -- the bal primary still swings
  end)

  it("other colours keep the generic assembler", function()
    reset(); gmcp.Char.Status.class = "Blue Dragon"
    local cmd = ataxiaBasher_dragonBashing()
    expect(has(cmd, "GENERIC_BRAGE")).toBeTrue()
    expect(has(cmd, "deaden")).toBeFalse()
  end)

  it("shielded+rageraze round burns NO cooldown stamp (review MEDIUM: lazy battlerage)", function()
    reset(); ataxia.vitals.rage = 50
    ataxiaBasher.shielded, ataxiaBasher.rageraze = true, true
    local cmd = ataxiaBasher_dragonBashing()
    expect(has(cmd, "psishatter " .. target)).toBeTrue() -- raze spends the rage
    expect(has(cmd, "deaden")).toBeFalse()
    expect(ataxiaTemp.gdragonBrAt).toBe(nil) -- rotation never consulted: no pick, no stamp
    -- Shield broken: the next normal round still opens with Deaden.
    ataxiaBasher.shielded, ataxiaBasher.rageraze = false, false
    expect(has(ataxiaBasher_dragonBashing(), "deaden " .. target)).toBeTrue()
  end)
end)

describe("ataxiaBasher_dragonBashing -- Might of Sycaerunax blast weave", function()
  it("drops the re-summon while the boon is up (breath persists through BLAST)", function()
    reset(); ataxiaBasher.dragonBlast = true; breath = "psi"
    ataxia.defences.dragonbreath = true; dragonMightSycaerunax = true
    local cmd = ataxiaBasher_dragonBashing()
    expect(has(cmd, "blast " .. target)).toBeTrue()
    expect(has(cmd, "summon")).toBeFalse()
    expect(has(cmd, "gut " .. target)).toBeTrue() -- the bal primary still swings
  end)

  it("still summons ONCE when breath is down (the boon keeps it thereafter)", function()
    reset(); ataxiaBasher.dragonBlast = true; breath = "psi"
    dragonMightSycaerunax = true -- breath def NOT up
    local cmd = ataxiaBasher_dragonBashing()
    expect(has(cmd, "summon psi")).toBeTrue()
    expect(has(cmd, "blast")).toBeFalse()
  end)

  it("without the boon the blast weave re-summons (unchanged)", function()
    reset(); ataxiaBasher.dragonBlast = true; breath = "psi"
    ataxia.defences.dragonbreath = true
    local cmd = ataxiaBasher_dragonBashing()
    expect(has(cmd, "blast " .. target .. ";summon psi")).toBeTrue()
  end)

  it("shielded reblast skips the re-summon with the boon", function()
    reset(); ataxiaBasher.shielded = true; breath = "psi"
    dragonMightSycaerunax = true
    local cmd = ataxiaBasher_dragonBashing()
    expect(has(cmd, "blast " .. target)).toBeTrue() -- shield still gets blasted
    expect(has(cmd, "summon")).toBeFalse()
  end)
end)

-- Restore shared state for whoever runs after us (files share one Lua state).
getEpoch = _epoch
ataxiaBasher_assembleBattlerage = _assemble
getDragonBreath = _breath
dragonMightSycaerunax = false
