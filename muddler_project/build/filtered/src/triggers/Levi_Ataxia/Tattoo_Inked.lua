local tat = matches[2]:lower()
tat = tat:title()

if table.contains(crucialTattoos, tat) then
	send("touch "..tat)
	table.remove(crucialTattoos, table.index_of(crucialTattoos, tat))
end

if crucialTattoos and #crucialTattoos > 0 then
	cecho("\n<LightSlateGrey> "..utf8.char(186).."----------------------------------------------------"..utf8.char(186))
	cecho("\n<LightSlateBlue>   Still missing: <NavajoWhite>"..table.concat(crucialTattoos, ", ").."<LightSlateBlue>.")
	cecho("\n<LightSlateGrey> "..utf8.char(186).."----------------------------------------------------"..utf8.char(186))
elseif #crucialTattoos == 0 then
	ataxiaEcho("All tattoos are done!")
end