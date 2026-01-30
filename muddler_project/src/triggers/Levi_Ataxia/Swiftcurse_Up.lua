curseCharge = 14
swiftcursing = false

if ataxiaBasher.enabled and found_target then
	--ataxiaBasher_attack()
  basher_needAction = true
  if not ataxiaBasher.manual then
    deleteFull()
  end  
end

