--[[mudlet
type: alias
name: Control First Denizens
hierarchy:
- Levi_Ataxia
- Ataxia
- Basher
- Lists
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^bash control ?(.*)$
command: ''
packageName: ''
]]--

-- Denizens whose own attacks are the threat, so battlerage is better spent on THEIR
-- balance than on their health (user: "a manifested nightmare -- when facing this denizen
-- we need to use as many battlerages that slow their attacks down as possible").
--
-- This only REORDERS abilities the class already owns; it never adds one. What each class
-- actually gains:
--   Blademaster   Daze (Stun, 4s) and Nerveslash (Weakness, 66% damage) before damage
--   Magi          Dilation (Aeon -- the mob acts once per lengthy balance)
--   Depthswalker  Chrono Curse (Aeon)
--   Golden Dragon Deaden (Aeon) and Psidaze (Amnesia)
--   Runewarden    Bulwark -- NOT a slow: Runewarden has no battlerage that slows a denizen
--                 (etch consumes aeon/stun rather than applying it). Bulwark negating 25%
--                 of all damage is the nearest equivalent, and this keeps it from being
--                 displaced by the Rage-Fuelled "spend the dearest first" rule.
--   Psion, Monk   nothing -- neither has an attack-slowing battlerage.
--
--   bash control                  - list entries (click to remove)
--   bash control add <name>       - add a denizen
--   bash control rem <name>       - remove one
ataxiaBasher.controlMobs = ataxiaBasher.controlMobs or {}

local arg = (matches[2] or ""):gsub("^%s+", ""):gsub("%s+$", "")

local function save() if ataxia_saveSettings then ataxia_saveSettings(false) end end

if arg == "" then
  if #ataxiaBasher.controlMobs == 0 then
    ataxiaEcho("No control-first denizens set. Add one with: <white>bash control add <name>")
    ataxiaEcho("<grey>Use this for mobs whose ATTACKS are the danger -- battlerage goes on")
    ataxiaEcho("<grey>slowing them (aeon/stun/weakness) before it goes on damage.")
  else
    ataxiaEcho("Control-first denizens -- click to remove:")
    for _, nm in ipairs(ataxiaBasher.controlMobs) do
      cecho("\n  <green>+ ")
      fg("white")
      echoLink(nm, [[ataxiaBasher_removeControlMob("]] .. nm .. [[")]], "Stop prioritising control against '" .. nm .. "'.", true)
      cecho(" <green>+")
    end
    send(" ")
  end
  return
end

local action, nm = arg:match("^(%S+)%s+(.+)$")
action = (action or arg):lower()

if action == "add" and nm then
  ataxiaBasher_addControlMob(nm)
elseif (action == "rem" or action == "remove" or action == "del" or action == "delete") and nm then
  ataxiaBasher_removeControlMob(nm)
else
  ataxiaEcho("Usage: <white>bash control<NavajoWhite> | <white>bash control add <name><NavajoWhite> | <white>bash control rem <name>")
end
