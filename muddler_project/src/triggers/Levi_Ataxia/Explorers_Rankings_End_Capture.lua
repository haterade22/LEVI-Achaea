setTriggerStayOpen("Explorers Rankings", 0)
if explorersUnchecked[1] then
	ataxiaEcho(#explorersUnchecked.." new names identified, grabbing their info.")
	cecho("\n<a_darkgrey> - "..table.concat(explorersUnchecked, ", ")..".")
	ataxiaNDB_NameList(explorersUnchecked)
end