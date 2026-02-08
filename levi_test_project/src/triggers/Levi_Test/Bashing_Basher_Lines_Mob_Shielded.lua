local tar = matches[2]:lower()

if type(target) == "number" and ataxiaBasher.enabled and tar == secondTarget:lower() then
  bashConsoleEcho("denizen", "Coward shielded!")
  local argFound = false
  
  if not ataxiaBasher.shieldswap or ataxiaBasher_validTargets() <= 1 or ataxiaTemp.mobshieldtimer then
    ataxiaBasher.shielded = true
    local shieldDur = (ataxiaBasher.shieldTimers and ataxiaBasher.shieldTimers[secondTarget])
      or ataxiaBasher.shieldTimerDefault or 3.1
    removeShield = tempTimer(shieldDur, [[ ataxiaBasher.shielded = false; removeShield = nil]])
  elseif ataxiaBasher.shieldswap and ataxiaBasher_validTargets() > 1 and not ataxiaTemp.mobshieldtimer then
    ataxiaBasher_shieldedTarget()
  end
  basher_needAction = true

	
elseif isTargeted(tar) then
	selectString(line, 1)
	fg("a_brown")
	resetFormat()
	tAffs.shield = true
	if applyAffV3 then applyAffV3("shield") end
	-- Update V2 tracking if available
	if tAffsV2 then
		tAffsV2.shield = 100
	end
end

