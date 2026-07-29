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
