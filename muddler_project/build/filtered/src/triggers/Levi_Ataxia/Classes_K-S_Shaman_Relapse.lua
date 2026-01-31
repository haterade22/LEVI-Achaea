ataxiaTemp.relapse = true
ataxiaTemp.relapseAff = matches[2]

if ataxiaTemp.relapseAff ~= "paralysis" then
	ataxiaTemp.relapseWait = tempTimer(1.8, [[ataxiaTemp.relapseWait = nil]])
end