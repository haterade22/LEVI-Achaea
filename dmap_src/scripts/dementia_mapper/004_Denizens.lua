--[[mudlet
type: script
name: dmap Denizens
hierarchy:
- Dementia_Mapper
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

--[[
    ============================================================================
    dmap.denizensHere - own room-denizen tracking from gmcp.Char.Items
    ============================================================================
    Standalone replacement for LEVI's ataxia.denizensHere, so the explorer knows
    "is this room clear?" with no combat system. { [id] = name } of the LIVE,
    KILLABLE monsters in the current room. Uses the Char.Items `attrib` flag-set
    correctly: a denizen has 'm' (monster) and NOT 'd' (dead/corpse) or 'x'
    (should-not-be-targeted / loyal to city/player). Raises "dmap denizens
    updated" on any change (the explorer ticks off it). Negotiates Char.Items.
    ============================================================================
]]--

dmap = dmap or {}
dmap.denizensHere = dmap.denizensHere or {}
dmap.config = dmap.config or {}
dmap.config.ownDenizens = dmap.config.ownDenizens or {} -- [name]=true: your pets/summons, never targets

local function isDenizen(v)
  return type(v) == "table" and type(v.attrib) == "string"
    and v.attrib:find("m") and not v.attrib:find("d") and not v.attrib:find("x")
end

local function fire() raiseEvent("dmap denizens updated") end

function dmap._denizensList()
  local L = gmcp and gmcp.Char and gmcp.Char.Items and gmcp.Char.Items.List
  if not (L and type(L.items) == "table") then return end
  if L.location ~= "room" then return end -- ignore inventory / containers
  dmap.denizensHere = {}
  for _, v in pairs(L.items) do
    if isDenizen(v) then dmap.denizensHere[tonumber(v.id)] = v.name end
  end
  fire()
end

function dmap._denizensAdd()
  local A = gmcp and gmcp.Char and gmcp.Char.Items and gmcp.Char.Items.Add
  if not (A and A.location == "room" and A.item) then return end
  if isDenizen(A.item) then
    dmap.denizensHere[tonumber(A.item.id)] = A.item.name
    fire()
  end
end

function dmap._denizensRemove()
  local R = gmcp and gmcp.Char and gmcp.Char.Items and gmcp.Char.Items.Remove
  if not (R and R.item and R.item.id) then return end
  local id = tonumber(R.item.id)
  if dmap.denizensHere[id] then dmap.denizensHere[id] = nil; fire() end
end

-- Own pet/summon check (config allowlist by name). Default: everything is a target.
function dmap.isOwnDenizen(name)
  return dmap.config.ownDenizens[name] == true
end

-- Ground truth for the explorer: any killable denizen left in the room?
function dmap.roomHasDenizens()
  for _, name in pairs(dmap.denizensHere or {}) do
    if not dmap.isOwnDenizen(name) then return true end
  end
  return false
end

function dmap.denizenCount()
  local n = 0
  for _, name in pairs(dmap.denizensHere or {}) do
    if not dmap.isOwnDenizen(name) then n = n + 1 end
  end
  return n
end

-- First killable denizen (id, name) -- for the combat hook.
function dmap.firstDenizen()
  for id, name in pairs(dmap.denizensHere or {}) do
    if not dmap.isOwnDenizen(name) then return id, name end
  end
end

dmap._handlers = dmap._handlers or {}
local function reg(ev, fn)
  if dmap._handlers[ev] then pcall(killAnonymousEventHandler, dmap._handlers[ev]) end
  dmap._handlers[ev] = registerAnonymousEventHandler(ev, fn)
end
reg("gmcp.Char.Items.List", "dmap._denizensList")
reg("gmcp.Char.Items.Add", "dmap._denizensAdd")
reg("gmcp.Char.Items.Remove", "dmap._denizensRemove")

-- Negotiate the GMCP modules we consume (Char.Items = room denizens; Room = the map).
-- On connect + now (in case the package was installed mid-session, already connected).
function dmap._negotiate()
  if not sendGMCP then return end
  pcall(sendGMCP, 'Core.Supports.Add ["Char.Items 1"]')
  pcall(sendGMCP, 'Core.Supports.Add ["Room 1"]')
end
reg("sysConnectionEvent", "dmap._negotiate")
pcall(dmap._negotiate)
