--- test_basher_owndenizens.lua — Unit tests for "our denizens" auto-add/target exclusion
-- Loads the real basher functions file and exercises ataxiaBasher_isOwnDenizen() and
-- ataxiaBasher_purgeOwnFromTargets(): pets/allies (falcons, Baalzadeen) must never be
-- learned or targeted, and existing matches are purged from target lists on add.

local mock = require("mock_mudlet")

-- Stub project globals the basher functions file expects
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
ataxia.settings = ataxia.settings or { separator = "::" }
ataxiaBasher = ataxiaBasher or {}
ataxiaTemp = ataxiaTemp or {}
gmcp = { Room = { Info = { area = "" } } }

local basher_file = "src_new/scripts/levi_ataxia/levi/ataxia/basher/001_Bashing_Functions.lua"
local ok, err = pcall(dofile, basher_file)
if not ok then error("Failed to load basher functions file: " .. tostring(err)) end

-- ----------------------------------------------------------------------------
describe("ataxiaBasher_isOwnDenizen — keyword substring match", function()

  it("matches 'a razor-beaked falcon' via the 'falcon' keyword", function()
    ataxiaBasher.ownDenizens = { "falcon", "baalzadeen" }
    expect(ataxiaBasher_isOwnDenizen("a razor-beaked falcon")).toBeTrue()
  end)

  it("matches 'Baalzadeen' case-insensitively", function()
    ataxiaBasher.ownDenizens = { "falcon", "baalzadeen" }
    expect(ataxiaBasher_isOwnDenizen("Baalzadeen")).toBeTrue()
  end)

  it("does not match an ordinary bashing mob", function()
    ataxiaBasher.ownDenizens = { "falcon", "baalzadeen" }
    expect(ataxiaBasher_isOwnDenizen("a mhun knight")).toBeFalse()
  end)

  -- v4.7.148: the Infernal pet was NOT on the seeded list, so the basher targeted it
  -- (seen live at 4% on the mob bar) -- and a mauled hyena turns on its owner.
  it("matches 'a daemonic hyena' via the 'hyena' keyword", function()
    ataxiaBasher.ownDenizens = { "falcon", "baalzadeen", "ashbeast", "hyena" }
    expect(ataxiaBasher_isOwnDenizen("a daemonic hyena")).toBeTrue()
    expect(ataxiaBasher_isOwnDenizen("A daemonic hyena")).toBeTrue()
  end)

  it("returns false when the list is empty", function()
    ataxiaBasher.ownDenizens = {}
    expect(ataxiaBasher_isOwnDenizen("a razor-beaked falcon")).toBeFalse()
  end)

  it("returns false for non-string input", function()
    ataxiaBasher.ownDenizens = { "falcon" }
    expect(ataxiaBasher_isOwnDenizen(nil)).toBeFalse()
  end)

end)

describe("ataxiaBasher_purgeOwnFromTargets — cleanup of already-learned pets", function()

  it("removes matching names from every area but keeps real mobs and the keyword", function()
    ataxiaBasher.ownDenizens = { "falcon", "baalzadeen" }
    ataxiaBasher.targetList = {
      ["Test Area"] = { "a mhun knight", "a razor-beaked falcon", "an elite mhun keeper", keyword = "mhun" },
      ["Other Area"] = { "Baalzadeen", "a goblin" },
    }
    local removed = ataxiaBasher_purgeOwnFromTargets()
    expect(removed).toBe(2)
    expect(table.contains(ataxiaBasher.targetList["Test Area"], "a razor-beaked falcon")).toBeFalse()
    expect(table.contains(ataxiaBasher.targetList["Test Area"], "a mhun knight")).toBeTrue()
    expect(ataxiaBasher.targetList["Test Area"].keyword).toBe("mhun")
    expect(table.contains(ataxiaBasher.targetList["Other Area"], "Baalzadeen")).toBeFalse()
    expect(table.contains(ataxiaBasher.targetList["Other Area"], "a goblin")).toBeTrue()
  end)

  it("returns 0 when nothing matches", function()
    ataxiaBasher.ownDenizens = { "falcon" }
    ataxiaBasher.targetList = { ["A"] = { "a goblin", "a rat" } }
    expect(ataxiaBasher_purgeOwnFromTargets()).toBe(0)
  end)

end)

describe("ataxiaBasher_addOwnDenizen — add + auto-purge", function()

  it("adds a new keyword and purges existing matches", function()
    ataxiaBasher.ownDenizens = {}
    ataxiaBasher.targetList = { ["A"] = { "a snow leopard", "a mhun knight" } }
    ataxiaBasher_addOwnDenizen("leopard")
    expect(table.contains(ataxiaBasher.ownDenizens, "leopard")).toBeTrue()
    expect(table.contains(ataxiaBasher.targetList["A"], "a snow leopard")).toBeFalse()
    expect(table.contains(ataxiaBasher.targetList["A"], "a mhun knight")).toBeTrue()
  end)

  it("does not add a duplicate keyword", function()
    ataxiaBasher.ownDenizens = { "falcon" }
    ataxiaBasher.targetList = {}
    ataxiaBasher_addOwnDenizen("falcon")
    local count = 0
    for _, v in ipairs(ataxiaBasher.ownDenizens) do if v == "falcon" then count = count + 1 end end
    expect(count).toBe(1)
  end)

end)

-- =====================================================================================
-- THE SEEDED DEFAULT WAS NEVER BACKFILLED (v4.7.348)
--
-- User: "the denizens in the room should not count our Baalzadeen as Apostate! It is thinking
-- it is a swarm."
--
-- `baalzadeen` and `falcon` have been in the DEFAULT list for as long as it has existed -- and
-- the default only runs when `ownDenizens` is nil, i.e. on a fresh install. Every save older
-- than the seed kept a list without them and nothing ever repaired it, because the backfill loop
-- beside it only ever carried `ashbeast` and `hyena`.
--
-- The cost is not "our demon might get hit". `isOwnDenizen` is what `M._denizenCount` and
-- `M._roomHasDenizens` filter through, so a missing keyword INFLATES the swarm count -- and the
-- threshold it inflates past is what fires the pull, the funnel and the icewall. One pet beside
-- two denizens reads as three, which is the default threshold exactly.
describe("the pet backfill repairs a legacy save", function()
  -- The shipped list, read from the file rather than restated here: a test that keeps its own
  -- copy of the list cannot notice the copy in the source going stale.
  local function shippedPets()
    local f = io.open("src_new/scripts/levi_ataxia/levi/ataxia/002_Check_For_Any_Missing_Variables.lua")
    local src = f:read("*a"); f:close()
    local list = src:match('for _, pet in ipairs%(%{(.-)%}%)')
    local pets = {}
    for w in (list or ""):gmatch('"([%w_ ]+)"') do pets[#pets + 1] = w end
    return pets
  end

  -- What the loop does, run against a save from before the seed existed.
  local function backfill(saved)
    for _, pet in ipairs(shippedPets()) do
      if not table.contains(saved, pet) then table.insert(saved, pet) end
    end
    return saved
  end

  it("ships baalzadeen in the backfill, not only in the seed", function()
    expect(table.contains(shippedPets(), "baalzadeen")).toBeTrue()
    expect(table.contains(shippedPets(), "falcon")).toBeTrue()
  end)

  it("adds it to a save that predates the seed", function()
    local saved = backfill({ "ashbeast", "hyena" })
    expect(table.contains(saved, "baalzadeen")).toBeTrue()
    ataxiaBasher.ownDenizens = saved
    expect(ataxiaBasher_isOwnDenizen("a towering baalzadeen")).toBeTrue()
  end)

  it("is idempotent -- a repaired save does not grow every load", function()
    local saved = backfill(backfill({ "ashbeast", "hyena" }))
    local n = 0
    for _, p in ipairs(saved) do if p == "baalzadeen" then n = n + 1 end end
    expect(n).toBe(1)
  end)

  it("keeps whatever the user added themselves", function()
    local saved = backfill({ "my war hound" })
    expect(table.contains(saved, "my war hound")).toBeTrue()
    expect(table.contains(saved, "baalzadeen")).toBeTrue()
  end)
end)

-- THE REAL LOOP, RUN (v4.7.351, deep review). The tests above read the shipped LIST and replay
-- the loop's logic by hand -- and the deep review's mutation run gated the real loop off entirely
-- (`if false and ...`) and the whole suite still passed. The fix this file exists to pin had no
-- coverage of its own execution. This runs the real ataxiaCheckForMissing() against a save from
-- before the seed, in FRESH tables: it writes dozens of defaults, and test files share one state.
describe("the real backfill repairs a legacy save", function()
  it("adds baalzadeen to a save that only had ashbeast and hyena", function()
    local savedA, savedB, savedT, savedEcho = ataxia, ataxiaBasher, ataxiaTemp, ataxiaEcho
    ataxia = { settings = {}, vitals = {} }
    ataxiaBasher = { ownDenizens = { "ashbeast", "hyena" } }
    ataxiaTemp = {}
    ataxiaEcho = function() end
    local ok, err = pcall(function()
      dofile("src_new/scripts/levi_ataxia/levi/ataxia/002_Check_For_Any_Missing_Variables.lua")
      ataxiaCheckForMissing()
    end)
    local owned = ataxiaBasher.ownDenizens
    ataxia, ataxiaBasher, ataxiaTemp, ataxiaEcho = savedA, savedB, savedT, savedEcho
    if not ok then error(err, 0) end
    expect(table.contains(owned, "baalzadeen")).toBeTrue()
    expect(table.contains(owned, "falcon")).toBeTrue()
    local n = 0
    for _, p in ipairs(owned) do if p == "hyena" then n = n + 1 end end
    expect(n).toBe(1) -- and it did not duplicate what was already there
  end)
end)
