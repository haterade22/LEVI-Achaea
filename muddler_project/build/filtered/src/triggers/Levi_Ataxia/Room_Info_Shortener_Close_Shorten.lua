if roomDeleting then
	deleteLine()

	cecho("\n<cyan>(<a_darkcyan>v"..gmcp.Room.Info.num.."<cyan>) <DarkKhaki>"..gmcp.Room.Info.name..".\n")
	local denizens = {}
	for num, mob in pairs(ataxia.denizensHere) do
		table.insert(denizens, mob:title())
	end
	if denizens[1] then
		cecho("\n<a_darkgreen>Denizens: <a_brown>"..table.concat(denizens, ", ")..".")
	end
	if ataxia.playersHere[1] then
		cecho("\n<purple>Players : <a_green>"..table.concat(ataxia.playersHere, ", ")..".")
	end
	
	cecho("\n<NavajoWhite>[Exits] : <goldenrod>"..room_exitstr..".")
end


roomDeleting = false
setTriggerStayOpen("Room Info Shortener",0)
disableTrigger("Room Info Shortener")