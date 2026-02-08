if #ataxia.playersHere > 0 then
	table.sort(ataxia.playersHere)
	cecho("\n<NavajoWhite>(<goldenrod>"..#ataxia.playersHere.."<NavajoWhite>) <DimGrey>"..(#ataxia.playersHere == 1 and "person" or "people").." here: ")
	cecho("<CornflowerBlue>"..table.concat(ataxia.playersHere, ", ")..".")
end