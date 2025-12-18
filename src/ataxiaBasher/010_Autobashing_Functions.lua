-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Ataxia-DownloadThis > Basher > Bashing > genRunning > Autobashing Functions

function ataxiaBasher_patterns()

  if ataxiaTemp.bashFlee then return end
  if ataxiaBasher.paused then return end
	--if not ataxiaBasher.paused and (speedWalkCounter < 1 or mmp.paused == true) and not autoHarvesting and not autoExtracting then
	if not ataxiaBasher.paused and (mmp.speedWalkCounter < 1 or mmp.paused == true) and not autoHarvesting and not autoExtracting then

    if not ataxiaBasher_skipRoom then
			if canBals() and canStand() then
				if found_target and not ataxiaBasher_atk then
          if gmcp.Char.Status.class == "Magi" then
            ataxiaBasher_magiBashing()
            ataxiaBasher_attack()
					  ataxiaBasher_atk = true
					  tempTimer(0.4, [[ataxiaBasher_atk=false]])
          else				
					ataxiaBasher_attack()
					ataxiaBasher_atk = true
					tempTimer(0.4, [[ataxiaBasher_atk=false]])
          end
				elseif not found_target and not ataxiaBasher.manual then
					if mmp.paused then
						ataxiaBasher_roomBashed()
						mmp.pause("off")
						send(" ")
          else
            ataxiaBasher_nextRoom()
          end
				end
			end
		elseif not ataxiaBasher.manual then
			if mmp.paused then
				ataxiaBasher_roomBashed()
				mmp.pause("off")
				send(" ")
      else
        ataxiaBasher_nextRoom()
      end
		end
	elseif autoHarvesting then
		ataxiaHarvester_check()
  elseif autoExtracting then
    ataxiaExtractor_check()
	--elseif not ataxiaBasher.manual and (speedWalkCounter < 1 or mmp.paused == true) then
  elseif not ataxiaBasher.manual and (mmp.speedWalkCounter < 1 or mmp.paused == true) then
	
		if mmp.paused then
			ataxiaBasher_roomBashed()
			mmp.pause("off")
			send(" ")
    else
      ataxiaBasher_nextRoom()
    end
	end
ataxiaBasher_stormhammer()		
end

function ataxiaBasher_nextRoom()
  local nextRoom, dist = 0, 9999
  
  if not autoExtracting and not autoHarvesting then
    ataxiaBasher_roomBashed()     
  else
    ataxiaHarvester_harvested()
  end
  if ataxiaBasher.manual then return end
  if #ataxiaBasher_path > 0 then
    if not ataxiaTemp.mapperPath then
      expandAlias("goto "..ataxiaBasher_path[1], false)
    else
      for _, v in ipairs(ataxiaBasher_path) do
        getPath(gCurrentRoom, v)
        if table.size(speedWalkDir) == 1 then
          nextRoom = v
          break
        elseif table.size(speedWalkDir) < dist then
          dist = table.size(speedWalkDir)
          nextRoom = v
        end
      end
      expandAlias("goto "..nextRoom,false)
    end
  else
    ataxiaBasher_areaoff()
  end   
   ataxiaBasher_stormhammer()         
end

function ataxiaBasher_manual()
	mmp.pause("off")
	if not ataxiaBasher.enabled then
		ataxiaEcho("Bashing module engaged. Manual movement required.")
		ataxiaBasher.enabled = true
		ataxiaBasher.paused = false
		ataxiaBasher.manual = true
		ataxiaBasher.areabash = false
		raiseEvent("basher enabled")
	else
		ataxiaBasher.enabled = false
		ataxiaBasher.paused = false
		ataxiaBasher.manual = false
		ataxiaBasher.areabash = false
		ataxiaEcho("Bashing systems disengaged.")
		raiseEvent("basher disabled")
	end
end

function ataxiaBasher_areabash()
	mmp.pause("off")
	local curArea = gmcp.Room.Info.area
	if ataxiaBasher.targetList[curArea] then
		ataxiaEcho("Complete control sacrificed. Walking to start of slaughter path.")
		ataxiaBasher.enabled = true
		ataxiaBasher.paused = false
		ataxiaBasher.manual = false
		ataxiaBasher.areabash = true
		ataxiaBasher_generatePath()
		raiseEvent("basher enabled")
	end
end

function ataxiaBasher_areaoff()
	mmp.pause("off")
	ataxiaBasher.enabled = false
	ataxiaBasher.paused = false
	ataxiaBasher.manual = false
	ataxiaBasher.areabash = false
	ataxiaEcho("Bashing systems disengaged.")
	raiseEvent("basher disabled")
end