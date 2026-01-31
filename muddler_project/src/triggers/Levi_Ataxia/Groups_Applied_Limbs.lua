if isTargeted(matches[2]) then
tdeliverance = false
  if passiveFailsafe then restorePassiveCure() end
	-- V2 tracking support: limb salve cures slickness and other affs
	if onTargetSalveLimbsV2 then onTargetSalveLimbsV2(matches[2], matches[3]) end
	erAff("slickness")

	-- V3 integration: limbs salve cure branching
	if onSalveCureV3 then onSalveCureV3("limbs") end
	target_appliedTo(matches[3])
	targetIshere = true
	erAff("bloodfire")
end
 
--Pre-Apply Counter
if isTargeted(matches[2]) and matches[3] == "legs" then
  if mprepped_leftleg == true and mprepped_rightleg == true then
    tarpreapply = true
    tempTimer(4, [[tarpreapply = false]] )	
    else 
    tarpreapply = false
  end
end