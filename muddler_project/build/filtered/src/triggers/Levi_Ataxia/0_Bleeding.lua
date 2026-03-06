if tAffs.bleed and tAffs.bleed > 0 then
	tAffs.haemophilia = false
	if removeAffV3 then removeAffV3("haemophilia") end
end

tAffs.bleed = 0
cecho(" <white>[<red>"..tAffs.bleed.."<white>]")