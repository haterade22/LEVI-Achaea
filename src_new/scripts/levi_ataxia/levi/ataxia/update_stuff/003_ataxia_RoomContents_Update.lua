--[[mudlet
type: script
name: ataxia_RoomContents_Update
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
- gmcp.Char.Items.List
- gmcp.Char.Items.Remove
- gmcp.Char.Items.Add
]]--

--[[mudlet
type: script
name: ataxia_RoomContents_Update
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
- gmcp.Char.Items.List
- gmcp.Char.Items.Remove
- gmcp.Char.Items.Add
]]--

function ataxia_RoomContents_Update(event)
	--Create the table if it's not already there.
   ataxiaBasher_invalidateStormhammer()
	ataxia.denizensHere = ataxia.denizensHere or {}
	atempDenizens = atempDenizens or {}
	waterGuards = waterGuards or {}
  if not gmcp.Char or not gmcp.Char.Items or not gmcp.Char.Items.List then return end
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
			-- attrib is a flag-SET string (m=monster, d=dead, t=takeable, x=should-not-be-targeted,
			-- loyal to city/player...), so test membership, not whole-string equality. Exclude x
			-- (protected/loyal NPCs -- attacking them draws aggro/bounties and the auto-learn block
			-- below would write them to the persistent targetList) and d (corpses). `not find("d")`
			-- supersedes the old exact `~= "mdt"`, which missed d/md/dt combos.
			elseif v.attrib and not v.attrib:find("x") and not v.attrib:find("d")
			   and v.attrib ~= "t" and v.icon ~= "guard" then
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
		end

		-- Auto-learn: when basher is active, add new denizens to this area's targetList.
		-- Keyed via ataxiaBasher_areaKey(), NOT gmcp's area: in Mnemosyne that pins to "" (the
		-- key the tower has always used), so the incurable-dementia boon reporting a hallucinated
		-- real area cannot scatter tower denizens into a genuine hunting list on disk -- and the
		-- lookup side (search_targets) agrees, so we still find things to attack.
		if ataxiaBasher.enabled and ataxiaBasher.autoLearn and gmcp.Room and gmcp.Room.Info then
			local area = ataxiaBasher_areaKey and ataxiaBasher_areaKey() or gmcp.Room.Info.area
			ataxiaBasher.targetList = ataxiaBasher.targetList or {}
			if not ataxiaBasher.targetList[area] then
				ataxiaBasher.targetList[area] = {}
			end
			for _, name in pairs(ataxia.denizensHere) do
				if not table.contains(ataxiaBasher.targetList[area], name)
				   and not ataxiaBasher_isOwnDenizen(name) then
					table.insert(ataxiaBasher.targetList[area], name)
				end
			end
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
    elseif gmcp.Char.Items.Remove.item.name == "a monolith sigil" then
      ataxiaTemp.monolith = false
		end		
		
	--Add the denizen.
	else
		-- Same flag-set membership as the List loop above: require attrib (nil-guard the List loop
		-- had but this Add path lacked), exclude x (loyal/protected) and d (dead -- the Add path
		-- never checked d before, so a corpse Added to the room became an attackable "denizen").
		if gmcp.Char.Items.Add.location == "room" and gmcp.Char.Items.Add.item.attrib
		   and not gmcp.Char.Items.Add.item.attrib:find("x") and not gmcp.Char.Items.Add.item.attrib:find("d")
		   and gmcp.Char.Items.Add.item.attrib ~= "t" and gmcp.Char.Items.Add.item.icon ~= "guard" then
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

	--Trigger the update of the list (debounced to coalesce rapid GMCP item changes).
	if not ataxiaTemp._targetsUpdatePending then
		ataxiaTemp._targetsUpdatePending = true
		tempTimer(0, function()
			ataxiaTemp._targetsUpdatePending = nil
			-- Reconcile the per-denizen combat-state table with the room (add newcomers,
			-- drop the departed/dead) before anyone reacts to "targets updated".
			if ataxiaBasher_dsSync then ataxiaBasher_dsSync() end
			raiseEvent("targets updated")
			ataxia_Update_RoomContents()
		end)
	end

end

function ataxia_Update_RoomContents() 
  if (ataxia.usegui == nil or ataxia.usegui == true) and ataxiagui.roomConsole then
    ataxiagui.roomConsole:clear()
    ataxiagui.roomConsole:setFontSize(7)
  elseif zgui then
    clearUserWindow("roomDenizensDisplay")
    zgui.showRoomInfo()
  end

	for id, denizen in pairs(ataxia.denizensHere) do
    if (ataxia.usegui == nil or ataxia.usegui == true) and ataxiagui.roomConsole then
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