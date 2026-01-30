ataxiaTemp.jinxCharge = ataxiaTemp.jinxCharge or 0
ataxiaTemp.jinxCharge = ataxiaTemp.jinxCharge - 1
if ataxiaTemp.jinxCharge < 1 then
	ataxiaTemp.canJinx = false
	ataxiaTemp.jinxCharge = 0
end

if ataxiaBasher.enabled and not ataxiaBasher.manual then
	deleteFull()
end

if ataxiaBasher and found_target then
	--ataxiaBasher_attack()
  basher_needAction = true
end