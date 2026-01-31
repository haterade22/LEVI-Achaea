--[[mudlet
type: script
name: Affliction Relapses for Two-handed
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Ataxia
- Combat
- Offensive Things
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

function twohanded_headHit()
  if ataxiaTables.fractureTimers.skull then killTimer(ataxiaTables.fractureTimers.skull) end
  
  if ataxiaTemp.fractures.skullfractures == 1 then
			ataxiaTables.fractureTimers.skull = tempTimer(5, [[twohanded_skullRelapse()]])
      
	elseif ataxiaTemp.fractures.skullfractures == 2 then
			ataxiaTables.fractureTimers.skull = tempTimer(4, [[twohanded_skullRelapse()]])
      
	elseif ataxiaTemp.fractures.skullfractures == 3 then
			ataxiaTables.fractureTimers.skull = tempTimer(3, [[twohanded_skullRelapse()]])
      
	elseif ataxiaTemp.fractures.skullfractures == 4 then
			ataxiaTables.fractureTimers.skull = tempTimer(2, [[twohanded_skullRelapse()]])
      
	elseif ataxiaTemp.fractures.skullfractures >= 5 then
			ataxiaTables.fractureTimers.skull = tempTimer(1, [[twohanded_skullRelapse()]])
	end 
end

function twohanded_armsHit()
  if ataxiaTables.fractureTimers.wrist then killTimer(ataxiaTables.fractureTimers.wrist) end
  
  if ataxiaTemp.fractures.wristfractures == 1 then
			ataxiaTables.fractureTimers.wrist = tempTimer(5, [[twohanded_wristRelapse()]])
      
	elseif ataxiaTemp.fractures.wristfractures == 2 then
			ataxiaTables.fractureTimers.wrist = tempTimer(4, [[twohanded_wristRelapse()]])
      
	elseif ataxiaTemp.fractures.wristfractures == 3 then
			ataxiaTables.fractureTimers.wrist = tempTimer(3, [[twohanded_wristRelapse()]])
      
	elseif ataxiaTemp.fractures.wristfractures == 4 then
			ataxiaTables.fractureTimers.wrist = tempTimer(2, [[twohanded_wristRelapse()]])
      
	elseif ataxiaTemp.fractures.wristfractures >= 5 then
			ataxiaTables.fractureTimers.wrist = tempTimer(1, [[twohanded_wristRelapse()]])
	end 
end

function twohanded_torsoHit()
  if ataxiaTables.fractureTimers.torso then killTimer(ataxiaTables.fractureTimers.torso) end
  
  if ataxiaTemp.fractures.crackedribs == 1 then
			ataxiaTables.fractureTimers.torso = tempTimer(5, [[twohanded_torsoRelapse()]])
      
	elseif ataxiaTemp.fractures.crackedribs == 2 then
			ataxiaTables.fractureTimers.torso = tempTimer(4, [[twohanded_torsoRelapse()]])
      
	elseif ataxiaTemp.fractures.crackedribs == 3 then
			ataxiaTables.fractureTimers.torso = tempTimer(3, [[twohanded_torsoRelapse()]])
      
	elseif ataxiaTemp.fractures.crackedribs == 4 then
			ataxiaTables.fractureTimers.torso = tempTimer(2, [[twohanded_torsoRelapse()]])
      
	elseif ataxiaTemp.fractures.crackedribs >= 5 then
			ataxiaTables.fractureTimers.torso = tempTimer(1, [[twohanded_torsoRelapse()]])
	end 
end

function twohanded_legsHit()
  if ataxiaTables.fractureTimers.legs then killTimer(ataxiaTables.fractureTimers.legs) end
  
  if ataxiaTemp.fractures.torntendons == 1 then
			ataxiaTables.fractureTimers.legs = tempTimer(5, [[twohanded_legsRelapse()]])
      
	elseif ataxiaTemp.fractures.torntendons == 2 then
			ataxiaTables.fractureTimers.legs = tempTimer(4, [[twohanded_legsRelapse()]])
      
	elseif ataxiaTemp.fractures.torntendons == 3 then
			ataxiaTables.fractureTimers.legs = tempTimer(3, [[twohanded_legsRelapse()]])
      
	elseif ataxiaTemp.fractures.torntendons == 4 then
			ataxiaTables.fractureTimers.legs = tempTimer(2, [[twohanded_legsRelapse()]])
      
	elseif ataxiaTemp.fractures.torntendons >= 5 then
			ataxiaTables.fractureTimers.legs = tempTimer(1, [[twohanded_legsRelapse()]])
	end 
end

function twohanded_skullRelapse()
  twohanded_headHit()
  send("echo "..target.."'s skull fractures relapsed nausea.",false)
  tarAffed("nausea")
end

function twohanded_wristRelapse()
  twohanded_armsHit()
  send("echo "..target.."'s wrist fractures relapsed lethargy.",false)
  tarAffed("lethargy")
end

function twohanded_torsoRelapse()
  twohanded_torsoHit()
  send("echo "..target.."'s cracked ribs relapsed sensitivity.",false)
  tarAffed("sensitivity")
end

function twohanded_legsRelapse()
  twohanded_legsHit()
  send("echo "..target.."'s torn tendons relapsed clumsiness.",false)
  tarAffed("clumsiness")
end