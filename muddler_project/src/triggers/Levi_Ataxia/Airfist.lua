if isTargeted(matches[2]) then
		tarAffed("airfist")
    tparrying = "none"
		if bmFistTimer then killTimer(bmFistTimer) end
		bmFistTimer = tempTimer(18, [[tAffs.airfist = nil; ataxia_Echo("Airfist has faded from "..target..".")]])
end