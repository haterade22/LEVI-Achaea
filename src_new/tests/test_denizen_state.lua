--- test_denizen_state.lua — Unit tests for the per-denizen combat-state layer
-- Loads the real basher/008_Denizen_State.lua and exercises the pure logic:
-- room sync, affliction set/expire (injected clock), exploit mapping, name->id
-- resolution, swap-target picking, and PvP inertness (string ids are no-ops).

require("mock_mudlet") -- for its global side-effects (getEpoch, cecho, …)

-- Project globals the module reads
ataxia = ataxia or {}
ataxiaBasher = ataxiaBasher or {}
ataxiaTemp = ataxiaTemp or {}
-- Own-denizen check: treat anything containing "falcon" as a pet (mirrors the real one)
function ataxiaBasher_isOwnDenizen(name)
  return type(name) == "string" and name:lower():find("falcon") ~= nil
end

local mod = "src_new/scripts/levi_ataxia/levi/ataxia/basher/008_Denizen_State.lua"
local ok, err = pcall(dofile, mod)
if not ok then error("Failed to load denizen-state module: " .. tostring(err)) end

local function reset()
  ataxiaBasher_dsReset()
  ataxia.denizensHere = {}
end

-- ─── Room sync ───────────────────────────────────────────────────────────────
describe("ataxiaBasher_dsSync", function()
  it("adds newcomers and drops denizens that left, keying by numeric id", function()
    reset()
    ataxiaBasher_dsSync({ [10] = "a fire wyrm", [11] = "a wyrm whelp" })
    expect(ataxiaBasher_dsGet(10) ~= nil).toBeTrue()
    expect(ataxiaBasher_dsGet(11).name).toBe("a wyrm whelp")
    -- wyrm whelp leaves, a new mob arrives
    ataxiaBasher_dsSync({ [10] = "a fire wyrm", [12] = "a crimson pyrapede" })
    expect(ataxiaBasher_dsGet(11)).toBeNil()
    expect(ataxiaBasher_dsGet(12) ~= nil).toBeTrue()
  end)

  it("preserves existing affs for denizens that persist across a sync", function()
    reset()
    ataxiaBasher_dsSync({ [10] = "a fire wyrm" })
    ataxiaBasher_dsSetAff(10, "charm", 1000)
    ataxiaBasher_dsSync({ [10] = "a fire wyrm", [11] = "a wyrm whelp" })
    expect(ataxiaBasher_dsHasAff(10, "charm", 1001)).toBeTrue() -- still charmed after sync
  end)

  it("coerces string ids and ignores non-numeric keys (PvP-inert)", function()
    reset()
    ataxiaBasher_dsSync({ ["10"] = "a fire wyrm", ["Penwize"] = "a player" })
    expect(ataxiaBasher_dsGet(10) ~= nil).toBeTrue() -- "10" coerced to 10
    expect(ataxiaBasher_dsGet("Penwize")).toBeNil()  -- player name never tracked
  end)
end)

-- ─── Afflictions + lazy expiry ───────────────────────────────────────────────
describe("affliction set / has / expiry", function()
  it("charm lasts 5s then lazily expires on read", function()
    reset()
    ataxiaBasher_dsAdd(10, "a fire wyrm")
    ataxiaBasher_dsSetAff(10, "charm", 1000)      -- endsAt = 1005
    expect(ataxiaBasher_dsHasAff(10, "charm", 1004)).toBeTrue()
    expect(ataxiaBasher_dsHasAff(10, "charm", 1005)).toBeFalse() -- expired at endsAt
    expect(ataxiaBasher_dsGet(10).affs.charm).toBeNil()          -- and cleared
  end)

  it("a state with no duration (shielded) persists until explicitly cleared", function()
    reset()
    ataxiaBasher_dsAdd(10, "a fire wyrm")
    ataxiaBasher_dsSetAff(10, "shielded", 1000)
    expect(ataxiaBasher_dsHasAff(10, "shielded", 999999)).toBeTrue() -- never times out
    ataxiaBasher_dsClearAff(10, "shielded")
    expect(ataxiaBasher_dsHasAff(10, "shielded", 999999)).toBeFalse()
  end)

  it("setting an aff auto-creates the entry so it is never silently dropped", function()
    reset()
    ataxiaBasher_dsSetAff(999, "charm", 1000) -- 999 not synced yet
    expect(ataxiaBasher_dsHasAff(999, "charm", 1000)).toBeTrue()
    expect(ataxiaBasher_dsGet(999) ~= nil).toBeTrue()
  end)

  it("setting an aff on a non-numeric (player) id stays inert", function()
    reset()
    ataxiaBasher_dsSetAff("Penwize", "charm", 1000)
    expect(ataxiaBasher_dsGet("Penwize")).toBeNil()
  end)

  it("a nil-duration aff (amnesia) persists until cleared", function()
    reset()
    ataxiaBasher_dsAdd(10, "a mob")
    ataxiaBasher_dsSetAff(10, "amnesia", 1000)
    expect(ataxiaBasher_dsHasAff(10, "amnesia", 999999)).toBeTrue()
  end)
end)

-- ─── Exploit mapping (bonus-damage priority) ─────────────────────────────────
describe("ataxiaBasher_dsExploit", function()
  it("maps each state to the ability that cashes it in", function()
    reset()
    ataxiaBasher_dsAdd(1, "a mob"); ataxiaBasher_dsSetAff(1, "shielded", 1000)
    ataxiaBasher_dsAdd(2, "b mob"); ataxiaBasher_dsSetAff(2, "recklessness", 1000)
    ataxiaBasher_dsAdd(3, "c mob"); ataxiaBasher_dsSetAff(3, "sensitivity", 1000)
    ataxiaBasher_dsAdd(4, "d mob"); ataxiaBasher_dsSetAff(4, "ablaze", 1000)
    ataxiaBasher_dsAdd(5, "e mob")
    expect(ataxiaBasher_dsExploit(1, 1000)).toBe("shatter")
    expect(ataxiaBasher_dsExploit(2, 1000)).toBe("headstrike")
    expect(ataxiaBasher_dsExploit(3, 1000)).toBe("burst")
    expect(ataxiaBasher_dsExploit(4, 1000)).toBe("fire")
    expect(ataxiaBasher_dsExploit(5, 1000)).toBeNil()
  end)

  it("feared also enables headstrike; an expired aff does not", function()
    reset()
    ataxiaBasher_dsAdd(2, "b mob"); ataxiaBasher_dsSetAff(2, "feared", 1000) -- 8s
    expect(ataxiaBasher_dsExploit(2, 1007)).toBe("headstrike")
    expect(ataxiaBasher_dsExploit(2, 1008)).toBeNil() -- feared expired
  end)
end)

-- ─── name -> id resolution (for the charm-end line) ──────────────────────────
describe("ataxiaBasher_dsResolveNameToId", function()
  it("returns nil for no match (players / stale), the id for a unique match", function()
    reset()
    local dz = { [10] = "a fire wyrm", [11] = "a wyrm whelp" }
    expect(ataxiaBasher_dsResolveNameToId("Penwize", dz)).toBeNil()
    expect(ataxiaBasher_dsResolveNameToId("a fire wyrm", dz)).toBe(10)
  end)

  it("prefers a match carrying the preferred aff when the name is ambiguous", function()
    reset()
    local dz = { [10] = "a fire wyrm", [11] = "a fire wyrm" } -- two same-named mobs
    ataxiaBasher_dsAdd(10, "a fire wyrm"); ataxiaBasher_dsAdd(11, "a fire wyrm")
    ataxiaBasher_dsSetAff(11, "charm", 1000)
    expect(ataxiaBasher_dsResolveNameToId("a fire wyrm", dz, "charm", 1001)).toBe(11)
  end)
end)

-- ─── swap-target picking (charm-swap) ────────────────────────────────────────
describe("ataxiaBasher_dsPickAlt", function()
  it("skips the excluded id, own pets, and (optionally) charmed mobs", function()
    reset()
    local dz = { [10] = "a fire wyrm", [11] = "a hunting falcon", [12] = "a wyrm whelp" }
    ataxiaBasher_dsAdd(12, "a wyrm whelp"); ataxiaBasher_dsSetAff(12, "charm", 1000)
    -- exclude 10 (current target) and the falcon (own); 12 is charmed -> excluded when asked
    expect(ataxiaBasher_dsPickAlt(dz, 10, true, 1001)).toBeNil()
    -- allow charmed -> 12 is now eligible
    expect(ataxiaBasher_dsPickAlt(dz, 10, false, 1001)).toBe(12)
  end)
end)

-- ─── simple setters / delegates ──────────────────────────────────────────────
describe("dsSetHp / dsIsCharmed / dsRemove", function()
  it("dsSetHp auto-creates and stores the numeric HP%", function()
    reset()
    ataxiaBasher_dsSetHp(10, "61")
    expect(ataxiaBasher_dsGet(10).hpp).toBe(61)
  end)

  it("dsIsCharmed reflects the charm aff and its expiry", function()
    reset()
    ataxiaBasher_dsAdd(10, "a mob"); ataxiaBasher_dsSetAff(10, "charm", 1000)
    expect(ataxiaBasher_dsIsCharmed(10, 1004)).toBeTrue()
    expect(ataxiaBasher_dsIsCharmed(10, 1005)).toBeFalse()
  end)

  it("dsRemove drops an entry", function()
    reset()
    ataxiaBasher_dsAdd(10, "a mob")
    ataxiaBasher_dsRemove(10)
    expect(ataxiaBasher_dsGet(10)).toBeNil()
  end)
end)

-- ─── dsExploit stays consistent with the BR_AFFS.exploitedBy spec ─────────────
-- Guards against the two drifting: every BR aff that declares an exploit must make
-- dsExploit return it (headstrike/burst), and inhibit's burst branch is covered.
describe("dsExploit ↔ BR_AFFS.exploitedBy consistency", function()
  it("each exploitable BR aff drives the matching exploit", function()
    for aff, spec in pairs(ataxiaBasher_BR_AFFS) do
      if spec.exploitedBy then
        reset()
        ataxiaBasher_dsAdd(1, "a mob")
        ataxiaBasher_dsSetAff(1, aff, 1000)
        expect(ataxiaBasher_dsExploit(1, 1000)).toBe(spec.exploitedBy)
      end
    end
  end)
end)

