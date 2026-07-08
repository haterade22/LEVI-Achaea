--- test_basher_falconrake.lua — Runewarden falcon rake cooldown infrastructure
-- Loads 005_Falcon_Cooldowns.lua and verifies the falcon rake cooldown flag flips
-- on use and resets, mirroring the Infernal hyena maul.

local mock = require("mock_mudlet")

function exists(name, kind) return 0 end

ataxiaBasher = {}

local cd_file = "src_new/scripts/levi_ataxia/levi/ataxia/basher/005_Falcon_Cooldowns.lua"
local ok, err = pcall(dofile, cd_file)
if not ok then error("Failed to load falcon cooldowns file: " .. tostring(err)) end

describe("Runewarden falcon rake cooldown", function()

  it("initializes ready with a 30s default cooldown", function()
    expect(ataxiaBasher.falconRakeReady).toBeTrue()
    expect(ataxiaBasher.falconRakeCooldownSec).toBe(30)
  end)

  it("goes on cooldown when the rake fires", function()
    ataxiaBasher.falconRakeReady = true
    ataxiaBasher_falconRakeCooldown()
    expect(ataxiaBasher.falconRakeReady).toBeFalse()
  end)

  it("schedules a reset timer while on cooldown", function()
    mock.reset()
    ataxiaBasher.falconRakeReady = true
    ataxiaBasher_falconRakeCooldown()
    local timers = 0
    for _ in pairs(mock.active_timers) do timers = timers + 1 end
    expect(timers).toBeGreaterThan(0)
  end)

  it("becomes ready again on the ready message / timer", function()
    ataxiaBasher.falconRakeReady = false
    ataxiaBasher_falconRakeReady()
    expect(ataxiaBasher.falconRakeReady).toBeTrue()
  end)

end)
