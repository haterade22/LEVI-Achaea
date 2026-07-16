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
