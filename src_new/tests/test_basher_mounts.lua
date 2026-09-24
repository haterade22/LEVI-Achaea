--- test_basher_mounts.lua -- our own mounts are not denizens (v4.7.335)
--
-- User, pasting the listing: "These need to be not on the kill list as they are our mounts."
--
--   Your loyal mounts are:
--   A black Dardanic stallion22638 is at your fingertips.
--   A lean grizzly bear135599 is at your feet.
--
-- The design decision these tests exist to pin: mounts are excluded BY ID, never by name. "a
-- massive dire wolf", "a lean grizzly bear" and "a war elephant" are real denizens in Achaea, so a
-- name keyword would blacklist every wild one -- the target list would quietly lose its best rooms
-- and nothing would say why.

local mock = require("mock_mudlet")

function ataxiaEcho(...) end
ataxia = ataxia or {}
ataxiaBasher = ataxiaBasher or {}
ataxiaTemp = ataxiaTemp or {}

local NOW = 1000
local realEpoch = getEpoch
getEpoch = function() return NOW end

local ok, err = pcall(dofile, "src_new/scripts/levi_ataxia/levi/ataxia/basher/013_Mounts.lua")
if not ok then error("failed to load the mounts module: " .. tostring(err)) end

local function reset()
  NOW = 1000
  ataxiaBasher.mountIds = {}
  ataxiaTemp.mountListUntil, ataxiaTemp.mountListSeen = nil, nil
end

-- The user's listing, verbatim.
local ROWS = {
  { "A black Dardanic stallion", "22638" },
  { "A lean grizzly bear", "135599" },
  { "A war elephant", "193142" },
  { "A massive dire wolf", "397877" },
  { "A withered crypt worm", "651017" },
}

local function listMounts()
  ataxiaBasher_onMountsHeader()
  for _, row in ipairs(ROWS) do ataxiaBasher_onMountRow(row[1], row[2]) end
end

describe("learning the mounts listing", function()
  it("takes every row's id, with the name for the report", function()
    reset()
    listMounts()
    local n = 0
    for _ in pairs(ataxiaBasher.mountIds) do n = n + 1 end
    expect(n).toBe(5)
    expect(ataxiaBasher.mountIds[22638]).toBe("A black Dardanic stallion")
    expect(ataxiaBasher.mountIds[651017]).toBe("A withered crypt worm")
  end)

  it("skips exactly those ids, and nothing else", function()
    reset()
    listMounts()
    expect(ataxiaBasher_isMount(397877)).toBeTrue()
    expect(ataxiaBasher_isMount("397877")).toBeTrue() -- GMCP hands ids over as strings
    expect(ataxiaBasher_isMount(999999)).toBeFalse()
    expect(ataxiaBasher_isMount(nil)).toBeFalse()
  end)

  -- The whole point: a wild denizen of the same species is still a target.
  it("does not touch the name-keyword list -- a wild dire wolf is still fair game", function()
    reset()
    ataxiaBasher.ownDenizens = { "falcon" }
    listMounts()
    expect(#ataxiaBasher.ownDenizens).toBe(1)
    for _, kw in ipairs(ataxiaBasher.ownDenizens) do
      expect(kw ~= "dire wolf" and kw ~= "grizzly bear").toBeTrue()
    end
  end)

  it("ignores a row that no header armed", function()
    reset()
    expect(ataxiaBasher_onMountRow("A wandering merchant", "5150")).toBeFalse()
    expect(ataxiaBasher_isMount(5150)).toBeFalse()
  end)

  it("stops reading rows once the listing's window has passed", function()
    reset()
    ataxiaBasher_onMountsHeader()
    NOW = NOW + 60
    expect(ataxiaBasher_onMountRow("A late row", "777")).toBeFalse()
    expect(ataxiaBasher_isMount(777)).toBeFalse()
  end)

  it("a fresh listing replaces nothing silently -- re-reading is idempotent", function()
    reset()
    listMounts()
    listMounts()
    local n = 0
    for _ in pairs(ataxiaBasher.mountIds) do n = n + 1 end
    expect(n).toBe(5)
  end)

  -- What the user was actually looking at: the name sat in the SAVED target list from before the
  -- v4.7.174 keyword existed, so `bash list` showed it even though nothing would attack it.
  it("takes the mount's name off the saved target lists, exactly", function()
    reset()
    ataxiaBasher.targetList = {
      ["the Tower"] = { "a massive dire wolf", "a mhun knight", "a lean grizzly bear" },
      ["Mhaldor"] = { "a dire wolf pup" }, -- a DIFFERENT denizen: the name is not the same
    }
    listMounts()
    local tower = ataxiaBasher.targetList["the Tower"]
    expect(#tower).toBe(1)
    expect(tower[1]).toBe("a mhun knight")
    expect(#ataxiaBasher.targetList["Mhaldor"]).toBe(1) -- untouched: substring is NOT the rule
    ataxiaBasher.targetList = nil
  end)

  it("the article does not matter, and nothing else is removed", function()
    reset()
    -- "a war elephant trainer" CONTAINS the mount's whole name: a substring rule would take a
    -- real denizen with it, which is the mistake this exactness exists to avoid.
    ataxiaBasher.targetList = { ["A"] = { "A War Elephant", "a war elephant trainer" } }
    ataxiaBasher_onMountsHeader()
    ataxiaBasher_onMountRow("A war elephant", "193142")
    expect(#ataxiaBasher.targetList["A"]).toBe(1)
    expect(ataxiaBasher.targetList["A"][1]).toBe("a war elephant trainer")
    ataxiaBasher.targetList = nil
  end)

  it("clear forgets them", function()
    reset()
    listMounts()
    expect(ataxiaBasher_mountsClear()).toBe(5)
    expect(ataxiaBasher_isMount(22638)).toBeFalse()
  end)
end)

describe("the room read skips a mount", function()
  -- The exclusion lives in `ataxia_RoomContents_Update`; this drives the same decision the way
  -- that loop makes it, so the contract ("mounts never reach denizensHere") is pinned here even
  -- though the loop itself needs the whole GMCP stack to run.
  it("a mount in the room is not a denizen, while the wild one beside it is", function()
    reset()
    listMounts()
    local items = {
      { id = "397877", name = "a massive dire wolf", attrib = "m" }, -- ours
      { id = "400001", name = "a massive dire wolf", attrib = "m" }, -- wild, same species
    }
    local denizens = {}
    for _, v in ipairs(items) do
      if not ataxiaBasher_isMount(v.id) then denizens[tonumber(v.id)] = v.name end
    end
    expect(denizens[397877]).toBeNil()
    expect(denizens[400001]).toBe("a massive dire wolf")
  end)

  it("the room-contents file really consults it", function()
    local f = io.open("src_new/scripts/levi_ataxia/levi/ataxia/update_stuff/003_ataxia_RoomContents_Update.lua")
    local src = f:read("*a"); f:close()
    expect(src:find("ataxiaBasher_isMount(v.id)", 1, true) ~= nil).toBeTrue()
  end)

  -- The v4.7.174 keyword stopped mounts being ATTACKED but never cleaned the saved list, which is
  -- why they were still sitting in `bash list`. The backfill purges once, on load.
  it("the seeding backfill purges the lists it seeded keywords for", function()
    local f = io.open("src_new/scripts/levi_ataxia/levi/ataxia/002_Check_For_Any_Missing_Variables.lua")
    local src = f:read("*a"); f:close()
    local mounts = src:find("withered crypt worm", 1, true)
    local purge = src:find("ataxiaBasher_purgeOwnFromTargets()", 1, true)
    expect(mounts ~= nil and purge ~= nil).toBeTrue()
    expect(purge > mounts).toBeTrue() -- after the keywords are seeded, or it purges nothing
  end)

  it("the triggers hand the listing to the module", function()
    local f = io.open("src_new/triggers/levi_ataxia/for_levi/leviticus/776_Mounts_Header.lua")
    local head = f:read("*a"); f:close()
    expect(head:find("^Your loyal mounts are:$", 1, true) ~= nil).toBeTrue()
    expect(head:find("ataxiaBasher_onMountsHeader()", 1, true) ~= nil).toBeTrue()
    f = io.open("src_new/triggers/levi_ataxia/for_levi/leviticus/777_Mount_Row.lua")
    local row = f:read("*a"); f:close()
    expect(row:find("is at your (?:fingertips|feet|side)", 1, true) ~= nil).toBeTrue()
    expect(row:find("ataxiaBasher_onMountRow(matches[2], matches[3])", 1, true) ~= nil).toBeTrue()
  end)
end)

-- Restore shared state for whoever runs after us (test files share one Lua state).
getEpoch = realEpoch
ataxiaBasher.mountIds = nil
ataxiaTemp.mountListUntil, ataxiaTemp.mountListSeen = nil, nil
