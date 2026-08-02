--- test_reload_safe_cooldowns.lua -- transient cooldowns must not ride the saved namespace
--
-- v4.7.194. `ataxia` is serialized wholesale (`table.save(file_loc, sanitizeForSave(ataxia))`)
-- and merged back on load with an unconditional `dst[k] = v`. A tempTimer is NOT serialized
-- and does not survive a relog or a SYSUPDATE package reload. So any flag that is
--
--     set true on use, and cleared only by a tempTimer,
--
-- and that lives under `ataxia`, comes back from disk stuck ON with nothing alive to ever
-- clear it -- permanently disabling whatever it guards. Three emergency abilities were built
-- exactly that way:
--
--   ataxia.wandReflectionCooldown   1 HOUR   -- being interrupted mid-cooldown is the NORMAL
--                                              case at that length, not an edge case
--   ataxia.maranCooldown            65s      -- emergency 5000hp barrier at <=25% hp
--   ataxia.vultureTalon.onCooldown  180s     -- caloric defence vs Blademaster/Magi
--
-- The fix is the convention the battlerage rotations already use: a reload-safe TIMESTAMP on
-- `ataxiaTemp`. Worst case after a reload is one early re-use; never a permanent lockout.
--
-- These tests model the persistence round-trip directly, because that is the part that was
-- never exercised -- each feature's own logic was correct in isolation.

require("mock_mudlet")

local _epoch = getEpoch
local clock = 900000
getEpoch = function() return clock end

-- The load-time merge: exactly what deepMerge does for a non-table value.
local function reload(saved, live)
  for k, v in pairs(saved) do
    if type(v) ~= "table" then live[k] = v end
  end
  return live
end

describe("the serialized-flag trap, modelled", function()
  it("a boolean under `ataxia` survives the reload that kills its timer", function()
    local saved = { maranCooldown = true }          -- saved mid-cooldown
    local live  = { maranCooldown = false }         -- fresh script defaults
    reload(saved, live)
    -- The tempTimer that would have cleared it did not come back.
    expect(live.maranCooldown).toBeTrue()           -- stuck ON, forever
  end)

  it("a TIMESTAMP on ataxiaTemp simply is not there after a reload", function()
    ataxiaTemp = {}                                  -- ataxiaTemp is never serialized
    expect(ataxiaTemp.maranAt).toBe(nil)
    -- ...and a nil stamp reads as READY, which is the safe direction.
  end)
end)

describe("vulture talon -- reload-safe cooldown", function()
  local function load()
    ataxia = { vultureTalon = {} }
    ataxiaTemp = {}
    dofile("src_new/scripts/levi_ataxia/levi/ataxia/swaps/005_Vulture_Talon.lua")
  end

  it("is ready on a fresh profile", function()
    load()
    expect(ataxia_vultureTalonReady()).toBeTrue()
  end)

  it("is NOT ready immediately after use", function()
    load()
    ataxiaTemp.vultureTalonAt = clock
    expect(ataxia_vultureTalonReady()).toBeFalse()
  end)

  it("becomes ready again once the duration has elapsed", function()
    load()
    ataxiaTemp.vultureTalonAt = clock - 180
    expect(ataxia_vultureTalonReady()).toBeTrue()
  end)

  it("honours a user-configured duration", function()
    load()
    ataxia.vultureTalon.cooldownDuration = 600
    ataxiaTemp.vultureTalonAt = clock - 300
    expect(ataxia_vultureTalonReady()).toBeFalse()
    ataxiaTemp.vultureTalonAt = clock - 600
    expect(ataxia_vultureTalonReady()).toBeTrue()
  end)

  it("KEEPS the configured duration on the saved namespace", function()
    ataxia = { vultureTalon = { cooldownDuration = 240 } } -- as restored from disk
    ataxiaTemp = {}
    dofile("src_new/scripts/levi_ataxia/levi/ataxia/swaps/005_Vulture_Talon.lua")
    expect(ataxia.vultureTalon.cooldownDuration).toBe(240) -- config is not clobbered
  end)

  it("SCRUBS a legacy stuck cooldown restored from an old save", function()
    -- The regression: this is what a pre-v4.7.194 save file contains.
    ataxia = { vultureTalon = { onCooldown = true, cooldownTimer = 41, cooldownDuration = 180 } }
    ataxiaTemp = {}
    dofile("src_new/scripts/levi_ataxia/levi/ataxia/swaps/005_Vulture_Talon.lua")
    expect(ataxia.vultureTalon.onCooldown).toBe(nil)
    expect(ataxia.vultureTalon.cooldownTimer).toBe(nil) -- a stale id killTimer could misfire
    expect(ataxia_vultureTalonReady()).toBeTrue()       -- usable again, not locked out
  end)
end)

describe("wand of reflection and maran -- timestamp gates", function()
  -- Mirrors the two gates in ataxiaBasher_assembleAttack.
  local function ready(stamp, window)
    return (clock - (tonumber(stamp) or -math.huge)) >= window
  end

  it("the wand is ready on a fresh profile and after its hour", function()
    expect(ready(nil, 3600)).toBeTrue()
    expect(ready(clock - 3600, 3600)).toBeTrue()
  end)

  it("the wand is held for the full hour after firing", function()
    expect(ready(clock, 3600)).toBeFalse()
    expect(ready(clock - 3599, 3600)).toBeFalse()
  end)

  it("maran is held 65s -- longer than the 60s barrier it draws", function()
    expect(ready(clock, 65)).toBeFalse()
    expect(ready(clock - 64, 65)).toBeFalse()
    expect(ready(clock - 65, 65)).toBeTrue()
  end)

  it("a missing stamp always reads READY, so a reload can never lock either out", function()
    expect(ready(nil, 3600)).toBeTrue()
    expect(ready(nil, 65)).toBeTrue()
  end)
end)

-- Restore shared state for whoever runs after us (files share one Lua state).
getEpoch = _epoch
ataxiaTemp = {}
