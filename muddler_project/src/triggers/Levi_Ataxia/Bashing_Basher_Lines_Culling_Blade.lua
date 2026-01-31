ataxiaBasher.shielded = false
ataxiaTemp.ignoreCrits = false
if line ~= "You swing the culling blade in a great arc, black energy leaping from the blade." then
	bashStats.attacks = bashStats.attacks + 1
end

ataxiaTemp.bladeCooldown = tempTimer(24, [[ataxiaTemp.bladeCooldown = nil]])

if type(target) == "number" and ataxiaBasher.enabled then
	if line ~= "You swing the culling blade in a great arc, black energy leaping from the blade." then
		bashConsoleEchom("PEW", "CULLED "..matches[2], "red", "a_darkred")
	end

	if not ataxiaBasher.manual then
		deleteFull()
	end
end

