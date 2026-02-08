ataxiaTemp.jinxCharge = ataxiaTemp.jinxCharge or 0
ataxiaTemp.jinxCharge = ataxiaTemp.jinxCharge + 1
ataxiaTemp.canJinx = true

if ataxiaBasher.enabled and not ataxiaBasher.manual then
	deleteFull()
end

