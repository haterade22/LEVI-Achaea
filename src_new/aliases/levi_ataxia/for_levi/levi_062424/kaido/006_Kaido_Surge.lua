--[[mudlet
type: alias
name: Kaido Surge
hierarchy:
- Levi_Ataxia
- Classes
- Monk
- Kaido
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^ks$
command: ''
packageName: ''
]]--

-- KAI SURGE (Kaido.wiki:319: 45 kai). This sent nothing, silently, below 31 kai, which was also
-- the wrong cost (kb/CONFLICTS.md #9). A typed command is the user's call: it goes out whatever we
-- read, and when kai is KNOWN to be short we say so first (monk/004 owns the costs).
local ok, have, need = ataxia_kaiAfford("surge", nil, target)
if not ok and have and need then
  ataxiaEcho("<yellow>[Kai] SURGE needs " .. need .. ", have " .. have .. " -- sent anyway<reset>")
end
send("queue addclear free kai surge " ..target)
