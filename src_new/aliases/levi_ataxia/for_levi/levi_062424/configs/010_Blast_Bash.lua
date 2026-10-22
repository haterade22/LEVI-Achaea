--[[mudlet
type: alias
name: Blast Bash
hierarchy:
- Levi_Ataxia
- Ataxia
- Basher
- Configs
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^bash blast (on|off)$
command: ''
packageName: ''
]]--

-- Toggle whether the dragon basher BLASTS. A round is one attack (v4.7.438): when on, the round
-- is "blast <tar>;summon <ele>", or "summon <ele>;blast <tar>;summon <ele>" with the breath down
-- (summon is off-eq, v4.7.439). Might of Sycaerunax blasts even when this is off.
if matches[2] == "on" then
	ataxiaBasher.dragonBlast = true
else
	ataxiaBasher.dragonBlast = false
end
ataxiaEcho("Dragon blast-weave has been "..(ataxiaBasher.dragonBlast == true and "<green>Enabled." or "<red>Disabled."))
