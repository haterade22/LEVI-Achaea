--[[mudlet
type: script
name: search_targets
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Basher
- Bashing
- genRunning
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
eventHandlers:
- targets updated
]]--

-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Ataxia-DownloadThis > Basher > Bashing > genRunning > search_targets

-- Track which room we've already drawn ldeck cards for
ataxiaBasher.ldeckDrawnRoom = nil

-- Helper to count specific mob types in current room
function ataxiaBasher_countMobsInRoom(mobName)
  local count = 0
  for id, mob in pairs(ataxia.denizensHere) do
    if mob:lower() == mobName:lower() then
      count = count + 1
    end
  end
  return count
end

-- Draw ldeck cards before combat for dangerous multi-target rooms
function ataxiaBasher_preCombatLdeck()
  local roomId = gmcp.Room.Info.num

  -- Skip if we already drew for this room
  if ataxiaBasher.ldeckDrawnRoom == roomId then
    return false
  end

  local keeperCount = ataxiaBasher_countMobsInRoom("an elite mhun keeper")
  local knightCount = ataxiaBasher_countMobsInRoom("a mhun knight")

  local drawMaran = false
  local drawMatic = false

  -- Elite keepers: 3+ = both cards
  if keeperCount >= 3 then
    drawMaran = true
    drawMatic = true
  end

  -- Knights: 3 = maran only, 4+ = both
  if knightCount >= 3 then
    drawMaran = true
    if knightCount >= 4 then
      drawMatic = true
    end
  end

  -- Send ldeck draws using queue system
  if drawMaran or drawMatic then
    if drawMaran then
      send("queue add free ldeck draw maran")
    end
    if drawMatic then
      send("queue add free ldeck draw matic")
    end
    ataxiaBasher.ldeckDrawnRoom = roomId
    return true
  end

  return false
end

function search_targets()
	if (not ataxiaBasher.enabled) or need_roomCheck then return false end
  if autoHarvesting or autoExtracting then return false end
	found_target = false
	if ataxiaBasher_skipRoom then return false end
	
  for i,v in pairs(ataxia.denizensHere) do
		if tonumber(i) == target then
			found_target = true
			return
 
		end
  end
	
	if not found_target then
		for num,npc in pairs(ataxiaBasher.targetList[gmcp.Room.Info.area]) do
			if num ~= "keyword" then
				for id,mob in pairs(ataxia.denizensHere) do
					if mob:lower() == npc:lower() then
						target=tonumber(id)
						secondTarget = mob
						found_target = true
						send("st "..target)
						if ataxiaBasher.manual then
							ataxiaEcho("Now targeting: "..target)
              send("pt Target: " ..target)
						end
						raiseEvent("changed target")
						--if speedWalkCounter > 0 and not mmp.paused then mmp.pause("on") end
						if mmp.speedWalkCounter > 0 and not mmp.paused then mmp.pause("on") end
            ataxiaBasher_preCombatLdeck()
            return
					end
				end
			end
		end
	end
  ataxiaBasher_stormhammer()
end

function ataxiaBasher_stormhammer()
stormhammerTargets = {}
for k,v in pairs(ataxia.denizensHere) do
  if (table.contains(ataxiaBasher.targetList[gmcp.Room.Info.area], v)) then 

    table.insert(stormhammerTargets, tostring(k))
    --cecho("\n<green>Added <white>"..tostring(v).."<white> to Stormhammer table: ")
    --display(stormhammerTargets)
  --else
    --cecho("\n<white>Skipping <red>"..v.."<white> as it was not found in targetList")
  end
end

end

function ataxiaBasher_retargetShielded()

  target = ataxiaTemp.retarget
  secondTarget = ataxiaTemp.retargetsecond
  basher_needAction = true
  ataxiaTemp.retarget = nil
  ataxiaTemp.retargetsecond = nil
  raiseEvent("changed target")
  bashConsoleEcho("denizen", "Retargeting previous target")
  if ataxiaTemp.mobshieldtimer then killTimer(ataxiaTemp.mobshieldtimer); ataxiaTemp.mobshieldtimer = nil end
  if ataxiaBasher.manual then
    ataxiaEcho("Unshielded, changing back to: "..target)
  end  
  send("st "..target,false)
  ataxiaBasher_stormhammer()
end

function ataxiaBasher_shieldedTarget()

  found_target = false
  for num, npc in pairs(ataxiaBasher.targetList[gmcp.Room.Info.area]) do
    if num ~= "keyword" and not found_target then
      for id, mob in pairs(ataxia.denizensHere) do
        if mob:lower() == npc:lower() then
          if target ~= tonumber(id) then
            ataxiaTemp.retarget = target
            ataxiaTemp.retargetsecond = secondTarget
            target = tonumber(id)
            secondTarget = mob
            found_target = true
            basher_needAction = true
            send("st "..target,false)
						if ataxiaBasher.manual then
							ataxiaEcho("Shielded, changing to: "..target)
						end
						raiseEvent("changed target")
            if ataxiaTemp.mobshieldtimer then killTimer(ataxiaTemp.mobshieldtimer); ataxiaTemp.mobshieldtimer = nil end
            if ataxiaTemp.retargetsecond == "a mhun knight" then
              ataxiaTemp.mobshieldtimer = tempTimer(4.7, [[ ataxiaBasher_retargetShielded() ]])
            else
              ataxiaTemp.mobshieldtimer = tempTimer(3.1, [[ ataxiaBasher_retargetShielded() ]])
            end
            return
          end
        end
      end
    end
  end   
  ataxiaBasher_stormhammer()         
end

function ataxiaBasher_validTargets()
  local c = 0
   ataxiaBasher_stormhammer()  
  for i, v in pairs(ataxia.denizensHere) do
    if table.contains(ataxiaBasher.targetList[gmcp.Room.Info.area], v) then
      c= c + 1
    end
  end
  return c

end