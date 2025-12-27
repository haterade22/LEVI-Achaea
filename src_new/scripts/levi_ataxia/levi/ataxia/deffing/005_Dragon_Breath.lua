--[[mudlet
type: script
name: Dragon Breath
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Ataxia
- System-related
- Deffing
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

function getDragonBreath()
	local colour = string.match(gmcp.Char.Status.class, "%w+")
	local types = {
		Black = "acid", Blue = "ice", Golden = "psi", Green = "venom", Red = "dragonfire", Silver = "lightning",
	}
	return types[colour]
end