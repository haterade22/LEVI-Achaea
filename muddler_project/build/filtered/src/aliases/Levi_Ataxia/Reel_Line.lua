if not ataxia.fishing then
	ataxiaEcho("Fishing variables do not exist. Use afish init to fix this.")
else
	ataxiaEcho("Stopping fishing.")
	ataxia.fishing.enabled = false
	send("reel line")
end