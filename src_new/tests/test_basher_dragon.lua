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

-- Controllable denizen count for the Draconic Rampage gate (the basher reads the
-- Mnemosyne explorer's killable-count helper, like the Kai Choke).
local denizens = 0
ataxia.mnemosyne = { _denizenCount = function() return denizens end }

local file = "src_new/scripts/levi_ataxia/levi/ataxia/basher/002_Class_Bashing.lua"
local ok, err = pcall(dofile, file)
if not ok then error("Failed to load class-bashing file: " .. tostring(err)) end

local function has(cmd, needle) return cmd:find(needle, 1, true) ~= nil end

local function reset()
  ataxiaBasher.shielded, ataxiaBasher.rageraze = false, false
  ataxiaBasher.cullingBlade, ataxiaBasher.rageConserveThreshold = nil, nil
  ataxiaBasher.dragonBlast, ataxiaBasher.rageFloor = nil, nil
  ataxiaBasher.jabBash, ataxiaBasher.wotBash, ataxiaBasher.dragonIncant = nil, nil, nil
  dragonOrganPiercer, dragonSparkExtant = nil, nil
  ataxia.vitals.rage, ataxia.vitals.wpp = 0, nil
  ataxia.defences = {}
  ataxiaTemp = {}
  gmcp.IRE.Target.Info = {}
  gmcp.Room.Info.area = ""
  gmcp.Char.Status.class = "Golden Dragon"
  dragonMightSycaerunax = false
  dragonRampage = false
  breath = nil
  denizens = 0
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

  it("rage floor: banking still banks, and picks need cost + floor (v4.7.141)", function()
    reset(); ataxiaBasher.rageFloor = 40
    ataxia.vitals.rage = 60 -- deaden needs 24 + 40 = 64: bank, don't spend on fillers
    expect(ataxiaBasher_goldenDragonBattlerage(";")).toBe("")
    reset(); ataxiaBasher.rageFloor = 40
    ataxia.vitals.rage = 64
    expect(has(ataxiaBasher_goldenDragonBattlerage(";"), "deaden")).toBeTrue()
    -- Reap is exempt: it fires at its own 36 even though 36 < 36 + floor.
    reset(); ataxiaBasher.rageFloor = 40
    ataxiaBasher.cullingBlade = true; ataxia.vitals.rage = 36
    expect(has(ataxiaBasher_goldenDragonBattlerage(";"), "reap " .. target)).toBeTrue()
    ataxiaBasher.rageFloor = nil
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
    expect(has(cmd, "gut")).toBeFalse() -- one attack per round (v4.7.438)
  end)

  it("still summons ONCE when breath is down, and blasts the same round (v4.7.439)", function()
    reset(); ataxiaBasher.dragonBlast = true; breath = "psi"
    dragonMightSycaerunax = true -- breath def NOT up
    local cmd = ataxiaBasher_dragonBashing()
    expect(has(cmd, "summon psi;blast " .. target)).toBeTrue()
    expect(has(cmd, "blast " .. target .. ";summon")).toBeFalse()
  end)

  it("without the boon the blast weave re-summons (unchanged)", function()
    reset(); ataxiaBasher.dragonBlast = true; breath = "psi"
    ataxia.defences.dragonbreath = true
    local cmd = ataxiaBasher_dragonBashing()
    expect(has(cmd, "blast " .. target .. ";summon psi")).toBeTrue()
  end)

  it("shielded reblast skips the re-summon with the boon", function()
    reset(); ataxiaBasher.shielded = true; breath = "psi"
    dragonMightSycaerunax = true; ataxia.defences.dragonbreath = true
    local cmd = ataxiaBasher_dragonBashing()
    expect(has(cmd, "blast " .. target)).toBeTrue() -- shield still gets blasted
    expect(has(cmd, "summon")).toBeFalse()
  end)
end)

describe("ataxiaBasher_dragonBashing -- Draconic Rampage trample", function()
  it("spends the balance swing on TRAMPLE at 2+ denizens off the 40s proc", function()
    reset(); dragonRampage = true; denizens = 3
    local cmd = ataxiaBasher_dragonBashing()
    expect(has(cmd, "trample")).toBeTrue()
    expect(has(cmd, "gut")).toBeFalse()
  end)

  it("stays on the normal swing solo or while the proc is down", function()
    reset(); dragonRampage = true; denizens = 1
    expect(has(ataxiaBasher_dragonBashing(), "gut " .. target)).toBeTrue()
    reset(); dragonRampage = true; denizens = 3
    ataxiaTemp.dragonRampageAt = clock - 10 -- proc spent 10s ago
    expect(has(ataxiaBasher_dragonBashing(), "gut " .. target)).toBeTrue()
    clock = clock + 31 -- 41s since the proc: ready again
    expect(has(ataxiaBasher_dragonBashing(), "trample")).toBeTrue()
  end)

  it("replays the trample round across the re-queue loop, then returns to gut", function()
    reset(); dragonRampage = true; denizens = 2
    expect(has(ataxiaBasher_dragonBashing(), "trample")).toBeTrue()
    clock = clock + 1
    expect(has(ataxiaBasher_dragonBashing(), "trample")).toBeTrue() -- in-flight hold
    clock = clock + 4 -- hold expired, proc on cooldown
    expect(has(ataxiaBasher_dragonBashing(), "gut " .. target)).toBeTrue()
  end)

  it("takes the whole round from the blast (one attack per round, v4.7.438)", function()
    reset(); dragonRampage = true; denizens = 2
    ataxiaBasher.dragonBlast = true; breath = "psi"
    ataxia.defences.dragonbreath = true; dragonMightSycaerunax = true
    local cmd = ataxiaBasher_dragonBashing()
    expect(has(cmd, "trample")).toBeTrue()
    expect(has(cmd, "blast")).toBeFalse()
  end)

  it("never trades a shield-break round for the trample", function()
    reset(); dragonRampage = true; denizens = 3
    ataxiaBasher.shielded = true; breath = "psi"
    local cmd = ataxiaBasher_dragonBashing()
    expect(has(cmd, "trample")).toBeFalse()
    expect(has(cmd, "blast " .. target)).toBeTrue() -- the shield still gets broken
  end)

  it("proc confirmation restamps the 40s cooldown and releases the trample hold", function()
    reset(); dragonRampage = true; denizens = 3
    expect(has(ataxiaBasher_dragonBashing(), "trample")).toBeTrue()
    clock = clock + 2 -- the queued trample lands (trigger highlighting/033 fires)
    ataxiaBasher_dragonRampageProc()
    expect(ataxiaTemp.dragonRampagePendingAt).toBe(nil)
    expect(ataxiaTemp.dragonRampageAt).toBe(clock) -- cooldown from the LANDED proc
    expect(has(ataxiaBasher_dragonBashing(), "gut " .. target)).toBeTrue() -- back to swinging
    clock = clock + 41 -- proc ready again
    expect(has(ataxiaBasher_dragonBashing(), "trample")).toBeTrue()
  end)
end)

describe("ataxiaBasher_dragonBashing -- Draconic Sweep tailsweep", function()
  local function fresh()
    reset(); dragonRampage = false; dragonSweep = true; denizens = 3
  end

  it("spends the balance swing on TAILSWEEP at 2+ denizens off the 30s proc", function()
    fresh()
    local cmd = ataxiaBasher_dragonBashing()
    expect(has(cmd, "tailsweep")).toBeTrue()
    expect(has(cmd, "gut")).toBeFalse()
  end)

  it("stays on the normal swing solo or while the proc is down", function()
    fresh(); denizens = 1
    expect(has(ataxiaBasher_dragonBashing(), "gut " .. target)).toBeTrue()
    fresh(); ataxiaTemp.dragonSweepAt = clock - 10
    expect(has(ataxiaBasher_dragonBashing(), "gut " .. target)).toBeTrue()
    clock = clock + 21 -- 31s since the proc: ready again
    expect(has(ataxiaBasher_dragonBashing(), "tailsweep")).toBeTrue()
  end)

  it("never trades a shield-break round for the tailsweep", function()
    fresh(); ataxiaBasher.shielded = true; breath = "psi"
    expect(has(ataxiaBasher_dragonBashing(), "tailsweep")).toBeFalse()
  end)

  it("sweeps first when both are ready, then tramples on the next round", function()
    fresh(); dragonRampage = true
    expect(has(ataxiaBasher_dragonBashing(), "tailsweep")).toBeTrue()
    clock = clock + 1
    expect(has(ataxiaBasher_dragonBashing(), "tailsweep")).toBeTrue() -- in-flight hold
    ataxiaBasher_dragonSweepProc() -- the sweep landed: hold released
    expect(has(ataxiaBasher_dragonBashing(), "trample")).toBeTrue()
  end)

  it("a trample in flight is not abandoned when the sweep comes ready", function()
    fresh(); dragonRampage = true
    ataxiaTemp.dragonSweepAt = clock - 29 -- sweep ready in 1s
    expect(has(ataxiaBasher_dragonBashing(), "trample")).toBeTrue()
    clock = clock + 2 -- sweep now ready, trample still in its hold
    expect(has(ataxiaBasher_dragonBashing(), "trample")).toBeTrue()
    clock = clock + 2 -- hold over: the sweep takes the slot
    expect(has(ataxiaBasher_dragonBashing(), "tailsweep")).toBeTrue()
  end)
end)

describe("ataxiaBasher_dragonBashing -- one attack per round (v4.7.438)", function()
  -- "It should be Blast or Incantation or Jab or Rend or Gut."
  local function base()
    reset(); dragonSweep = false; dragonRampage = false; dragonMightSycaerunax = false
  end
  local function only(cmd, atk)
    for _, other in ipairs({ "blast", "incantation", "jab", "rend", "gut", "whip" }) do
      if other ~= atk then expect(has(cmd, other .. " ")).toBeFalse() end
    end
    expect(has(cmd, atk .. " " .. target)).toBeTrue()
  end

  it("Might of Sycaerunax: blast alone, even with the toggle off, incant on, or jab set", function()
    base(); breath = "psi"; ataxia.defences.dragonbreath = true; dragonMightSycaerunax = true
    ataxiaBasher.dragonBlast = false
    only(ataxiaBasher_dragonBashing(), "blast")
    ataxiaBasher.dragonIncant = true; ataxiaBasher.jabBash = true -- the live 'blast;jab' log
    only(ataxiaBasher_dragonBashing(), "blast")
  end)

  it("no blast: incantation, then jab, then whip, then rend, then gut", function()
    base(); ataxiaBasher.dragonIncant = true; ataxiaBasher.jabBash = true
    ataxiaBasher.wotBash = true; dragonOrganPiercer = true
    only(ataxiaBasher_dragonBashing(), "incantation")
    ataxiaBasher.dragonIncant = false
    only(ataxiaBasher_dragonBashing(), "jab")
    ataxiaBasher.jabBash = false
    only(ataxiaBasher_dragonBashing(), "whip")
    ataxiaBasher.wotBash = false
    only(ataxiaBasher_dragonBashing(), "rend")
    dragonOrganPiercer = false
    only(ataxiaBasher_dragonBashing(), "gut")
  end)

  it("a jab round wields the dirk first", function()
    base(); ataxiaBasher.jabBash = true
    expect(has(ataxiaBasher_dragonBashing(), "wield dirk;jab " .. target)).toBeTrue()
  end)

  it("low willpower jabs for the incantation per round, and never rewrites the settings", function()
    base(); ataxiaBasher.dragonIncant = true; ataxia.vitals.wpp = 4
    expect(has(ataxiaBasher_dragonBashing(), "wield dirk;jab " .. target)).toBeTrue()
    expect(ataxiaBasher.dragonIncant).toBe(true)
    expect(ataxiaBasher.jabBash == true).toBeFalse()
    ataxia.vitals.wpp = 60 -- willpower back: incantation again
    only(ataxiaBasher_dragonBashing(), "incantation")
  end)

  it("breath down: summon (off-eq) then blast in the same round (v4.7.439)", function()
    base(); breath = "psi"; ataxiaBasher.dragonBlast = true; ataxiaBasher.dragonIncant = true
    local cmd = ataxiaBasher_dragonBashing()
    expect(has(cmd, "summon psi;blast " .. target .. ";summon psi")).toBeTrue()
    expect(has(cmd, "incantation")).toBeFalse()
    dragonMightSycaerunax = true -- Might keeps the breath: no trailing re-summon
    cmd = ataxiaBasher_dragonBashing()
    expect(has(cmd, "summon psi;blast " .. target)).toBeTrue()
    expect(has(cmd, "blast " .. target .. ";summon")).toBeFalse()
    ataxiaBasher.shielded = true -- the shield round summons first too
    expect(has(ataxiaBasher_dragonBashing(), "summon psi;blast " .. target)).toBeTrue()
    ataxia.defences.dragonbreath = true
    only(ataxiaBasher_dragonBashing(), "blast")
  end)

  it("without the boon, the toggle and the jab exclusion still apply", function()
    base(); breath = "psi"; ataxia.defences.dragonbreath = true; ataxiaBasher.dragonBlast = false
    expect(has(ataxiaBasher_dragonBashing(), "blast")).toBeFalse()
    ataxiaBasher.dragonBlast = true; ataxiaBasher.jabBash = true
    expect(has(ataxiaBasher_dragonBashing(), "blast")).toBeFalse()
    ataxiaBasher.dragonBlast = true; ataxiaBasher.jabBash = false
    expect(has(ataxiaBasher_dragonBashing(), "blast " .. target .. ";summon psi")).toBeTrue()
    expect(has(ataxiaBasher_dragonBashing(), "gut")).toBeFalse()
  end)
end)

describe("ataxiaBasher_dragonBashing -- Spark Extant incantation (v4.7.440)", function()
  -- "Incantation (with boon) > Tail > Trample > Blast"
  local function fresh(n)
    reset(); dragonSparkExtant = true; dragonSweep = true; dragonRampage = true
    dragonMightSycaerunax = true; breath = "psi"; ataxia.defences.dragonbreath = true
    denizens = n
  end

  it("casts incantation over tailsweep, trample and blast at 2+ denizens", function()
    fresh(3)
    local cmd = ataxiaBasher_dragonBashing()
    expect(has(cmd, "incantation " .. target)).toBeTrue()
    expect(has(cmd, "tailsweep")).toBeFalse()
    expect(has(cmd, "blast")).toBeFalse()
    expect(ataxiaTemp.dragonSweepAt).toBe(nil) -- the AoE pick was never asked: no stamp
  end)

  it("solo it is the normal round (blast)", function()
    fresh(1)
    local cmd = ataxiaBasher_dragonBashing()
    expect(has(cmd, "blast " .. target)).toBeTrue()
    expect(has(cmd, "incantation")).toBeFalse()
  end)

  it("at 5% willpower or less it falls through to tailsweep", function()
    fresh(3); ataxia.vitals.wpp = 5
    expect(has(ataxiaBasher_dragonBashing(), "tailsweep")).toBeTrue()
  end)

  it("a tailsweep in its in-flight hold replays before the incantation", function()
    fresh(3); dragonSparkExtant = false
    expect(has(ataxiaBasher_dragonBashing(), "tailsweep")).toBeTrue()
    dragonSparkExtant = true; clock = clock + 1
    expect(has(ataxiaBasher_dragonBashing(), "tailsweep")).toBeTrue()
    clock = clock + 3 -- hold over
    expect(has(ataxiaBasher_dragonBashing(), "incantation " .. target)).toBeTrue()
  end)

  it("the shield round still blasts", function()
    fresh(3); ataxiaBasher.shielded = true
    local cmd = ataxiaBasher_dragonBashing()
    expect(has(cmd, "blast " .. target)).toBeTrue()
    expect(has(cmd, "incantation")).toBeFalse()
  end)
end)

-- Restore shared state for whoever runs after us (files share one Lua state).
getEpoch = _epoch
ataxiaBasher_assembleBattlerage = _assemble
getDragonBreath = _breath
dragonMightSycaerunax = false
dragonRampage = false
dragonSweep = false
dragonOrganPiercer = false
dragonSparkExtant = false
