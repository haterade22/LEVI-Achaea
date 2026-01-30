if isTargeted(matches[2]) then
		tarAffed("hamstring")
		if hamstringTimer then killTimer(hamstringTimer) end
		hamstringTimer = tempTimer(10, [[tAffs.hamstring = nil]])

		-- Update BM dispatch timestamp for hamstring tracking
		if blademaster and blademaster.onHamstringApplied then
			blademaster.onHamstringApplied()
		end

if not ataxia.afflictions.aeon and partyrelay then
  send("pt " ..target..": Hamstring")
end
end