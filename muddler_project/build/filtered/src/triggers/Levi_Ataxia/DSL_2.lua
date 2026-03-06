local weapons = {"Soulpiercer", "Eagle's Scream","rapier"}

for i in pairs(weapons) do
 if not string.find(multimatches[1][4], weapons[i]) then
 
	slc_last_limb = multimatches[1][3]

	dualcweapcheck = true
	tempTimer(1, [[slc_dualcweapcheck = false]] )
	
 end
end