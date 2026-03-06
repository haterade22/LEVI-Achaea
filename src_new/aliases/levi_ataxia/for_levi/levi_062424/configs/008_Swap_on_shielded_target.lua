--[[mudlet
type: alias
name: Swap on shielded target
hierarchy:
- Levi_Ataxia
- Ataxia
- Basher
- Configs
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^aconfig shieldswap$
command: ''
packageName: ''
]]--

--Ideally this will make it so you just don't bother razing shield if there's another target in room to hit.

if not ataxiaBasher.shieldswap then
	ataxiaBasher.shieldswap = true
else
	ataxiaBasher.shieldswap = false
end
ataxiaEcho( (ataxiaBasher.shieldswap and "Will" or "Won't") .. " look for a new target when denizens shield.")