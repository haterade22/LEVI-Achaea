--- test_basher_psion.lua -- Psion bashing assembly (v4.7.128 PvE overhaul)
-- Verifies ataxiaBasher_psionBashing + ataxiaBasher_psionBattlerage: Panoply flurry
-- swap, the timer-free battlerage rotation (Devastate > Whirlwind > Barbedblade,
-- Regrowth opt-in, culling owned locally), the fixed shielded branch (pulverise+weave
-- OR cleave -- never empty, never double-break), the Roth sub-50% eq rider, and the
-- transcend/secondskin keepers. Loads the real basher/002_Class_Bashing.lua.

require("mock_mudlet")

-- Globals the Psion bashing path reads at call time.
target = "manticore"
ataxia = { settings = { separator = ";" }, vitals = { rage = 0, hpp = 100 },
           defences = { secondskin = true, psitranscend = true } }
ataxiaBasher = { shielded = false, rageraze = false,
                 battlerage = { Psion = { raze = "weave pulverise " .. target } } }
ataxiaTemp = {}
gmcp = {
  Room = { Info = { area = "" } },
  Char = { Status = { class = "Psion", level = "80 " } },
  IRE = { Target = { Info = {} } },
}
function ataxiaEcho() end

-- Controllable clock for the send-side cooldown stamps; restored at EOF (test files
-- share one Lua state).
local _epoch = getEpoch
local clock = 500000
getEpoch = function() return clock end

local file = "src_new/scripts/levi_ataxia/levi/ataxia/basher/002_Class_Bashing.lua"
local ok, err = pcall(dofile, file)
if not ok then error("Failed to load class-bashing file: " .. tostring(err)) end

local function has(cmd, needle) return cmd:find(needle, 1, true) ~= nil end

local function reset()
  ataxiaBasher.shielded, ataxiaBasher.rageraze = false, false
  ataxiaBasher.cullingBlade, ataxiaBasher.rageConserveThreshold = nil, nil
  ataxiaBasher.psionRegrowth = nil
  ataxia.vitals.rage, ataxia.vitals.hpp = 0, 100
  ataxia.defences = { secondskin = true, psitranscend = true }
  ataxiaTemp = {}
  gmcp.IRE.Target.Info = {}
  gmcp.Room.Info.area = ""
  psionPanoply = false
  clock = 500000
end

describe("ataxiaBasher_psionBashing -- weave selection", function()
  it("bashes with weave deathblow by default", function()
    reset()
    local cmd = ataxiaBasher_psionBashing()
    expect(has(cmd, "weave deathblow " .. target)).toBeTrue()
    expect(has(cmd, "weave flurry")).toBeFalse()
  end)

  it("swaps to weave flurry while Panoply is up", function()
    reset(); psionPanoply = true
    local cmd = ataxiaBasher_psionBashing()
    expect(has(cmd, "weave flurry " .. target)).toBeTrue()
    expect(has(cmd, "weave deathblow")).toBeFalse()
  end)

  it("keeps psi shatter's transcendence slot", function()
    reset(); ataxiaTemp.transcendence = 100
    local cmd = ataxiaBasher_psionBashing()
    expect(has(cmd, "psi shatter " .. target .. ";weave deathblow " .. target)).toBeTrue()
  end)
end)

describe("ataxiaBasher_psionBashing -- shielded branch (review fix)", function()
  it("always cleaves as the fallback (the old branch built an EMPTY command)", function()
    reset(); ataxiaBasher.shielded = true
    local cmd = ataxiaBasher_psionBashing()
    expect(has(cmd, "weave cleave " .. target)).toBeTrue()
  end)

  it("with rageraze: pulverise breaks on rage + the damage weave lands same round", function()
    reset(); ataxiaBasher.shielded = true
    ataxiaBasher.rageraze = true; ataxia.vitals.rage = 100
    local cmd = ataxiaBasher_psionBashing()
    expect(has(cmd, "weave pulverise " .. target .. ";weave deathblow " .. target)).toBeTrue()
    expect(has(cmd, "weave cleave")).toBeFalse() -- no double-break
  end)
end)

describe("ataxiaBasher_psionBattlerage -- timer-free rotation", function()
  it("fires Devastate > Whirlwind > Barbedblade by priority, honoring cooldown stamps", function()
    reset(); ataxia.vitals.rage = 100
    -- One pick per simulated balance round (the in-flight hold replays within ~3s).
    expect(has(ataxiaBasher_psionBattlerage(";"), "psi devastate")).toBeTrue()
    clock = clock + 4
    expect(has(ataxiaBasher_psionBattlerage(";"), "weave whirlwind")).toBeTrue()
    clock = clock + 4
    expect(has(ataxiaBasher_psionBattlerage(";"), "weave barbedblade")).toBeTrue()
    clock = clock + 4 -- t12: everything stamped (t0/t4/t8) and on cooldown
    expect(ataxiaBasher_psionBattlerage(";")).toBe("")
    clock = clock + 13 -- t25: barbedblade (t8 + 16s) AND devastate (t0 + 23s) back -> priority wins
    expect(has(ataxiaBasher_psionBattlerage(";"), "psi devastate")).toBeTrue()
    clock = clock + 4 -- t29: whirlwind (t4 + 23s) back
    expect(has(ataxiaBasher_psionBattlerage(";"), "weave whirlwind")).toBeTrue()
  end)

  it("replays the SAME pick across the 0.3s re-queue loop (v4.7.129: no phantom burn)", function()
    reset(); ataxia.vitals.rage = 100
    local first = ataxiaBasher_psionBattlerage(";")
    expect(has(first, "psi devastate")).toBeTrue()
    clock = clock + 1
    expect(ataxiaBasher_psionBattlerage(";")).toBe(first)
    expect(ataxiaTemp.psionBrAt.whirlwind).toBe(nil) -- the rotation did NOT advance
    clock = clock + 4 -- hold expired: next pick
    expect(has(ataxiaBasher_psionBattlerage(";"), "weave whirlwind")).toBeTrue()
  end)

  it("respects rage floors (14 barbedblade / 25 whirlwind / 36 devastate)", function()
    reset(); ataxia.vitals.rage = 20
    expect(has(ataxiaBasher_psionBattlerage(";"), "weave barbedblade")).toBeTrue()
    reset(); ataxia.vitals.rage = 30
    expect(has(ataxiaBasher_psionBattlerage(";"), "weave whirlwind")).toBeTrue()
    reset(); ataxia.vitals.rage = 10
    expect(ataxiaBasher_psionBattlerage(";")).toBe("")
  end)

  it("Regrowth is opt-in and takes priority when enabled (self-healing denizens)", function()
    reset(); ataxia.vitals.rage = 100
    ataxiaBasher.psionRegrowth = true
    expect(has(ataxiaBasher_psionBattlerage(";"), "enact regrowth")).toBeTrue()
    reset(); ataxia.vitals.rage = 100
    expect(has(ataxiaBasher_psionBattlerage(";"), "enact regrowth")).toBeFalse()
  end)

  it("owns culling: reap outranks the rotation at 36 rage", function()
    reset(); ataxia.vitals.rage = 100
    ataxiaBasher.cullingBlade = true
    expect(has(ataxiaBasher_psionBattlerage(";"), "reap " .. target)).toBeTrue()
    ataxiaTemp.bladeCooldown = true
    expect(has(ataxiaBasher_psionBattlerage(";"), "psi devastate")).toBeTrue()
  end)

  it("conserves rage on nearly-dead mobs, parsing percent-suffixed hpperc", function()
    reset(); ataxia.vitals.rage = 100
    ataxiaBasher.rageConserveThreshold = 15
    gmcp.IRE.Target.Info.hpperc = "10%" -- live shape (gsub multi-return regression)
    expect(ataxiaBasher_psionBattlerage(";")).toBe("")
  end)
end)

describe("ataxiaBasher_psionBashing -- eq riders and keepers", function()
  it("fires Roth below 50% HP on its 3-minute stamp, riding eq beside the weave", function()
    reset(); ataxia.vitals.hpp = 40
    local cmd = ataxiaBasher_psionBashing()
    expect(has(cmd, "enact roth;")).toBeTrue()
    expect(has(cmd, "weave deathblow")).toBeTrue() -- the swing still happens
    local cmd2 = ataxiaBasher_psionBashing()
    expect(has(cmd2, "enact roth")).toBeFalse() -- stamped: 185s lockout
    clock = clock + 190
    expect(has(ataxiaBasher_psionBashing(), "enact roth")).toBeTrue()
  end)

  it("Roth still fires on shielded rounds (heal first, break shield same round)", function()
    reset(); ataxia.vitals.hpp = 40; ataxiaBasher.shielded = true
    local cmd = ataxiaBasher_psionBashing()
    expect(has(cmd, "enact roth")).toBeTrue()
    expect(has(cmd, "weave cleave")).toBeTrue()
  end)

  it("re-ups PSI TRANSCEND when its defence drops (attempt-held)", function()
    reset(); ataxia.defences.psitranscend = nil
    expect(has(ataxiaBasher_psionBashing(), "psi transcend;")).toBeTrue()
    expect(has(ataxiaBasher_psionBashing(), "psi transcend;")).toBeFalse() -- held
  end)

  it("re-weaves SECONDSKIN when it drops -- replacing that round's swing", function()
    reset(); ataxia.defences.secondskin = nil
    local cmd = ataxiaBasher_psionBashing()
    expect(has(cmd, "weave secondskin")).toBeTrue()
    expect(has(cmd, "weave deathblow")).toBeFalse() -- secondskin takes the balance
    local cmd2 = ataxiaBasher_psionBashing()
    expect(has(cmd2, "weave deathblow")).toBeTrue() -- held: back to swinging
  end)

  it("skips the secondskin keeper on shielded rounds (break the shield first)", function()
    reset(); ataxia.defences.secondskin = nil; ataxiaBasher.shielded = true
    local cmd = ataxiaBasher_psionBashing()
    expect(has(cmd, "weave cleave")).toBeTrue()
    expect(has(cmd, "weave secondskin")).toBeFalse()
  end)
end)

-- PENDING KEY, NOT PENDING COMMAND (v4.7.193, Codex adversarial review). The ready-line
-- feed (basher/011) releases a held pick with `pend.verb == field`, where field is the
-- BR_READY_MAP key ("barbedblade"). Psion was the one rotation storing the full command
-- ("weave barbedblade") in `verb`, so that comparison never matched for ANY of its four
-- abilities: after the game said the ability was ready again, the stale pick kept being
-- replayed for the rest of its 3s window. Runewarden and Depthswalker always stored the
-- key; Golden Dragon dodged it only because its commands happen to equal their keys.
describe("psion in-flight replay -- released by the ready line", function()
  it("stores the ROTATION KEY in verb, and the full command in cmd", function()
    reset(); ataxia.vitals.rage = 100
    local cmd = ataxiaBasher_psionBattlerage(";")
    local p = ataxiaTemp.psionBrPending
    expect(p ~= nil).toBeTrue()
    expect(p.verb).toBe("devastate")           -- the key BR_READY_MAP uses
    expect(p.verb:find(" ", 1, true)).toBe(nil) -- never a command string
    expect(p.cmd).toBe(cmd)                     -- replay stays byte-stable
  end)

  it("replays the pick verbatim inside the window", function()
    reset(); ataxia.vitals.rage = 100
    local first = ataxiaBasher_psionBattlerage(";")
    expect(ataxiaBasher_psionBattlerage(";")).toBe(first)
  end)

  it("the ready line RELEASES the hold -- the regression", function()
    reset(); ataxia.vitals.rage = 100
    ataxiaBasher_psionBattlerage(";")
    expect(ataxiaTemp.psionBrPending ~= nil).toBeTrue()
    -- Mirrors the release loop in basher/011_Battlerage_Ready_Lines.lua.
    local field = "devastate"
    local pend = ataxiaTemp.psionBrPending
    if pend and pend.verb == field then ataxiaTemp.psionBrPending = nil end
    expect(ataxiaTemp.psionBrPending).toBe(nil) -- was NOT released before the fix
  end)
end)

-- Restore shared state for whoever runs after us (files share one Lua state).
psionPanoply = false
getEpoch = _epoch
