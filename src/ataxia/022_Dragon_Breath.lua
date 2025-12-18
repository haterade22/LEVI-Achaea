-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Ataxia-DownloadThis > Ataxia > System-related > Deffing > Dragon Breath

function getDragonBreath()
	local colour = string.match(gmcp.Char.Status.class, "%w+")
	local types = {
		Black = "acid", Blue = "ice", Golden = "psi", Green = "venom", Red = "dragonfire", Silver = "lightning",
	}
	return types[colour]
end