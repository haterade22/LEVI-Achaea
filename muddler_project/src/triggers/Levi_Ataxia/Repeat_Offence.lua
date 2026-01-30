if _G[ataxiaTemp.repeatOffence] then
	_G[ataxiaTemp.repeatOffence]()
else
	ataxiaTemp.repeatOffence = nil
end
disableTrigger("Repeat Offence")
