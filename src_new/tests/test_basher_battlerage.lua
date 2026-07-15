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
  ataxiaTemp.bladeCooldown = nil
  ataxiaTemp.bmHeadstrikeReadyAt = nil
  exploitReturn = nil
  gmcp.Room.Info.area = ""
end

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

  it("respects the Headstrike 25-rage gate (24 -> Leapstrike, 25 -> Headstrike)", function()
    reset(); exploitReturn = "headstrike"; ataxia.vitals.rage = 24
    expect(ataxiaBasher_blademasterBattlerage(";")).toBe("leapstrike 1;") -- Headstrike unaffordable
    reset(); exploitReturn = "headstrike"; ataxia.vitals.rage = 25
    expect(ataxiaBasher_blademasterBattlerage(";")).toBe("strike 1 head;")
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
