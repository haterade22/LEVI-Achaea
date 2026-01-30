local person = multimatches[1][2]
if isTargeted(perosn) then
	if multimatches[3][1] == "The attack rebounds back onto you!" then
  tAffs.rebounding = true
  table.remove(envenomList, 1)
	table.remove(envenomListTwo, 1)
	elseif  multimatches[3][1] == "A reflection of " .. person .. " blinks out of existence." then
	 table.remove(envenomList, 1)
   table.remove(envenomListTwo, 1)
	else
	
	 if not affs_to_colour then populate_aff_colours() end
    aff1 = venom_to_aff(envenomList[1])
    table.remove(envenomList, 1)
    aff2 = venom_to_aff(envenomListTwo[1])
    tarAffed(aff2)
	end
end

if snapTarget then
	snapTarget = false
	ataxiaTemp.snapTimer = tempTimer(0.4, [[
		if haveAff("asthma") and not haveAff("rebounding") then
			send("snap "..target..ataxia.settings.separator.."snap "..target)
		end
		ataxiaTemp.snapTimer = nil
	]])
end