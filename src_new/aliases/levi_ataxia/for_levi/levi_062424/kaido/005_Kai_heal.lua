--[[mudlet
type: alias
name: Kai heal
hierarchy:
- Levi_Ataxia
- Classes
- Monk
- Kaido
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^kh$
command: ''
packageName: ''
]]--

-- KAI HEAL (Kaido.wiki:308: 21 kai, self). This sent nothing, silently, below 21. A typed command
-- is the user's call: it goes out whatever we read, and when kai is KNOWN to be short we say so
-- first (monk/004 owns the costs).
local ok, have, need = ataxia_kaiAfford("heal")
if not ok and have and need then
  ataxiaEcho("<yellow>[Kai] HEAL needs " .. need .. ", have " .. have .. " -- sent anyway<reset>")
end
send("queue addclear free kai heal")
