local name = matches[2]

if isTargeted(matches[2]) and tBals.focus then
	tarAffed("nausea")
	if applyAffV3 then applyAffV3("nausea") end
	tBals.focus = false
	tempTimer(2, [[tBals.focus = true]])
	targetIshere = true
end