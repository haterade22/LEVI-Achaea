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

-- Toggle whether the dragon basher weaves a breath BLAST into its incantation/gut rotation.
-- When on and dragonbreath is summoned, the attack becomes "blast <tar>;summon <ele>;<incant/gut> <tar>".
if matches[2] == "on" then
	ataxiaBasher.dragonBlast = true
else
	ataxiaBasher.dragonBlast = false
end
ataxiaEcho("Dragon blast-weave has been "..(ataxiaBasher.dragonBlast == true and "<green>Enabled." or "<red>Disabled."))
