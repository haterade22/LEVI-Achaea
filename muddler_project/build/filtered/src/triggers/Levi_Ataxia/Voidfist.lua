if isTargeted(matches[2]) then
		tarAffed("voidfist")
		if bmFistTimer then killTimer(bmFistTimer) end
		bmFistTimer = tempTimer(18, [[tAffs.voidfist = nil; ataxia_Echo("Voidfist has faded from "..target..".")]])
end