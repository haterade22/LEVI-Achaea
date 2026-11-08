--- test_room_contents_flags.lua -- the two room flags in update_stuff/003 (2026-11-08)
--
-- ataxia.lightwall (the Serpent venom order, hasLightwall; [light] on the room bar) and
-- ataxiaTemp.monolith ([mono]) say what stands in the room we are in. The handler cleared both at
-- its top on any List, Add or Remove while the last List was not the inventory's, so one denizen
-- walking in cleared them with the wall still up. And an inventory List fell through to the Add
-- branch, which re-read the last Add received.
--
-- The REAL handler runs on GMCP's shapes. Every global it creates or changes is restored at the end
-- (one shared Lua state for all test files).

local mock = require("mock_mudlet")
local before = {}
for k, v in pairs(_G) do before[k] = v end
local savedContains = table.contains

local ROOM = "src_new/scripts/levi_ataxia/levi/ataxia/update_stuff/003_ataxia_RoomContents_Update.lua"
local LEVI = "src_new/triggers/levi_ataxia/for_levi/leviticus/"

local function world()
  mock.reset()
  table.contains = table.contains or function(t, v)
    for _, x in pairs(t) do if x == v then return true end end
    return false
  end
  ataxia = { denizensHere = {} }
  ataxiaTemp = {}
  ataxiaBasher = { enabled = false }
  ataxiaBasher_invalidateStormhammer = function() end
  ataxiaBasher_isMount, ataxiaBasher_profanedForget = nil, nil
  item_Pickup, waterGuards, atempDenizens = {}, {}, {}
  gmcp = { Char = { Items = {} } }
  dofile(ROOM)
end

local function list(location, names)
  local items = {}
  for i, name in ipairs(names) do items[i] = { id = tostring(100 + i), name = name, attrib = "m" } end
  gmcp.Char.Items.List = { location = location, items = items }
  ataxia_RoomContents_Update("gmcp.Char.Items.List")
end
local function roomList(...) list("room", { ... }) end
local function invList(...) list("inv", { ... }) end

local function add(name, attrib)
  gmcp.Char.Items.Add = { location = "room", item = { id = "900", name = name, attrib = attrib } }
  ataxia_RoomContents_Update("gmcp.Char.Items.Add")
end
local function remove(name, location)
  gmcp.Char.Items.Remove = { location = location or "room", item = { id = "900", name = name } }
  ataxia_RoomContents_Update("gmcp.Char.Items.Remove")
end

local ok, err = pcall(function()

describe("ataxia.lightwall says whether a lightwall stands in our room", function()
  it("a room list with a wall sets it, and one without clears it", function()
    world()
    roomList("a lightwall", "a rat")
    expect(ataxia.lightwall).toBeTrue()
    roomList("a rat")
    expect(ataxia.lightwall).toBeFalse()
  end)

  it("an Add or a Remove of anything else leaves it up", function()
    world()
    roomList("a lightwall")
    add("a rat", "m")
    expect(ataxia.lightwall).toBeTrue()
    remove("a rat")
    expect(ataxia.lightwall).toBeTrue()
  end)

  it("an Add of the wall sets it, and a room Remove of the wall clears it", function()
    world()
    roomList("a rat")
    add("a lightwall")
    expect(ataxia.lightwall).toBeTrue()
    remove("a lightwall")
    expect(ataxia.lightwall).toBeFalse()
  end)

  it("an inventory list leaves it alone", function()
    world()
    roomList("a lightwall")
    invList("a dirk")
    expect(ataxia.lightwall).toBeTrue()
  end)

  it("an inventory list does not replay the last Add into this room", function()
    world()
    roomList("a rat")
    add("a lightwall")
    add("a black bear", "m")
    add("a lightwall")
    roomList()                 -- we walked out
    expect(ataxia.lightwall).toBeFalse()
    invList("a dirk")
    expect(ataxia.lightwall).toBeFalse()
    expect(next(ataxia.denizensHere)).toBeNil()
  end)

  it("an inventory list before any Add does not throw", function()
    world()
    invList("a dirk")
    expect(ataxia.lightwall).toBeNil()
  end)

  -- Trigger 648 ("Darkshade Failsafe") wrote ataxia.lightwall = true on this line and did nothing
  -- else: "The sun has rendered you too weak to move a muscle."
  -- (kb/raw/logs/2026-11-01_nikita_depthswalker-vs-serpent_win_X8pRorzR.txt:1520, :6555). Both rows
  -- are in an indoor room with a wall (:1034-1035, :5303-5304), so a wall can give the line. But with
  -- a wall up the room list and the room line have already set the flag, so the write added nothing
  -- there. Its only other effect would be a false wall on a target under the real sun, and now that
  -- nothing clears the flag early, that would hold the venom order until we left the room.
  it("the sun line no longer has a trigger that sets it", function()
    local f = io.open(LEVI .. "648_Darkshade_Failsafe.lua", "r")
    if f then f:close() end
    expect(f).toBeNil()
  end)
end)

describe("ataxiaTemp.monolith says whether a monolith sigil stands in our room", function()
  it("a room list sets it, and one without clears it", function()
    world()
    roomList("a monolith sigil")
    expect(ataxiaTemp.monolith).toBeTrue()
    roomList("a rat")
    expect(ataxiaTemp.monolith).toBeFalse()
  end)

  it("an Add or a Remove of anything else leaves it up", function()
    world()
    roomList("a monolith sigil")
    add("a rat", "m")
    remove("a rat")
    expect(ataxiaTemp.monolith).toBeTrue()
  end)

  it("an Add sets it, and a room Remove clears it", function()
    world()
    roomList("a rat")
    add("a monolith sigil")
    expect(ataxiaTemp.monolith).toBeTrue()
    remove("a monolith sigil")
    expect(ataxiaTemp.monolith).toBeFalse()
  end)

  it("a carried sigil leaving the inventory does not clear the room's", function()
    world()
    roomList("a monolith sigil")
    remove("a monolith sigil", "inv")
    expect(ataxiaTemp.monolith).toBeTrue()
  end)
end)

end)

mock.reset()
table.contains = savedContains
-- Restore the shared Lua state: drop every global the loaded file created and put back every one
-- it replaced.
for k in pairs(_G) do
  if before[k] == nil then _G[k] = nil end
end
for k, v in pairs(before) do _G[k] = v end
if not ok then error(err) end
