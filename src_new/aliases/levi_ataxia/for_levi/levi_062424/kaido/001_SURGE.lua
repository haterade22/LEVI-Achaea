--[[mudlet
type: alias
name: SURGE
hierarchy:
- Levi_Ataxia
- Classes
- Monk
- KAIDO
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^sur$
command: ''
packageName: ''
]]--

-- KAI SURGE (Kaido.wiki:319: 45 kai). A typed command is the user's call: it goes out whatever we
-- read, and when kai is KNOWN to be short we say so first (monk/004 owns the costs).
local ok, have, need = ataxia_kaiAfford("surge", nil, target)
if not ok and have and need then
  ataxiaEcho("<yellow>[Kai] SURGE needs " .. need .. ", have " .. have .. " -- sent anyway<reset>")
end
send("queue addclear free kai surge "..target)
