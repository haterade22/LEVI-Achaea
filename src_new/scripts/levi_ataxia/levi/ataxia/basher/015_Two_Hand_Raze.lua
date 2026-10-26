--[[mudlet
type: script
name: Two Hand Raze
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
    TWO HANDED SHIELD BREAK: CARVE WITH A BASTARD SWORD, SPLINTER WITH A WARHAMMER (v4.7.452)

    User: "When in 2 handed, if I am wielding a bastard sword it should carve, warhammer splinter."
    The game's refusal, pasted with it:

        You must be wielding a warhammer to splinter an opponent's defences.

    Both are Weaponmastery, so all four knights have both (kb/classes/<knight>.md: CARVE needs a
    Bastard Sword, SPLINTER a Warhammer). Until now the Infernal basher always sent SPLINTER and the
    Paladin, Runewarden and Unnamable bashers always sent CARVE, whatever was in hand.

    THE WEAPON IS READ FROM GMCP. Inventory items carry `attrib`; an `l` or `L` in it means
    wielded. `Char.Items.List` (location "inv") replaces the picture, `Char.Items.Update`, `Add` and
    `Remove` change one item. A wielded name with "warhammer" means SPLINTER; one with "bastard"
    means CARVE. With no inventory seen yet, one `Char.Items.Inv` request is sent.

    THE REFUSAL TEACHES TOO (trigger 790). If SPLINTER is refused, we hold no warhammer: the belief
    becomes "bastard sword" and the round is re-sent, so the stale raze is replaced by CARVE at once.
    The carve refusal line is not captured; GMCP covers that direction.

    Unknown weapon: each class keeps its old default (`fallback`), so nothing changes for a
    character the package cannot read.
]]--

ataxiaTemp = ataxiaTemp or {}

local function isWielded(item)
  local a = type(item) == "table" and item.attrib
  return type(a) == "string" and (a:find("l", 1, true) or a:find("L", 1, true)) ~= nil
end

-- "warhammer" / "bastard" / nil for one item name.
local function weaponKind(name)
  if type(name) ~= "string" then return nil end
  local n = name:lower()
  if n:find("warhammer", 1, true) then return "warhammer" end
  if n:find("bastard", 1, true) then return "bastard" end
  return nil
end

-- The wielded two-hander, from the items we know are wielded.
function ataxiaBasher_twoHandWeapon()
  local wielded = ataxiaTemp.wieldedItems
  if type(wielded) == "table" then
    for _, name in pairs(wielded) do
      local k = weaponKind(name)
      if k then return k end
    end
  end
  return ataxiaTemp.twoHandLearned
end

-- The shield-break command for a Two Handed knight. `fallback` is the class's old verb.
function ataxiaBasher_twoHandRaze(tgt, fallback)
  local kind = ataxiaBasher_twoHandWeapon()
  if not kind and not ataxiaTemp.wieldInvAsked and sendGMCP then
    ataxiaTemp.wieldInvAsked = true
    pcall(sendGMCP, "Char.Items.Inv")
  end
  local verb = (kind == "warhammer" and "splinter") or (kind == "bastard" and "carve") or fallback
  return verb .. " " .. tostring(tgt)
end

-- GMCP inventory feed: keep id -> name for wielded items only.
function ataxiaBasher_wieldItemsEvent(event)
  local items = gmcp and gmcp.Char and gmcp.Char.Items
  if not items then return end
  if event == "gmcp.Char.Items.List" then
    local l = items.List
    if type(l) ~= "table" or l.location ~= "inv" then return end
    ataxiaTemp.wieldedItems = {}
    for _, it in ipairs(l.items or {}) do
      if isWielded(it) then ataxiaTemp.wieldedItems[tostring(it.id)] = it.name end
    end
    ataxiaTemp.twoHandLearned = nil -- a fresh picture outranks a refusal's guess
    return
  end
  local key = (event == "gmcp.Char.Items.Update" and "Update")
    or (event == "gmcp.Char.Items.Add" and "Add")
    or (event == "gmcp.Char.Items.Remove" and "Remove")
  local m = key and items[key]
  if type(m) ~= "table" or m.location ~= "inv" or type(m.item) ~= "table" then return end
  ataxiaTemp.wieldedItems = ataxiaTemp.wieldedItems or {}
  local id = tostring(m.item.id)
  if key ~= "Remove" and isWielded(m.item) then
    ataxiaTemp.wieldedItems[id] = m.item.name
    ataxiaTemp.twoHandLearned = nil
  else
    ataxiaTemp.wieldedItems[id] = nil
  end
end

-- Trigger 790: "You must be wielding a warhammer to splinter an opponent's defences."
function ataxiaBasher_splinterRefused()
  ataxiaTemp.twoHandLearned = "bastard"
  if ataxiaTemp.wieldedItems then
    for id, name in pairs(ataxiaTemp.wieldedItems) do
      if weaponKind(name) == "warhammer" then ataxiaTemp.wieldedItems[id] = nil end
    end
  end
  if type(target) ~= "number" then return end           -- PvE only
  if not (ataxiaBasher and ataxiaBasher.enabled) or ataxiaBasher.paused then return end
  if ataxiaTemp.swarmHold then return end               -- a pull chain is queued; do not wipe it
  local nowT = (getEpoch and getEpoch()) or 0
  if ataxiaTemp.splinterRefusedAt and (nowT - ataxiaTemp.splinterRefusedAt) < 1 then return end
  ataxiaTemp.splinterRefusedAt = nowT
  if ataxiaBasher_attack then ataxiaBasher_attack() end
end

-- Reload-safe registration: kill the previous ids first so a SYSUPDATE cannot stack handlers.
ataxiaTemp.wieldHandlers = ataxiaTemp.wieldHandlers or {}
for _, id in ipairs(ataxiaTemp.wieldHandlers) do
  if killAnonymousEventHandler then pcall(killAnonymousEventHandler, id) end
end
ataxiaTemp.wieldHandlers = {}
for _, ev in ipairs({ "gmcp.Char.Items.List", "gmcp.Char.Items.Update",
                      "gmcp.Char.Items.Add", "gmcp.Char.Items.Remove" }) do
  ataxiaTemp.wieldHandlers[#ataxiaTemp.wieldHandlers + 1] = registerAnonymousEventHandler(ev,
    function(event) if ataxiaBasher_wieldItemsEvent then ataxiaBasher_wieldItemsEvent(event) end end)
end
