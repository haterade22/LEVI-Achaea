function getDragonBreath()
	local colour = string.match(gmcp.Char.Status.class, "%w+")
	local types = {
		Black = "acid", Blue = "ice", Golden = "psi", Green = "venom", Red = "dragonfire", Silver = "lightning",
	}
	return types[colour]
end