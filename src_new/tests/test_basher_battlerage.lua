--- test_basher_battlerage.lua — Blademaster battlerage rotation
-- Loads the real basher/001 and exercises ataxiaBasher_blademasterBattlerage():
-- rage must never idle (the "100+ rage unused" bug), culling/priority order is
-- correct, and a reckless/feared target is cashed in with Headstrike for bonus damage.

require("mock_mudlet") -- tempTimer / getEpoch / etc.

-- Project globals the basher functions file expects at load time
function ataxiaEcho(...) end
function get_Battlerage() end
function ataxia_saveSettings(...) end
function ataxiaBasher_canShield() return true end
function table.contains(t, v)
  if type(t) ~= "table" then return false end
  for _, x in pairs(t) do if x == v then return true end end
  return false
end

ataxia = ataxia or {}
ataxia.settings = { separator = ";" }
ataxia.vitals = { rage = 0 }
ataxiaBasher = ataxiaBasher or {}
ataxiaTemp = ataxiaTemp or {}
battleRage_Timers = {}
target = 1
gmcp = {
  Room = { Info = { area = "" } },
  Char = { Status = { class = "Blademaster", level = "80 " } },
  IRE = { Target = { Info = {} } },
}

local basher_file = "src_new/scripts/levi_ataxia/levi/ataxia/basher/001_Bashing_Functions.lua"
local ok, err = pcall(dofile, basher_file)
if not ok then error("Failed to load basher functions file: " .. tostring(err)) end

-- Blademaster battlerage config (as get_Battlerage builds it, target already baked in)
ataxiaBasher.battlerage = {
  Blademaster = {
    small = "leapstrike 1", large = "spinslash 1", special = "shin daze 1",
    specialuse = "strike 1 head", raze = "shin shatter 1",
  },
}

-- Controllable dsExploit stub (Stage-1 denizen-state layer isn't loaded here)
local exploitReturn = nil
function ataxiaBasher_dsExploit(id) return exploitReturn end

local function reset()
  ataxia.vitals.rage = 0
  battleRage_Timers = {}
  ataxiaBasher.cullingBlade = false
  ataxiaBasher.inMnemosyne = false
  ataxiaTemp.bladeCooldown = nil
  ataxiaTemp.bmHeadstrikeReadyAt = nil
  ataxiaTemp.bmNerveslashReadyAt = nil
  ataxiaTemp.brGlobalReadyAt = nil
  exploitReturn = nil
  gmcp.Room.Info.area = ""
end

-- Blademaster config exposes specialafflict = Nerveslash (weakness)
ataxiaBasher.battlerage.Blademaster.specialafflict = "nsl 1"

describe("ataxiaBasher_blademasterBattlerage — rage never idles", function()
  it("spends flush rage on Spinslash (never returns empty when able)", function()
    reset(); ataxia.vitals.rage = 103
    expect(ataxiaBasher_blademasterBattlerage(";")).toBe("spinslash 1;")
  end)

  it("prioritises Culling reap when enabled, off cooldown, and affordable", function()
    reset(); ataxia.vitals.rage = 103; ataxiaBasher.cullingBlade = true
    expect(ataxiaBasher_blademasterBattlerage(";")).toBe("reap 1;")
  end)

  it("does NOT reap in the World Tree area", function()
    reset(); ataxia.vitals.rage = 103; ataxiaBasher.cullingBlade = true
    gmcp.Room.Info.area = "the Fathomless Expanse of the World Tree"
    expect(ataxiaBasher_blademasterBattlerage(";")).toBe("spinslash 1;")
  end)

  it("cashes in a reckless/feared target with Headstrike + arms its cooldown", function()
    reset(); ataxia.vitals.rage = 103; exploitReturn = "headstrike"
    expect(ataxiaBasher_blademasterBattlerage(";")).toBe("strike 1 head;")
    expect(ataxiaTemp.bmHeadstrikeReadyAt ~= nil).toBeTrue() -- timestamp cooldown armed
  end)

  it("skips Headstrike while its client cooldown is up, falling to Spinslash", function()
    reset(); ataxia.vitals.rage = 103; exploitReturn = "headstrike"
    ataxiaTemp.bmHeadstrikeReadyAt = getEpoch() + 100 -- still on cooldown
    expect(ataxiaBasher_blademasterBattlerage(";")).toBe("spinslash 1;")
  end)

  it("only Headstrikes on a headstrike exploit, not shatter/burst", function()
    reset(); ataxia.vitals.rage = 103; exploitReturn = "burst"
    expect(ataxiaBasher_blademasterBattlerage(";")).toBe("spinslash 1;")
  end)

  it("respects the Headstrike 25-rage gate (20 -> Leapstrike, 25 -> Headstrike)", function()
    reset(); exploitReturn = "headstrike"; ataxia.vitals.rage = 20 -- < 22 (Nerveslash) & < 25 (Headstrike)
    expect(ataxiaBasher_blademasterBattlerage(";")).toBe("leapstrike 1;")
    reset(); exploitReturn = "headstrike"; ataxia.vitals.rage = 25
    expect(ataxiaBasher_blademasterBattlerage(";")).toBe("strike 1 head;")
  end)

  it("in Mnemosyne, Stun (Daze) is fired BEFORE damage (survival > speed)", function()
    reset(); ataxia.vitals.rage = 103; ataxiaBasher.inMnemosyne = true
    expect(ataxiaBasher_blademasterBattlerage(";")).toBe("shin daze 1;") -- mitigation first
    -- ...but Culling still outranks it (fresh reset -- the prior call armed the global cooldown)
    reset(); ataxia.vitals.rage = 103; ataxiaBasher.inMnemosyne = true; ataxiaBasher.cullingBlade = true
    expect(ataxiaBasher_blademasterBattlerage(";")).toBe("reap 1;")
  end)

  it("outside Mnemosyne, damage (Spinslash) is fired before Stun", function()
    reset(); ataxia.vitals.rage = 103 -- inMnemosyne false
    expect(ataxiaBasher_blademasterBattlerage(";")).toBe("spinslash 1;")
  end)

  it("fires Nerveslash (Weakness) as an other-affliction when damage is on cooldown, arming its cooldown", function()
    reset(); ataxia.vitals.rage = 103
    battleRage_Timers.large = 1; battleRage_Timers.special = 1 -- Spinslash + Daze on CD
    expect(ataxiaBasher_blademasterBattlerage(";")).toBe("nsl 1;")
    expect(ataxiaTemp.bmNerveslashReadyAt ~= nil).toBeTrue() -- timestamp cooldown armed
  end)

  it("skips Nerveslash while its client cooldown is up, falling to Leapstrike", function()
    reset(); ataxia.vitals.rage = 103
    battleRage_Timers.large = 1; battleRage_Timers.special = 1 -- Spinslash + Daze on CD
    ataxiaTemp.bmNerveslashReadyAt = getEpoch() + 100 -- Nerveslash on client cooldown
    expect(ataxiaBasher_blademasterBattlerage(";")).toBe("leapstrike 1;")
  end)

  it("does NOT queue a battlerage while the global ~1s cooldown is up", function()
    reset(); ataxia.vitals.rage = 103
    ataxiaTemp.brGlobalReadyAt = getEpoch() + 5 -- global cooldown active
    expect(ataxiaBasher_blademasterBattlerage(";")).toBe("")
  end)

  it("arms the global cooldown after firing a battlerage, not after an empty result", function()
    reset(); ataxia.vitals.rage = 103
    ataxiaBasher_blademasterBattlerage(";")
    expect(ataxiaTemp.brGlobalReadyAt ~= nil).toBeTrue()
    reset(); ataxia.vitals.rage = 10 -- nothing affordable -> ""
    ataxiaBasher_blademasterBattlerage(";")
    expect(ataxiaTemp.brGlobalReadyAt).toBeNil() -- not armed on empty
  end)

  it("is safe and still spends rage when dsExploit is unavailable (008 not loaded)", function()
    reset(); ataxia.vitals.rage = 103
    local saved = ataxiaBasher_dsExploit
    ataxiaBasher_dsExploit = nil
    local cmd = ataxiaBasher_blademasterBattlerage(";")
    ataxiaBasher_dsExploit = saved
    expect(cmd).toBe("spinslash 1;")
  end)

  it("waits (empty) only when the affordable ability is genuinely on cooldown", function()
    reset(); ataxia.vitals.rage = 20; battleRage_Timers.small = 1 -- Leapstrike on CD; rage < 26 & < 36
    expect(ataxiaBasher_blademasterBattlerage(";")).toBe("") -- correct waiting, NOT stranding
    ataxia.vitals.rage = 30 -- Daze (26) now affordable and off cooldown
    expect(ataxiaBasher_blademasterBattlerage(";")).toBe("shin daze 1;")
  end)

  it("falls to Leapstrike when Spinslash is unaffordable", function()
    reset(); ataxia.vitals.rage = 20 -- >=14, <36
    expect(ataxiaBasher_blademasterBattlerage(";")).toBe("leapstrike 1;")
  end)

  it("spends surplus on Daze when small + large are on cooldown", function()
    reset(); ataxia.vitals.rage = 103
    battleRage_Timers.large = 1; battleRage_Timers.small = 1
    expect(ataxiaBasher_blademasterBattlerage(";")).toBe("shin daze 1;")
  end)

  it("returns empty only when nothing is affordable", function()
    reset(); ataxia.vitals.rage = 10 -- < 14
    expect(ataxiaBasher_blademasterBattlerage(";")).toBe("")
  end)
end)

-- ── Monk: Ripplestrike -> Inhibit, spent only where healing actually happens ──────────────
-- Inhibit stops a denizen healing, so it is dead rage against a mob that never heals -- and
-- gold against the "Sanguine Restoration" affix ("Pools of blood shall heal nearby denizens").
-- Mindblast is deliberately not prioritised: nothing in Monk's kit applies Weakness or
-- Sensitivity (Scramble = Clumsy, Ripplestrike = Inhibit), so its bonus can never self-enable.
describe("ataxiaBasher_monkBattlerage", function()

  local function monkReset(affix)
    reset()
    gmcp.Char.Status.class = "Monk"
    ataxiaBasher.battlerage = ataxiaBasher.battlerage or {}
    ataxiaBasher.battlerage["Monk"] = {
      small = "sbp " .. target, large = "tnk " .. target,
      raze = "spk " .. target, special = "mind scramble " .. target,
      specialafflict = "rpst " .. target, specialuse = "mind blast " .. target,
    }
    ataxiaBasher.healerDenizens = {}
    ataxiaBasher.inMnemosyne = true
    ataxia.mnemosyne = { hasAffix = function(n) return affix == true end }
  end

  it("fires Ripplestrike when Sanguine Restoration is up (pools heal denizens)", function()
    monkReset(true); ataxia.vitals.rage = 100
    expect(ataxiaBasher_monkBattlerage("::")).toBe("rpst " .. target .. "::")
  end)

  -- Ripplestrike's 27s cooldown has no shared battleRage_Timers entry (330/331/332 only cover
  -- small/large/special), so trigger 023 stamps a reload-safe timestamp from the real fire.
  -- Gating on the never-set battleRage_Timers.specialafflict would never block -> RPST every
  -- attack, burning rage on a cooldown we cannot see.
  it("respects Ripplestrike's cooldown timestamp instead of re-firing every attack", function()
    monkReset(true); ataxia.vitals.rage = 100
    ataxiaTemp.monkRipplestrikeReadyAt = getEpoch() + 27   -- just fired
    local cmd = ataxiaBasher_monkBattlerage("::")
    expect(cmd:find("rpst", 1, true)).toBeNil()
    expect(cmd).toBe("tnk " .. target .. "::")             -- damage instead of a wasted RPST
    ataxiaTemp.monkRipplestrikeReadyAt = nil
  end)

  it("fires Ripplestrike again once the timestamp expires", function()
    monkReset(true); ataxia.vitals.rage = 100
    ataxiaTemp.monkRipplestrikeReadyAt = getEpoch() - 1    -- elapsed
    expect(ataxiaBasher_monkBattlerage("::")).toBe("rpst " .. target .. "::")
    ataxiaTemp.monkRipplestrikeReadyAt = nil
  end)

  it("does NOT waste Ripplestrike when nothing is healing", function()
    monkReset(false); ataxia.vitals.rage = 100
    local cmd = ataxiaBasher_monkBattlerage("::")
    expect(cmd:find("rpst", 1, true)).toBeNil()
    expect(cmd).toBe("tnk " .. target .. "::")   -- biggest affordable damage instead
  end)

  -- The denizen-state module isn't loaded here, so stub the reader the rotation guards on
  -- (production nil-guards it: `ataxiaBasher_dsHasAff and ataxiaBasher_dsHasAff(...)`).
  it("does not re-apply Inhibit to an already-inhibited denizen", function()
    monkReset(true); ataxia.vitals.rage = 100
    local prev = ataxiaBasher_dsHasAff
    ataxiaBasher_dsHasAff = function(_, aff) return aff == "inhibit" end
    local cmd = ataxiaBasher_monkBattlerage("::")
    ataxiaBasher_dsHasAff = prev
    expect(cmd:find("rpst", 1, true)).toBeNil()
    expect(cmd).toBe("tnk " .. target .. "::")   -- damage instead, not wasted rage
  end)

  it("spends surplus on Scramble (Clumsy) when damage is on cooldown", function()
    monkReset(false); ataxia.vitals.rage = 100
    battleRage_Timers.large, battleRage_Timers.small = 1, 1
    expect(ataxiaBasher_monkBattlerage("::")).toBe("mind scramble " .. target .. "::")
  end)

  it("never spends rage on shields (spk is unreachable)", function()
    monkReset(true); ataxia.vitals.rage = 100
    ataxiaBasher.shielded = true
    expect(ataxiaBasher_monkBattlerage("::"):find("spk", 1, true)).toBeNil()
  end)

  it("falls to the cheap filler rather than idling rage", function()
    monkReset(false); ataxia.vitals.rage = 20   -- under tnk's 36
    expect(ataxiaBasher_monkBattlerage("::")).toBe("sbp " .. target .. "::")
  end)

  it("is PvP-inert (string target)", function()
    monkReset(true); ataxia.vitals.rage = 100
    target = "Penwize"
    expect(ataxiaBasher_monkBattlerage("::")).toBe("")
    target = 12345
  end)
end)

-- ── Magi: owns culling; Stormbolt->Sensitivity->Squeeze; Firefall on clumsy/reckless ──────
-- Kit: Windlash 14 (small), Dilation 35 (special->aeon), Squeeze 36 (large), Stormbolt 25
-- (specialafflict->sensitivity), Firefall 25 (specialuse, bonus vs clumsy/reckless). Disintegrate
-- (raze, shield break) is NEVER fired -- magiBashing casts the free `erode`. Dilation/Stormbolt
-- gate on their own aff (aeon/sensitivity) plus a short in-flight bridge.
describe("ataxiaBasher_magiBattlerage", function()

  local magiAffs = {}
  local function magiReset()
    reset()
    target = 1                       -- a prior block's PvP-inert test can leave this non-1
    gmcp.Char.Status.class = "Magi"
    ataxiaBasher.battlerage = ataxiaBasher.battlerage or {}
    ataxiaBasher.battlerage["Magi"] = {
      small = "cast windlash at 1", large = "cast squeeze 1", special = "cast dilation at 1",
      specialafflict = "cast stormbolt at 1", specialuse = "cast firefall at 1",
      raze = "cast disintegrate at 1",
    }
    magiAffs = {}
    ataxiaBasher_dsHasAff = function(_, a) return magiAffs[a] == true end
    ataxiaTemp.magiDilationReadyAt = nil
    ataxiaTemp.magiStormboltReadyAt = nil
    ataxiaTemp.magiFirefallReadyAt = nil
    ataxiaTemp.magiWindlashReadyAt = nil
  end

  it("owns culling: reap at >=36 when cullingBlade is on", function()
    magiReset(); ataxiaBasher.cullingBlade = true; ataxia.vitals.rage = 100
    expect(ataxiaBasher_magiBattlerage(";")).toBe("reap 1;")
  end)

  it("Mnemosyne: Dilation (aeon) is the mitigation priority", function()
    magiReset(); ataxiaBasher.inMnemosyne = true; ataxia.vitals.rage = 100
    expect(ataxiaBasher_magiBattlerage(";")).toBe("cast dilation at 1;")
  end)

  it("does not re-apply Dilation once the target is already aeon'd", function()
    magiReset(); ataxiaBasher.inMnemosyne = true; ataxia.vitals.rage = 100
    magiAffs.aeon = true
    local cmd = ataxiaBasher_magiBattlerage(";")
    expect(cmd:find("dilation", 1, true)).toBeNil()
    expect(cmd).toBe("cast stormbolt at 1;")     -- moves on to the Sensitivity setup
  end)

  it("Firefall when the target is clumsy or reckless (from any source)", function()
    magiReset(); ataxia.vitals.rage = 100; magiAffs.recklessness = true  -- BR_AFFS key is 'recklessness'
    expect(ataxiaBasher_magiBattlerage(";")).toBe("cast firefall at 1;")
    magiReset(); ataxia.vitals.rage = 100; magiAffs.clumsy = true
    expect(ataxiaBasher_magiBattlerage(";")).toBe("cast firefall at 1;")
  end)

  it("Stormbolt->Sensitivity when not sensitive, then Squeeze once sensitive", function()
    magiReset(); ataxia.vitals.rage = 100
    expect(ataxiaBasher_magiBattlerage(";")).toBe("cast stormbolt at 1;")
    magiReset(); ataxia.vitals.rage = 100; magiAffs.sensitivity = true
    expect(ataxiaBasher_magiBattlerage(";")).toBe("cast squeeze 1;")
  end)

  it("bridges Stormbolt so it doesn't re-cast before the Sensitivity line lands", function()
    magiReset(); ataxia.vitals.rage = 100
    ataxiaBasher_magiBattlerage(";")             -- fires stormbolt, arms bridge + global cd
    ataxiaTemp.brGlobalReadyAt = nil             -- clear the 1s global to isolate the bridge
    local cmd = ataxiaBasher_magiBattlerage(";")
    expect(cmd:find("stormbolt", 1, true)).toBeNil()   -- bridge holds
    expect(cmd).toBe("cast squeeze 1;")
  end)

  it("never fires Disintegrate/raze (erode strips shields for free)", function()
    magiReset(); ataxia.vitals.rage = 100; magiAffs.sensitivity = true
    battleRage_Timers.large = 1                  -- squeeze on cd
    expect(ataxiaBasher_magiBattlerage(";"):find("disintegrate", 1, true)).toBeNil()
  end)

  it("falls to Windlash filler rather than idling rage", function()
    magiReset(); ataxia.vitals.rage = 20; magiAffs.sensitivity = true  -- under squeeze's 36
    expect(ataxiaBasher_magiBattlerage(";")).toBe("cast windlash at 1;")
  end)

  it("does not re-fire Windlash while its 16s cooldown is up (returns empty)", function()
    magiReset(); ataxia.vitals.rage = 20; magiAffs.sensitivity = true
    ataxiaBasher_magiBattlerage(";")            -- fires windlash, arms its cd + global
    ataxiaTemp.brGlobalReadyAt = nil            -- isolate the windlash cd from the 1s global
    expect(ataxiaBasher_magiBattlerage(";")).toBe("")   -- nothing else affordable, windlash on cd
  end)

  it("respects the ~1s global BR cooldown", function()
    magiReset(); ataxia.vitals.rage = 100
    ataxiaTemp.brGlobalReadyAt = getEpoch() + 1
    expect(ataxiaBasher_magiBattlerage(";")).toBe("")
  end)

  it("is PvP-inert (string target)", function()
    magiReset(); ataxia.vitals.rage = 100; target = "Penwize"
    expect(ataxiaBasher_magiBattlerage(";")).toBe("")
    target = 1
  end)
end)

describe("ataxiaBasher_magiShouldBloodboil", function()
  -- Bloodboil fires from magiBashing's equilibrium slot for two independent reasons:
  --   CURE  -- 3+ real afflictions while OUR tree tattoo is on balance (ataxiaTemp.usedTree).
  --   HEAL  -- Hot Springs boon + low HP + the boon's 30s heal off cooldown.
  local function bloodboilReset()
    gmcp.Char.Status.class = "Magi"
    ataxiaTemp.usedTree = true                -- OUR tree tattoo is on balance (down)
    magiHotSprings = false                    -- heal boon off unless a test enables it
    ataxia.vitals.mp = 1000                   -- plenty of mana
    ataxia.vitals.hpp = 100                   -- full HP unless a test lowers it
    ataxia.afflictions = { asthma = true, slickness = true, clumsiness = true }  -- 3 affs
  end

  -- CURE branch --------------------------------------------------------------
  it("cures at 3+ affs while OUR tree is on balance", function()
    bloodboilReset()
    expect(ataxiaBasher_magiShouldBloodboil()).toBe(true)
  end)

  it("holds while OUR tree tattoo is up (passive cure handles it)", function()
    bloodboilReset(); ataxiaTemp.usedTree = nil
    expect(ataxiaBasher_magiShouldBloodboil()).toBe(false)
  end)

  it("holds below 3 afflictions", function()
    bloodboilReset(); ataxia.afflictions = { asthma = true, slickness = true }
    expect(ataxiaBasher_magiShouldBloodboil()).toBe(false)
  end)

  it("counts only real affs -- ignores incoming_* predictions and cured (0) stacks", function()
    bloodboilReset()
    ataxia.afflictions = { asthma = true, slickness = true, incoming_paralysis = true, crescendo = 0 }
    expect(ataxiaBasher_magiShouldBloodboil()).toBe(false)   -- only 2 real affs
  end)

  it("does not cast while haemophilic (the spell just fails)", function()
    bloodboilReset(); ataxia.afflictions.haemophilia = true  -- now 4 affs but blood too thin
    expect(ataxiaBasher_magiShouldBloodboil()).toBe(false)
  end)

  it("holds when mana can't cover the 75 cost", function()
    bloodboilReset(); ataxia.vitals.mp = 40
    expect(ataxiaBasher_magiShouldBloodboil()).toBe(false)
  end)

  it("is Magi-only (class guard)", function()
    bloodboilReset(); gmcp.Char.Status.class = "Blademaster"
    expect(ataxiaBasher_magiShouldBloodboil()).toBe(false)
    gmcp.Char.Status.class = "Magi"
  end)

  -- HEAL branch (Hot Springs boon) -------------------------------------------
  it("heals on the Hot Springs boon at low HP, even with tree up and no affs", function()
    bloodboilReset()
    magiHotSprings = true; ataxia.vitals.hpp = 45
    ataxiaTemp.usedTree = nil; ataxia.afflictions = {}   -- no cure reason
    expect(ataxiaBasher_magiShouldBloodboil()).toBe(true)
  end)

  it("keeps returning true across cycles while HP stays low (no self-cd -> no addclearfull clobber)", function()
    bloodboilReset()
    magiHotSprings = true; ataxia.vitals.hpp = 45
    ataxiaTemp.usedTree = nil; ataxia.afflictions = {}
    -- Must stay stable so the re-queued `cast bloodboil` isn't clobbered before eq fires it.
    expect(ataxiaBasher_magiShouldBloodboil()).toBe(true)
    expect(ataxiaBasher_magiShouldBloodboil()).toBe(true)
    expect(ataxiaBasher_magiShouldBloodboil()).toBe(true)
  end)

  it("does not heal at healthy HP even with the boon", function()
    bloodboilReset()
    magiHotSprings = true; ataxia.vitals.hpp = 85
    ataxiaTemp.usedTree = nil; ataxia.afflictions = {}
    expect(ataxiaBasher_magiShouldBloodboil()).toBe(false)
  end)

  it("does not heal on low HP without the boon", function()
    bloodboilReset()
    magiHotSprings = false; ataxia.vitals.hpp = 30
    ataxiaTemp.usedTree = nil; ataxia.afflictions = {}
    expect(ataxiaBasher_magiShouldBloodboil()).toBe(false)
  end)

  it("is reload-safe: nil afflictions do not crash even past the mana guard (exercises the cure loop)", function()
    bloodboilReset()
    ataxia.vitals = { mp = 1000, hpp = 100 }   -- mana passes the guard so we reach the cure loop
    ataxiaTemp.usedTree = true                  -- force into the cure path
    ataxia.afflictions = nil                    -- `affs or {}` must keep pairs() from crashing
    expect(ataxiaBasher_magiShouldBloodboil()).toBe(false)
    ataxia.vitals = { rage = 0, mp = 1000, hpp = 100 }  -- restore for later blocks
  end)
end)

-- Regression: gsub returns (string, COUNT) -- an unparenthesized gsub call as
-- tonumber's argument expands to tonumber(str, count), and count is read as a BASE
-- ("base out of range"). This killed the ENTIRE attack dispatch on every prompt for
-- a live Psion (first class whose battlerage branch parses hpperc). The fix wraps
-- the gsub in truncating parens; these tests feed live-shaped "NN%" strings.
describe("ataxiaBasher_assembleBattlerage -- hpperc parsing (multi-return trap)", function()
  local function psionReset()
    gmcp.Char.Status.class = "Psion"
    gmcp.Char.Status.level = "80 "
    gmcp.IRE.Target.Info = { hpperc = "66%" } -- live shape: string WITH the percent sign
    battleRage_Timers = {}
    ataxia.vitals.rage = 100
    ataxiaBasher.cullingBlade = nil
    ataxiaBasher.rageraze = nil
    ataxiaBasher.rageConserveThreshold = nil
    ataxiaBasher.battlerage.Psion = {
      small = "weave barbedblade 1", large = "weave whirlwind 1",
      special = "enact regrowth 1", raze = "weave pulverise 1",
    }
  end

  it("survives a percent-suffixed hpperc for any class (Psion routes to 002 now)", function()
    psionReset()
    -- v4.7.128: the assembler's Psion branch moved to ataxiaBasher_psionBattlerage
    -- (002, timer-free); the assembler must still parse hpperc safely for the
    -- rage-conservation path shared by every class.
    local ok = pcall(ataxiaBasher_assembleBattlerage)
    expect(ok).toBeTrue()
  end)

  it("rage conservation reads hpperc strings without erroring", function()
    psionReset()
    ataxiaBasher.rageConserveThreshold = 15
    gmcp.IRE.Target.Info.hpperc = "10%"
    local ok, cmd = pcall(ataxiaBasher_assembleBattlerage)
    expect(ok).toBeTrue()
    expect(cmd).toBe("") -- nearly dead mob: rage conserved
    ataxiaBasher.rageConserveThreshold = nil
    gmcp.Char.Status.class = "Blademaster" -- restore for any later blocks
  end)
end)

-- ─── Rage floor (v4.7.141) ───────────────────────────────────────────
-- Gear pays a damage bonus while rage stays at/above a threshold, so
-- `ataxiaBasher.rageFloor = N` makes every rotation spend only the SURPLUS: an
-- ability costing C fires at C + N. Culling reap is deliberately exempt -- an
-- execute that ends the fight beats a per-swing multiplier. Blademaster costs:
-- reap 36 (exempt), spinslash 36, daze 26, headstrike 25, nerveslash 22,
-- leapstrike 14. NOTE: each successful call arms the ~1s global BR cooldown, so
-- every assertion below re-resets (reset() clears brGlobalReadyAt).
-- CULLING vs THE FLOOR (v4.7.229). User: "we need to keep 40 battlerage at all times in order
-- to increase our damage by 23 percent." Culling was exempt from the floor unconditionally --
-- right for Golden Dragon's `reap` (an EXECUTE; a kill beats a bonus on swings that never
-- happen), wrong for the artifact culling blade on a class like Bard, where firing at 36 rage
-- drops us under a 40 floor and switches the bonus off for roughly a dozen swings.
describe("ataxiaBasher_cullAfford -- the exemption is now a setting", function()
  local function cullReset(floor, floorCulling)
    reset()
    gmcp.Char.Status.class = "Blademaster"
    ataxiaBasher.rageFloor = floor
    ataxiaBasher.floorCulling = floorCulling
  end

  it("keeps the exemption by DEFAULT -- reap still fires on the floor", function()
    cullReset(40, nil)
    expect(ataxiaBasher_cullAfford(36, 36)).toBeTrue()  -- would breach a 40 floor, allowed
    expect(ataxiaBasher_cullAfford(35, 36)).toBeFalse() -- but still needs the cost itself
    cullReset(nil, nil)
  end)

  it("respects the floor once `bash floor culling` is on", function()
    cullReset(40, true)
    expect(ataxiaBasher_cullAfford(36, 36)).toBeFalse() -- 36 would leave 0, under the floor
    expect(ataxiaBasher_cullAfford(75, 36)).toBeFalse() -- needs 36 + 40
    expect(ataxiaBasher_cullAfford(76, 36)).toBeTrue()
    cullReset(nil, nil)
  end)

  it("is unchanged when no floor is set, either way", function()
    for _, fc in ipairs({ false, true }) do
      cullReset(nil, fc)
      expect(ataxiaBasher_cullAfford(36, 36)).toBeTrue()
      expect(ataxiaBasher_cullAfford(35, 36)).toBeFalse()
    end
    cullReset(nil, nil)
  end)

  -- A FREE battlerage costs no rage, so it can never breach the floor -- and must stay
  -- allowed even with culling floored, or the free charge is simply wasted.
  it("still allows a free battlerage below the floor", function()
    cullReset(40, true)
    ataxiaTemp.brFreeCharge = true
    expect(ataxiaBasher_cullAfford(0, 36)).toBeTrue()
    ataxiaTemp.brFreeCharge = nil
    cullReset(nil, nil)
  end)
end)

describe("rage floor -- spend only the surplus", function()
  local function floorReset(floor)
    reset()
    gmcp.Char.Status.class = "Blademaster"
    ataxiaBasher.rageFloor = floor
  end

  it("is OFF by default -- rageAfford is a plain >= then", function()
    floorReset(nil)
    expect(ataxiaBasher_rageAfford(14, 14)).toBeTrue()
    expect(ataxiaBasher_rageAfford(13, 14)).toBeFalse()
  end)

  it("requires cost + floor once set", function()
    floorReset(40)
    expect(ataxiaBasher_rageAfford(53, 14)).toBeFalse() -- leapstrike needs 54
    expect(ataxiaBasher_rageAfford(54, 14)).toBeTrue()
    expect(ataxiaBasher_rageAfford(75, 36)).toBeFalse() -- spinslash needs 76
    expect(ataxiaBasher_rageAfford(76, 36)).toBeTrue()
    floorReset(nil)
  end)

  it("holds the line: 53 rage buys NOTHING at floor 40", function()
    floorReset(nil); ataxia.vitals.rage = 53
    expect(ataxiaBasher_blademasterBattlerage(";")).toBe("spinslash 1;") -- floor off: spends
    floorReset(40); ataxia.vitals.rage = 53
    expect(ataxiaBasher_blademasterBattlerage(";")).toBe("") -- nothing affordable above the floor
    floorReset(nil)
  end)

  it("spends the surplus once it covers an ability", function()
    floorReset(40); ataxia.vitals.rage = 54
    expect(ataxiaBasher_blademasterBattlerage(";")).toBe("leapstrike 1;") -- 14 + 40
    floorReset(40); ataxia.vitals.rage = 76
    expect(ataxiaBasher_blademasterBattlerage(";")).toBe("spinslash 1;")  -- 36 + 40
    floorReset(nil)
  end)

  it("NEVER floors culling reap -- the execute outranks the multiplier", function()
    floorReset(40); ataxiaBasher.cullingBlade = true
    ataxia.vitals.rage = 36 -- exactly reap's cost, far below reap + floor
    expect(ataxiaBasher_blademasterBattlerage(";")).toBe("reap 1;")
    floorReset(40); ataxiaBasher.cullingBlade = true
    ataxia.vitals.rage = 39
    expect(ataxiaBasher_blademasterBattlerage(";")).toBe("reap 1;")
    floorReset(nil)
  end)
end)

-- ---------------------------------------------------------------------------
-- Bard CYCLONE: cash in a denizen carrying STUN or CLUMSY (v4.7.210, user rule)
-- ---------------------------------------------------------------------------
-- Same shape as Runewarden's Etch and Blademaster's Headstrike -- an ability that spends an
-- affliction already on the mob -- so it beats generic damage but yields to the crowd
-- abilities, since charm removes a mob from the fight entirely.
describe("bard cyclone -- exploits stun or clumsy", function()
  local affs
  local function setup(rage, denizens)
    ataxiaTemp = {}
    affs = {}
    ataxia.vitals = ataxia.vitals or {}
    ataxia.vitals.rage = rage or 100
    target = 7
    ataxiaBasher.cullingBlade = false
    ataxiaBasher.bardCycloneRage, ataxiaBasher.bardCycloneCd = nil, nil
    ataxiaBasher.bardCycloneCmd = nil
    battleRage_Timers = { small = false, large = false, special = false }
    ataxiaBasher_validTargets = function() return denizens or 1 end
    stormhammerTargets = { 7, 9 }
    ataxiaBasher_dsHasAff = function(_, a) return affs[a] == true end
  end

  it("does not fire on a clean denizen", function()
    setup()
    local cmd = ataxiaBasher_bardBattlerage(";")
    expect(cmd:find("cyclone", 1, true)).toBe(nil)
    expect(cmd:find("howlslash", 1, true) ~= nil).toBeTrue()
  end)

  it("fires on STUN", function()
    setup(); affs.stun = true
    expect(ataxiaBasher_bardBattlerage(";")).toBe("cyclone 7;")
  end)

  it("fires on CLUMSY", function()
    setup(); affs.clumsy = true
    expect(ataxiaBasher_bardBattlerage(";")).toBe("cyclone 7;")
  end)

  it("beats generic damage -- that is the whole point of an exploit", function()
    setup(100); affs.stun = true
    local cmd = ataxiaBasher_bardBattlerage(";")
    expect(cmd:find("howlslash", 1, true)).toBe(nil)
    expect(cmd:find("moulinet", 1, true)).toBe(nil)
  end)

  -- Charm takes a mob out of the fight; a bonus on one mob does not.
  it("still yields to the crowd abilities at 2+ denizens", function()
    setup(100, 2); affs.stun = true
    expect(ataxiaBasher_bardBattlerage(";")).toBe("play charm at 9;")
  end)

  it("honours its own cooldown, then fires again", function()
    setup(); affs.stun = true
    expect(ataxiaBasher_bardBattlerage(";")).toBe("cyclone 7;")
    expect(ataxiaBasher_bardBattlerage(";"):find("cyclone", 1, true)).toBe(nil) -- cooling
    ataxiaTemp.bardCycloneAt = 0
    expect(ataxiaBasher_bardBattlerage(";")).toBe("cyclone 7;")
  end)

  it("respects the rage cost, and the rage floor through rageAfford", function()
    setup(24); affs.stun = true
    expect(ataxiaBasher_bardBattlerage(";"):find("cyclone", 1, true)).toBe(nil)
    setup(25); affs.stun = true
    expect(ataxiaBasher_bardBattlerage(";")).toBe("cyclone 7;")
  end)

  -- The command, cost and cooldown are UNCONFIRMED game data, so all three are settings.
  it("takes a configured command, cost and cooldown", function()
    setup(30); affs.clumsy = true
    ataxiaBasher.bardCycloneCmd = "play cyclone at"
    ataxiaBasher.bardCycloneRage = 30
    expect(ataxiaBasher_bardBattlerage(";")).toBe("play cyclone at 7;")
    setup(29); affs.clumsy = true
    ataxiaBasher.bardCycloneRage = 30
    expect(ataxiaBasher_bardBattlerage(";"):find("cyclone", 1, true)).toBe(nil)
  end)

  it("is inert when the denizen-state layer is absent (PvP / no basher)", function()
    setup(); affs.stun = true
    ataxiaBasher_dsHasAff = nil
    expect(ataxiaBasher_bardBattlerage(";"):find("cyclone", 1, true)).toBe(nil)
  end)
end)
