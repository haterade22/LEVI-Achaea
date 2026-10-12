--[[mudlet
type: alias
name: kai enfeeble
hierarchy:
- Levi_Ataxia
- Classes
- Monk
- Kaido
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^ke$
command: ''
packageName: ''
]]--

-- KAI ENFEEBLE (Kaido.wiki:352: 61 kai; none against a denizen with the Spirit Rend boon). This
-- sent nothing, silently, below 61. A typed command is the user's call: it goes out whatever we
-- read, and when kai is KNOWN to be short we say so first (monk/004 owns the costs).
local ok, have, need = ataxia_kaiAfford("enfeeble", nil, target)
if not ok and have and need then
  ataxiaEcho("<yellow>[Kai] ENFEEBLE needs " .. need .. ", have " .. have .. " -- sent anyway<reset>")
end
send("queue addclear free kai enfeeble " ..target)
