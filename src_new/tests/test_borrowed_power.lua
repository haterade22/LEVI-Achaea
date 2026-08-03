--- test_borrowed_power.lua -- the Borrowed Power paragon swap (v4.7.204)
--
-- "Your critical hits can now reach plane-razing level without requiring paragons or the
-- Psion class. THIS DOES NOT STACK with those effects, however."
--
-- The non-stacking clause is the actionable part: while the boon is up, the paragon that buys
-- crit TIER sits in an embrasure doing nothing. Swap it for the willpower or shifting-damage
-- one (user, 2026-08-03) -- and, more importantly, swap it BACK, because the boon is per-run
-- and a stuck swap would cost the crit paragon everywhere outside the tower.

require("mock_mudlet")

ataxia = { settings = { separator = ";" } }
function ataxia_saveSettings() end

local swapped
ataxia.armour = {
  config = { profiles = {}, paragons = {}, bashProfile = "bash" },
  state = {},
}
function ataxia.armour.echo() end
function ataxia.armour.save() end
function ataxia.armour.swap(name) swapped = name; return true end
function ataxia.armour.paragonName(id) return ataxia.armour.config.paragons[id] end

-- Slice out just the three Borrowed Power helpers: the file as a whole needs a live Mudlet
-- (Geyser, timers, the alias dispatcher), but these are pure decision logic.
local SRC = "src_new/scripts/levi_ataxia/levi/levi_scripts/gear_system/002_Armour_Paragons.lua"
-- Sliced by plain offsets, not a newline-bearing pattern: this source is CRLF, so `.-\nend\n`
-- silently fails to match.
local body = io.open(SRC):read("*a")
local from = body:find("ataxia.armour.config.borrowedRedundant", 1, true)
local to = body:find("function ataxia.armour.addProfile", 1, true)
assert(from and to and to > from,
  "could not slice the Borrowed Power helpers out of " .. SRC)
-- `loadstring` is 5.1-only; the runner may be on a newer Lua, where it is `load`.
local loadfn = loadstring or load
assert(loadfn(body:sub(from, to - 1)))()

local function reset()
  swapped = nil
  ataxia.armour.config.borrowed = nil
  ataxia.armour.config.borrowedReplacement = nil
  ataxia.armour.config.borrowedRedundant = { "crucious" }
  ataxia.armour.config.bashProfile = "bash"
  ataxia.armour.config.paragons = {
    ["p_icosagon"] = "icosagon (20% crit)",
    ["p_crucious"] = "crucious (crit multiplier)",
    ["p_metal"]    = "metalliferous (7.5% resist)",
    ["p_serendip"] = "serendipitous (5% dmg->WP)",
  }
  ataxia.armour.config.profiles = {
    bash = { slots = { "p_icosagon", "p_serendip", "p_crucious" }, traits = { "quick-witted" } },
  }
end

describe("which paragon the boon makes redundant", function()
  it("crucious (crit MULTIPLIER) is dead weight -- plane-razing is a tier", function()
    reset()
    expect(ataxia.armour.isBorrowedRedundant("p_crucious")).toBeTrue()
  end)

  it("icosagon is NOT -- it buys crit CHANCE, which the boon does not grant", function()
    reset()
    expect(ataxia.armour.isBorrowedRedundant("p_icosagon")).toBeFalse()
  end)

  it("nor is anything unrelated, nor an unknown id", function()
    reset()
    expect(ataxia.armour.isBorrowedRedundant("p_metal")).toBeFalse()
    expect(ataxia.armour.isBorrowedRedundant("nonsense")).toBeFalse()
  end)
end)

describe("what goes in its place", function()
  it("prefers the shifting-damage paragon (the willpower one is usually already worn)", function()
    reset()
    expect(ataxia.armour.borrowedReplacementId()).toBe("p_metal")
  end)

  it("falls back to the willpower paragon when there is no shifting one", function()
    reset()
    ataxia.armour.config.paragons.p_metal = nil
    expect(ataxia.armour.borrowedReplacementId()).toBe("p_serendip")
  end)

  it("honours an explicit choice", function()
    reset()
    ataxia.armour.config.borrowedReplacement = "p_serendip"
    expect(ataxia.armour.borrowedReplacementId()).toBe("p_serendip")
  end)

  it("returns nothing when neither is known, rather than guessing", function()
    reset()
    ataxia.armour.config.paragons = { ["p_crucious"] = "crucious (crit multiplier)" }
    expect(ataxia.armour.borrowedReplacementId()).toBe(nil)
  end)
end)

describe("the swap", function()
  it("builds a `borrowed` profile with the crit slot replaced, and wears it", function()
    reset()
    expect(ataxia.armour.borrowedPower(true)).toBeTrue()
    expect(swapped).toBe("borrowed")
    local b = ataxia.armour.config.profiles.borrowed
    expect(b.slots[1]).toBe("p_icosagon") -- crit CHANCE kept
    expect(b.slots[2]).toBe("p_serendip") -- untouched
    expect(b.slots[3]).toBe("p_metal")    -- crit MULTIPLIER replaced
  end)

  it("carries the base profile's traits across", function()
    reset()
    ataxia.armour.borrowedPower(true)
    expect(ataxia.armour.config.profiles.borrowed.traits[1]).toBe("quick-witted")
  end)

  it("does nothing when the bash profile holds no crit paragon", function()
    reset()
    ataxia.armour.config.profiles.bash.slots = { "p_icosagon", "p_serendip", "p_metal" }
    expect(ataxia.armour.borrowedPower(true)).toBeFalse()
    expect(swapped).toBe(nil)
  end)

  it("does nothing when no replacement paragon is known", function()
    reset()
    ataxia.armour.config.paragons.p_metal = nil
    ataxia.armour.config.paragons.p_serendip = nil
    expect(ataxia.armour.borrowedPower(true)).toBeFalse()
    expect(swapped).toBe(nil)
  end)

  it("respects the opt-out", function()
    reset()
    ataxia.armour.config.borrowed = false
    expect(ataxia.armour.borrowedPower(true)).toBeFalse()
    expect(swapped).toBe(nil)
  end)
end)

-- The half that actually matters: the boon is per-RUN, so a swap left in place would cost the
-- crit paragon everywhere outside the tower.
describe("reverting", function()
  it("goes back to the bash profile when the boon ends", function()
    reset()
    ataxia.armour.borrowedPower(true)
    expect(swapped).toBe("borrowed")
    ataxia.armour.borrowedPower(false)
    expect(swapped).toBe("bash")
  end)

  it("reverts to whatever bashProfile actually names, not a hardcoded 'bash'", function()
    reset()
    ataxia.armour.config.bashProfile = "mypve"
    ataxia.armour.config.profiles.mypve = { slots = { "p_crucious" } }
    ataxia.armour.borrowedPower(false)
    expect(swapped).toBe("mypve")
  end)

  it("does not blow up when the base profile is missing", function()
    reset()
    ataxia.armour.config.profiles.bash = nil
    expect(ataxia.armour.borrowedPower(false)).toBeFalse()
  end)
end)

-- Restore shared state for whoever runs after us (files share one Lua state).
ataxia.armour = nil
