--[[mudlet
type: alias
name: KAI CHOKE
hierarchy:
- Levi_Ataxia
- Classes
- Monk
- Kaido
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^kc$
command: ''
packageName: ''
]]--

-- KAI CHOKE (Kaido.wiki:286: 10 kai and 50 mana; no kai against a denizen, :289). When kai is
-- KNOWN to be short this alias sends MIND CRUSH instead, as it always has, and now says so
-- (monk/004 owns the costs). An unknown kai sends the choke as typed.
local ok, have, need = ataxia_kaiAfford("choke", nil, target)
if ok or not (have and need) then
  send("queue addclear free kai choke " ..target)
else
  ataxiaEcho("<yellow>[Kai] CHOKE needs " .. need .. ", have " .. have .. " -- mind crush instead<reset>")
  send("queue addclear free mind crush " ..target)
end
