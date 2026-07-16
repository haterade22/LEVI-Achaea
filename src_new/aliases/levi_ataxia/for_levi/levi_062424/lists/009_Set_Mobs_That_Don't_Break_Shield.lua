--[[mudlet
type: alias
name: Set Mobs That Don't Break Shield
hierarchy:
- Levi_Ataxia
- Ataxia
- Basher
- Lists
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^bash safec?$
command: ''
packageName: ''
]]--

if ataxia.denizensHere and ataxiaBasher.targetList[ataxiaBasher_areaKey()] then
	if matches[1]:find("c") then
		for _, mob in pairs(ataxiaBasher.targetList[ataxiaBasher_areaKey()]) do
			ataxiaBasher_shieldingAdd(mob)
		end
		ataxiaEcho("Shielding list has been updated to reflect the entire area.")
	else
		ataxiaEcho("Displaying mobs in the area. Click A/R to add/remove from the shield list.")
	
		for _, mob in pairs(ataxiaBasher.targetList[ataxiaBasher_areaKey()]) do
			echo("\n")
			fg("red")
			echoLink("[A]", [[ataxiaBasher_shieldingAdd("]]..mob..[[")]], "Add "..mob.." to the danger list.", true)
			fg("green")
			echoLink("[R]", [[ataxiaBasher_shieldingRemove("]]..mob..[[")]], "Remove "..mob.." from danger list.", true)
			cecho("<NavajoWhite> "..mob)
		end
	end
else
	ataxiaEcho("Target list for this area is not yet populated.")
end
send(" ")