--[[mudlet
type: script
name: Serpent Auto Evade
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- Leviticus
- Serpent
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

--[[
    SERPENT AUTO-EVADE (2026-11-11, the user's rules)

    "We should also auto evade in a direction when being targeted by 2 or more people and in
    serpent." The user set the rules:
      - Targeted: 2 different players hit us within 3 s ("2 attackers within 3 seconds should be
        reasonable").
      - Direction: "One that we came in through or random, point is to get out."
      - "it needs balance and not to be paralyzed or web/entangled".

    WHAT COUNTS AS A HIT. classDetect.noteHit (class_detect/001), which the class-grab triggers call
    for an attack line that names us ("you"/"your"). It is the same record the anti-class defences
    read. So an attack that no class-grab trigger knows does not count here. noteHit calls
    serpent.evadeOnHit(name).

    ONLY THIS ROOM. The window is cleared when the room changes, so hits from the room we left do
    not start a second evade on arrival.

    DIRECTION. The exit of this room that leads to the room we came from (gmcp.Room.Info exits).
    That exit is not used when we got here by an auto-evade, because it leads back into the fight;
    then, or when no exit leads back, a random exit. No exit: no evade.

    GATES. Serpent, `serpent.config.autoEvade` not false (`srevade on|off`), the basher off, balance
    up (EVADE costs 2.00 s of balance, kb/classes/serpent.md), and none of paralysis, webbed,
    entangled. Prone: a stand goes first (EVADE refuses while prone). One evade per EVADE_GAP; a
    room change clears that early.
]]--

serpent = serpent or {}
serpent.config = serpent.config or {}
if serpent.config.autoEvade == nil then serpent.config.autoEvade = true end

serpent.evade = serpent.evade or {}
local E = serpent.evade
E.hits = E.hits or {}        -- lower-case name -> getEpoch() of the newest hit in this room
E.WINDOW = 3                 -- seconds: the user's "within 3 seconds"
E.NEEDED = 2                 -- different attackers: the user's "2 attackers"
E.GAP = 3                    -- seconds between two evades from one room
E.BLOCKERS = { "paralysis", "webbed", "entangled" }

local function now() return getEpoch() end

local function has(aff)
  return ataxia and ataxia.afflictions and ataxia.afflictions[aff] and true or false
end

local function roomInfo()
  return gmcp and gmcp.Room and gmcp.Room.Info
end

-- The exit to take, and why ("the way we came" or "random"), or nil.
function E.pickExit()
  local info = roomInfo()
  if not info or type(info.exits) ~= "table" then return nil end
  local dirs = {}
  for dir, num in pairs(info.exits) do
    dirs[#dirs + 1] = dir
    if E.cameFrom and not E.arrivedByEvade and tostring(num) == tostring(E.cameFrom) then
      return dir, "the way we came"
    end
  end
  if #dirs == 0 then return nil end
  table.sort(dirs)   -- pairs() has no order; sorted first, so only math.random picks
  return dirs[math.random(#dirs)], "random"
end

-- Different attackers whose newest hit is inside the window, in name order.
function E.recentAttackers()
  local t, list = now(), {}
  for name, at in pairs(E.hits) do
    if t - at <= E.WINDOW then list[#list + 1] = name end
  end
  table.sort(list)
  return list
end

-- Nil when we may evade now, else the reason we may not.
function E.blocked()
  if not (gmcp and gmcp.Char and gmcp.Char.Status and gmcp.Char.Status.class == "Serpent") then
    return "not a Serpent"
  end
  if serpent.config.autoEvade == false then return "off" end
  if ataxiaBasher and ataxiaBasher.enabled then return "basher on" end
  local v = gmcp.Char.Vitals
  if not v or v.bal ~= "1" then return "no balance" end
  for _, aff in ipairs(E.BLOCKERS) do
    if has(aff) then return aff end
  end
  if E.sentAt and now() - E.sentAt < E.GAP then return "just evaded" end
  return nil
end

function E.check()
  local who = E.recentAttackers()
  if #who < E.NEEDED then return false end
  if E.blocked() then return false end
  local dir, why = E.pickExit()
  if not dir then return false end
  E.sentAt = now()
  if has("prone") then send("stand", false) end
  send("evade " .. dir, false)
  cecho("\n<red>AUTO-EVADE: <white>" .. table.concat(who, ", ") .. " hit us within "
    .. E.WINDOW .. " s -- evade " .. dir .. " <dim_grey>(" .. why .. ")")
  return true
end

-- From classDetect.noteHit, for each attack line that names us.
function serpent.evadeOnHit(name)
  if type(name) ~= "string" or name == "" then return end
  E.hits[name:lower()] = now()
  E.check()
end

-- Balance back: two hits that came while we were off balance start the evade now.
function E.onVitals()
  if next(E.hits) then E.check() end
end

function E.onRoom()
  local info = roomInfo()
  if not info or info.num == nil then return end
  if E.roomNum ~= nil and tostring(info.num) ~= tostring(E.roomNum) then
    E.cameFrom = E.roomNum
    -- An evade sent in the last 3 s moved us. An older one failed, and this is a walk.
    E.arrivedByEvade = (E.sentAt ~= nil and now() - E.sentAt < 3)
    E.hits = {}
    E.sentAt = nil
  end
  E.roomNum = info.num
end

if E.roomHandler then pcall(killAnonymousEventHandler, E.roomHandler) end
E.roomHandler = registerAnonymousEventHandler("gmcp.Room.Info", function() E.onRoom() end)
if E.vitalsHandler then pcall(killAnonymousEventHandler, E.vitalsHandler) end
E.vitalsHandler = registerAnonymousEventHandler("gmcp.Char.Vitals", function() E.onVitals() end)
