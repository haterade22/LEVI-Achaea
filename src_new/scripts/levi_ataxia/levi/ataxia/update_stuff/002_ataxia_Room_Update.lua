--[[mudlet
type: script
name: ataxia_Room_Update
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Ataxia
- Gmcp Related
- Update Stuff
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
eventHandlers:
- gmcp.Room
]]--

function ataxia_Room_Update()
 ataxiaBasher_stormhammer()  
	if not gmcp.Room.Info then return end
	if ataxiaBasher.enabled and ataxia.settings.roomshorten then enableTrigger("Room Info Shortener") end
	
  if ataxiaBasher.enabled then need_roomCheck = true end
  
	setMapZoom(8)
	centerview(gmcp.Room.Info.num)
	
	gPreviousRoom = gPreviousRoom or 0	
	gCurrentRoom = tonumber(gmcp.Room.Info.num)
	
	if not env_to_get then get_herbHarvestTable() end

	if ataxiaBasher.enabled and not ataxiaBasher.manual then
		for i, n in pairs(ataxiaBasher_path) do
			if tonumber(gmcp.Room.Info.num) == n then
				table.remove(ataxiaBasher_path, i)
				break
			end
		end
		if autoHarvesting and not harvested_in_room_stuff() and table.contains(env_to_get, gmcp.Room.Info.environment) then
			mmp.pause("on")
		end
	end

	if mapping_path ~= nil and not table.contains(mapping_path, gmcp.Room.Info.num) and mapping_bpath == true then
		table.insert(mapping_path, gmcp.Room.Info.num)
		ataxiaEcho(gmcp.Room.Info.num.." added.")
	end

	room_exits = {}
	for i,v in pairs(gmcp.Room.Info.exits) do
		table.insert(room_exits, i:upper())
	end
	room_exitstr = table.concat(room_exits, ", ")

	if ataxiaBasher.targetList then
		if not ataxiaBasher.targetList[gmcp.Room.Info.area] then
			ataxiaBasher.targetList[gmcp.Room.Info.area] = {}
			ataxiaEcho("Added "..gmcp.Room.Info.area.." to areas.")
		end
	end

	local roomInfo = "(v"..gmcp.Room.Info.num..") - "..gmcp.Room.Info.area.." - "..gmcp.Room.Info.name

  if ataxia.usegui == nil or ataxia.usegui == true then
    ataxiagui.mapRoom:echo([[<p style="font-size:12px"><center><font color="NavajoWhite"><font face="Merienda">]]..roomInfo..[[</font></p>]] )
    ataxiagui.mapExits:echo([[<p style="font-size:12px"><center><font color="NavajoWhite"><font face="Merienda">]].."[ "..room_exitstr.." ]"..[[</font></p>]] )
  elseif zgui then
    zgui.showRoomInfo()
  end
	
	if ataxia_isClass("Bard") then
		ataxiaTemp.harmsRoom = ataxiaTemp.harmsRoom or 0
		if gCurrentRoom ~= gPreviousRoom and gCurrentRoom ~= ataxiaTemp.harmsRoom then
			bardHarmsInRoom = false
		end
	end

	if ataxiaTemp.bashFlee then
		if not table.contains(ataxiaBasher_path, gPreviousRoom) then
			table.insert(ataxiaBasher_path, 1, gPreviousRoom)
		end
	end
	
  local bubbleEnv = {"Freshwater", "Ocean", "River",}
  local wDefs = ataxia.settings.defences
  if wDefs.current ~= "" and wDefs.current ~= nil and wDefs.current ~= "empty" then
    if (wDefs.defup[wDefs.current].grookbubble or wDefs.keepup[wDefs.current].grookbubble) and not ataxia.defences.grookbubble then
      if table.contains(gmcp.Room.Info.details, "underwater") or table.contains(bubbleEnv, gmcp.Room.Info.environment) then
        if not triedBubble then
          send("form bubble",false)
          triedBubble = tempTimer(3, [[ triedBubble = nil ]])
        end
      end
    end
  end
  
  if gCurrentRoom ~= gPreviousRoom then vibes_inRoom = {} end
	gPreviousRoom = tonumber(gmcp.Room.Info.num)
end
