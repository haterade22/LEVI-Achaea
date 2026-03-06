--^\w+ viciously jabs .+ into your (.+)\.$
local weapons = {"Soulpiercer", "Eagle's Scream","rapier"}

for i in pairs(weapons) do
 if not string.find(multimatches[1][3], weapons[i]) then

	slc_last_limb = multimatches[1][4]

	dualcweapcheck = true
	tempTimer(1, [[dualcweapcheck = false]] )	
	
 end
end
