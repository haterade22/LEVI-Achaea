function ataxia_RoomContents_Update(event)
	--Create the table if it's not already there.
   ataxiaBasher_invalidateStormhammer()
	ataxia.denizensHere = ataxia.denizensHere or {}
	atempDenizens = atempDenizens or {}
	waterGuards = waterGuards or {}
  if gmcp.Char.Items.List.location ~= "inv" then
    ataxia.lightwall = false
    ataxiaTemp.monolith = false
  end
	ataxiaBasher_skipRoom = false

	--For QL/Entering a room.
	if event == "gmcp.Char.Items.List" and gmcp.Char.Items.List.location ~= "inv" then
		ataxia.denizensHere = {}
		atempDenizens = {}
		ataxiaTemp.goldInRoom = false
		local ignoreCount = 0
		for i,v in pairs(gmcp.Char.Items.List.items) do
      if v.name:find("lightwall") then
        ataxia.lightwall = true 
      elseif v.name:find("monolith") then
        ataxiaTemp.monolith = true
			elseif v.attrib and v.attrib ~= "t" and v.attrib ~= "mdt" and v.icon ~= "guard" then
				ataxia.denizensHere[tonumber(v.id)] = v.name
				
				if (v.name == "a guarded firewall" or v.name == "an audacious guardsman" or v.name == "a Vault guardian") and not table.contains(waterGuards, v.id) and #waterGuards < 10 and beckonGuards then
					send("beckon "..v.id)
					table.insert(waterGuards, v.id)
				elseif v.name == "an audacious guardsman" and not table.contains(waterguards, v.id) and #waterGuards < 10 and saluteGuards then
					send("wsalute "..v.id)
					table.insert(waterGuards, v.id)
				elseif v.name == "a Coterie councillor" and not table.contains(waterguards, v.id) and #waterGuards < 15 and saluteGuards then
					sendAll("grab "..v.id,false)
					table.insert(waterGuards, v.id)
				elseif v.name == "a Coterie councillor" and not table.contains(waterGuards, v.id) and #waterGuards < 10 and beckonGuards then
					sendAll("give document to "..v.id, "g document")
					table.insert(waterGuards, v.id)
				end
				
				atempDenizens[tonumber(v.id)] = v.name
				
			elseif v.icon == "coin" then
				ataxiaTemp.goldInRoom = true
      elseif table.contains(item_Pickup, v.name) then
        send("get "..v.id,false)
			end
  if ataxiaBasher.enabled then ataxiaBasher_invalidateStormhammer() end
		end

	--Remove (either by leaving, or dying)
	elseif event == "gmcp.Char.Items.Remove" then
  
		for i,v in pairs(ataxia.denizensHere) do
      
			if tonumber(i) == tonumber(gmcp.Char.Items.Remove.item.id) then
				ataxia.denizensHere[i] = nil
      if ataxiaBasher.enabled then ataxiaBasher_invalidateStormhammer() end
			end
    
      
      if ataxiaTemp.retarget and tonumber(i) == ataxiaTemp.retarget then
        ataxiaTemp.retarget = nil
        ataxiaTemp.retargetsecond = nil
        if ataxiaTemp.mobshieldtimer then killTimer(ataxiaTemp.mobshieldtimer); ataxiaTemp.mobshieldtimer = nil end
      end
		end
		if gmcp.Char.Items.Remove.item.icon == "coin" then
			ataxiaTemp.goldInRoom = false
    elseif gmcp.Char.Items.Add.location == "room" and gmcp.Char.Items.Remove.item.name == "a monolith sigil" then
      ataxiaTemp.monolith = false
		end		
		
	--Add the denizen.
	else
		if gmcp.Char.Items.Add.location == "room" and gmcp.Char.Items.Add.item.attrib ~= "t" and gmcp.Char.Items.Add.item.icon ~= "guard" then
			ataxia.denizensHere[gmcp.Char.Items.Add.item.id] = gmcp.Char.Items.Add.item.name
			atempDenizens[gmcp.Char.Items.Add.item.id] = gmcp.Char.Items.Add.item.name
		end
		if gmcp.Char.Items.Add.item.icon == "coin" then
			if ataxiaBasher.enabled then
				ataxiaTemp.goldInRoom = true
			end
		end
		if gmcp.Char.Items.Add.item.name == "a lightwall" then
			ataxia.lightwall = true
    elseif gmcp.Char.Items.Add.location == "room" and gmcp.Char.Items.Add.item.name == "a monolith sigil" then
      ataxiaTemp.monolith = true
		end
    
	end

	--Trigger the update of the list.
	raiseEvent("targets updated")

	--Update the gui.
	ataxia_Update_RoomContents()

end

function ataxia_Update_RoomContents() 
  if ataxia.usegui == nil or ataxia.usegui == true then
    ataxiagui.roomConsole:clear()
    ataxiagui.roomConsole:setFontSize(7)
  elseif zgui then
    clearUserWindow("roomDenizensDisplay")
    zgui.showRoomInfo()
  end

	for id, denizen in pairs(ataxia.denizensHere) do
    if ataxia.usegui == nil or ataxia.usegui == true then
		  ataxiagui.roomConsole:cecho("\n<a_darkcyan>[<DodgerBlue>"..string.rep(" ", 6-string.len(id))..id.."<a_darkcyan>] <NavajoWhite>"..denizen:title())
    else
      cecho("roomDenizensDisplay", "\n<a_darkcyan>[<DodgerBlue>"..string.rep(" ", 6-string.len(id))..id.."<a_darkcyan>] <NavajoWhite>"..denizen:title())
    end
	end
end

function mob_isHere(what)
	local found = false
	for id, name in pairs(ataxia.denizensHere) do
		if id == what or name:title() == what:title() then
			found = true
			return true
		end
	end
	if not found then return false end
end