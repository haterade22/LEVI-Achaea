--[[mudlet
type: alias
name: KAI CRIPPLE
hierarchy:
- Levi_Ataxia
- Classes
- Monk
- Kaido
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^kcr$
command: ''
packageName: ''
]]--

-- KAI CRIPPLE (Kaido.wiki:297: 41 kai). This sent nothing, silently, below 41. A typed command is
-- the user's call: it goes out whatever we read, and when kai is KNOWN to be short we say so first
-- (monk/004 owns the costs).
local ok, have, need = ataxia_kaiAfford("cripple", nil, target)
if not ok and have and need then
  ataxiaEcho("<yellow>[Kai] CRIPPLE needs " .. need .. ", have " .. have .. " -- sent anyway<reset>")
end
send("queue addclear free kai cripple " ..target)
