--^Lightning-quick, \w+ (?:stabs|jabs) your (.+) with
local weapons = {"Soulpiercer", "Eagle's Scream","rapier"}

for i in pairs(weapons) do
 if string.find(multimatches[1][4], weapons[i]) then

	slc_last_limb = multimatches[1][3]

	weapcheck = true
	tempTimer(1, [[weapcheck = false]] )
	
 end
end
