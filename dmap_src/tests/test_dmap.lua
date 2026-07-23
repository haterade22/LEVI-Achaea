-- Self-contained tests for the Dementia Mapper port. Run: lua dmap_src/tests/test_dmap.lua
-- Validates that the scripts load clean under the Mudlet mock and that the ported map graph +
-- dementia-tolerant routing + decoupled explorer behave.

dofile("src_new/tests/mock_mudlet.lua") -- reuse LEVI's Mudlet mock (events, timers, gmcp, geyser)
gmcp = gmcp or {}
main = main or {}

local base = "dmap_src/scripts/dementia_mapper/"
for _, f in ipairs({ "001_Core", "002_Map", "003_Window", "004_Denizens", "005_Explorer", "006_Commands" }) do
  local ok, err = pcall(dofile, base .. f .. ".lua")
  if not ok then print("LOAD FAIL " .. f .. ": " .. tostring(err)); os.exit(1) end
end
print("all dmap scripts loaded clean")

local pass, fail = 0, 0
local function ok(cond, msg) if cond then pass = pass + 1 else fail = fail + 1; print("  FAIL: " .. msg) end end

local MAP = dmap.map

-- 1. Graph build + exit normalisation
dmap.run.active = true
MAP.reset()
MAP.onRoom(1, "A", { north = 2, east = 0 }, nil)
ok(MAP.rooms[1] ~= nil, "room 1 recorded")
ok(MAP.rooms[1].exits.north == 2, "north exit normalised + dest coerced to number")
ok(MAP.current == 1, "current == 1")

-- 2. relayout places connected rooms on the grid
MAP.reset()
MAP.onRoom(1, "A", { east = 2 }, nil)
MAP.onRoom(2, "B", { west = 1 }, "e")
ok(MAP.rooms[1].x ~= nil and MAP.rooms[2].x ~= nil, "both rooms placed by relayout")
ok(MAP.rooms[2].x == MAP.rooms[1].x + 1, "B is east of A")

-- 3. walked-edge path
MAP.reset()
MAP.onRoom(1, "A", { east = 2 }, nil)
MAP.onRoom(2, "B", { west = 1, east = 3 }, "e")
MAP.onRoom(3, "C", { west = 2 }, "e")
local p = MAP.path(3, 1)
ok(p and #p == 2 and p[1] == "w" and p[2] == "w", "walked path 3->1 = w,w")

-- 4. dementia-tolerant pathKnown: reach a room only in the REPORTED-exit graph (walked edge dropped)
MAP.reset()
MAP.onRoom(1, "A", { east = 2 }, nil)
MAP.onRoom(2, "B", { west = 1, east = 3 }, "e")
-- arrive in 3 with NO determinable move-dir (faked exits): walked edge 2->3 is dropped,
-- but 2 still REPORTS east=3, so pathKnown must still route 1->...->3.
MAP.rooms[3] = { num = 3, name = "C", exits = { west = 2 }, edges = {}, visited = true }
MAP.current = 3
local pk = MAP.pathKnown(1, 3)
ok(pk ~= nil, "pathKnown routes over reported-exit graph when walked edge is missing (dementia)")

-- 5. next sweep step: an unwalked exit of the current room
MAP.reset()
MAP.onRoom(1, "A", { north = 0, east = 0 }, nil)
local step = dmap._nextExploreStep()
ok(step == "n" or step == "e", "_nextExploreStep returns an unexplored exit (" .. tostring(step) .. ")")

-- 6. denizen tracking via gmcp.Char.Items + attrib flag-set (m, not d, not x)
gmcp.Char = { Items = { List = { location = "room", items = {
  { id = 10, name = "a wolf", attrib = "m" },       -- live monster -> denizen
  { id = 11, name = "a corpse", attrib = "md" },    -- dead -> NOT a denizen
  { id = 12, name = "a guard", attrib = "mx" },     -- loyal/protected -> NOT a denizen
  { id = 13, name = "an apple", attrib = "t" },     -- item -> NOT a denizen
} } } }
dmap._denizensList()
ok(dmap.denizensHere[10] == "a wolf", "live monster tracked")
ok(dmap.denizensHere[11] == nil and dmap.denizensHere[12] == nil and dmap.denizensHere[13] == nil,
  "corpse / loyal / item excluded by attrib flag-set")
ok(dmap.roomHasDenizens() == true, "roomHasDenizens true with a live monster")
dmap.denizensHere = {}
ok(dmap.roomHasDenizens() == false, "roomHasDenizens false when empty")

-- 7. Room.WrongDir condemns + prunes the exit (server-authoritative wall)
MAP.reset()
MAP.onRoom(1, "A", { north = 2, east = 0 }, nil)
dmap.explore.on = true; dmap.explore.moving = true; dmap.explore.fromRoom = 1; dmap.explore.failed = {}
dmap._onWrongDir("n")
ok(dmap.explore.failed[1] and dmap.explore.failed[1].north == true, "WrongDir condemned the exit")
ok(MAP.rooms[1].exits.north == nil, "WrongDir pruned the faked exit from the graph")
ok(dmap.explore.moving == false, "WrongDir ended the move")
dmap.explore.on = false

-- 8. explorer is gated on being in a ripple (no basher dependency)
dmap.run.active = false
dmap.explore.on = false
dmap.exploreStart()
ok(dmap.explore.on == false, "exploreStart refuses outside a ripple")
dmap.run.active = true
dmap.exploreStart()
ok(dmap.explore.on == true, "exploreStart runs inside a ripple (basher-free)")
dmap.exploreStop("test")
ok(dmap.explore.on == false, "exploreStop stops the sweep")

print(string.format("\n=== dmap: %d passed, %d failed ===", pass, fail))
os.exit(fail == 0 and 0 or 1)
