if not ataxiaTemp.ignoreShield then
	local nairat = {"nocaloric", "shivering", "frozen"}
	local count = 0
	for _, aff in pairs(nairat) do
		if count == 2 then
			break
		else
			if not haveAff(aff) then
				tAffs[aff] = true
				count = count + 1
			end
		end
	end
	selectString(line, 1)
	if haveAff("frozen") then
		fg("blue")
	else
		fg("a_blue")
	end
	deselect()
end
ataxiaTemp.ignoreShield = nil