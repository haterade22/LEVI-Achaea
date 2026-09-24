--[[mudlet
type: script
name: Mounts
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Basher
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

--[[
    ============================================================================
    OUR OWN MOUNTS ARE NOT TARGETS  (v4.7.335, user-directed)
    ============================================================================

    User, pasting the listing: "These need to be not on the kill list as they are our mounts."

        Your loyal mounts are:
        A black Dardanic stallion22638 is at your fingertips.
        A lean grizzly bear135599 is at your feet.
        A war elephant193142 is at your fingertips.
        A massive dire wolf397877 is at your fingertips.
        A withered crypt worm651017 is at your fingertips.

    A mount in the room is an ordinary GMCP item with the monster attribute, so the basher reads it
    as a denizen, learns its name into the area's target list, and swings at it.

    BY ID, NEVER BY NAME. This is the whole design decision. `ataxiaBasher.ownDenizens` already
    excludes pets by keyword, and a keyword is exactly wrong here: "a massive dire wolf", "a lean
    grizzly bear" and "a war elephant" are REAL denizens in the game. Adding those words would
    blacklist every wild one in Achaea -- the target list would quietly lose its best rooms, and
    nothing would say why. The id in the listing ("stallion22638") is the item id GMCP reports, it
    belongs to that one creature, and it does not change when the mount is stabled or re-summoned.

    So: learn the ids here, and drop exactly those ids where the room contents are read
    (`ataxia_RoomContents_Update`). A wild dire wolf in the same room is still a target; ours is
    not in `denizensHere` at all, which is the one place everything downstream agrees on.

    LEARNED PASSIVELY. The listing is parsed whenever the game prints it -- no command is sent,
    because the command that produces it was never captured in a log and this tree does not guess
    game syntax (the horn's rule). Type your mounts command once a session, or whenever you tame
    one, and the ids stick: `ataxiaBasher` is saved to disk.
]]--

ataxiaBasher = ataxiaBasher or {}
ataxiaTemp = ataxiaTemp or {}

-- How long the header keeps the row parser open. The rows arrive in one burst; anything later is
-- some other screen that happens to look like a mount row.
local MOUNT_LIST_WINDOW = 3

-- "Your loyal mounts are:" -- arm the row parser and start a fresh reading, so a mount sold or
-- released disappears from the list rather than lingering forever.
function ataxiaBasher_onMountsHeader()
  ataxiaTemp.mountListUntil = ((getEpoch and getEpoch()) or os.time()) + MOUNT_LIST_WINDOW
  ataxiaTemp.mountListSeen = {}
  return true
end

-- One row: `name` is the text before the id ("A black Dardanic stallion"), `id` the digits.
-- Ignored unless a header armed us, so a lookalike line elsewhere cannot poison the list.
function ataxiaBasher_onMountRow(name, id)
  local until_ = tonumber(ataxiaTemp.mountListUntil) or 0
  if ((getEpoch and getEpoch()) or os.time()) > until_ then return false end
  id = tonumber(id)
  if not id then return false end
  name = tostring(name or ""):gsub("^%s+", ""):gsub("%s+$", "")
  ataxiaBasher.mountIds = ataxiaBasher.mountIds or {}
  ataxiaBasher.mountIds[id] = (name ~= "") and name or true
  ataxiaTemp.mountListSeen = ataxiaTemp.mountListSeen or {}
  ataxiaTemp.mountListSeen[id] = true
  -- ...and take the name off the saved target lists (v4.7.335). The id keeps us from ATTACKING
  -- one, but `bash list` is by name, so a mount learned before this still SAT on the kill list --
  -- which is what the user was looking at. Exact name only, never a substring: "dire wolf" would
  -- take half the bestiary with it. If a wild one of the same species turns up later, auto-learn
  -- puts the name back from THAT denizen, which is the right reason to have it.
  ataxiaBasher_purgeMountName(name)
  return true
end

-- Remove one exact mount name from every area's target list. Returns how many entries went.
function ataxiaBasher_purgeMountName(name)
  local want = tostring(name or ""):lower():gsub("^%s*an?%s+", ""):gsub("^%s*the%s+", "")
  want = want:gsub("^%s+", ""):gsub("%s+$", "")
  if want == "" or type(ataxiaBasher.targetList) ~= "table" then return 0 end
  local removed = 0
  for _, list in pairs(ataxiaBasher.targetList) do
    if type(list) == "table" then
      for i = #list, 1, -1 do
        local entry = tostring(list[i] or ""):lower():gsub("^%s*an?%s+", ""):gsub("^%s*the%s+", "")
        if entry == want then
          table.remove(list, i)
          removed = removed + 1
        end
      end
    end
  end
  if removed > 0 then
    ataxiaEcho("Mount <white>" .. tostring(name) .. "<reset> removed from " .. removed
      .. " target list(s) -- it is skipped by ID from now on.")
  end
  return removed
end

-- Is this room item one of our mounts? Called from the room-contents read, by id.
function ataxiaBasher_isMount(id)
  id = tonumber(id)
  if not id then return false end
  return (ataxiaBasher.mountIds and ataxiaBasher.mountIds[id]) and true or false
end

-- `bash mounts` -- what we know, and how it was learned.
function ataxiaBasher_mountsReport()
  local ids = {}
  for id in pairs(ataxiaBasher.mountIds or {}) do ids[#ids + 1] = id end
  table.sort(ids)
  if #ids == 0 then
    return ataxiaEcho("No mounts learned yet -- list your mounts in game once and they will be "
      .. "skipped from then on (they are excluded by ID, so wild denizens of the same species "
      .. "are still targets).")
  end
  ataxiaEcho("Mounts skipped by the basher (" .. #ids .. "):")
  for _, id in ipairs(ids) do
    local name = ataxiaBasher.mountIds[id]
    cecho("\n  <cyan>" .. id .. "<reset>  " .. (type(name) == "string" and name or "(name unknown)"))
  end
end

-- `bash mounts clear` -- forget them (a sold mount, or a bad reading).
function ataxiaBasher_mountsClear()
  local n = 0
  for _ in pairs(ataxiaBasher.mountIds or {}) do n = n + 1 end
  ataxiaBasher.mountIds = {}
  ataxiaEcho("Forgot <cyan>" .. n .. "<reset> mount(s). List them again to re-learn.")
  return n
end
