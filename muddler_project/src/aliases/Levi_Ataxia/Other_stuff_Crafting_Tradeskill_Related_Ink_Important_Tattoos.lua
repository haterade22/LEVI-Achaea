if #crucialTattoos > 0 then
	ataxiaEcho("Going to ink a "..crucialTattoos[1].." tattoo on ourselves.")
	send("ink "..crucialTattoos[1].." on me")
else
	ataxiaEcho("We have all the necessary tattoos already!")
end