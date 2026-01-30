--[[mudlet
type: script
name: Engaged/Disengage
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
]]--

--[[mudlet
type: script
name: Engaged/Disengage
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
]]--

autoBashRotation = autoBashRotation or false

function toggleAutoBashRotation()
  autoBashRotation = not autoBashRotation
  if autoBashRotation then
    ataxiaEcho("Auto bash rotation ENABLED")
  else
    ataxiaEcho("Auto bash rotation DISABLED")
  end
end

-- Auto-move with arrival verification and retry
function autoMoveAndBash(destinationRoom, expectedArea, travelTime)
  expandAlias("goto " .. destinationRoom)
  tempTimer(travelTime, function()
    if gmcp.Room.Info.area == expectedArea then
      ataxiaBasher_areabash()
    else
      -- Retry once
      ataxiaEcho("Did not reach " .. expectedArea .. ", retrying...")
      expandAlias("goto " .. destinationRoom)
      tempTimer(travelTime, function()
        if gmcp.Room.Info.area == expectedArea then
          ataxiaBasher_areabash()
        else
          ataxiaEcho("Failed to reach " .. expectedArea .. " after retry.")
        end
      end)
    end
  end)
end

-- Register to check whenever room players update
registerAnonymousEventHandler("gmcp.Room.Players", "checkForNaytorlin")

function basher_disengaged()
	disableTimer("Clear Bashing Console")
	disableTrigger("Denizen Attacks / Misc Lines")
	local times = stopStopWatch(bashWatcher)
	times = string.format("%2.2f", (times/60))

	ataxia_saveSettings(false)
	ataxiaEcho("Bashing finished. Started at ("..getCurExp.." / "..getCurGold.."g) and bashed for "..times.." minutes. ")
	ataxiaBasher_alert("Normal")

	--switchTarget("Nothing")
	
	if gmcp.Char.Status.class == "Bard" then
		send("wield rapier shield",false)
		if ataxia.bardStuff.ariaBash then
			send("curing priority defence aria reset",false)
			
			if ataxiaTemp.deafnessToggle then
				send("curing priority defence deafness 25",false)
				ataxiaTemp.deafnessToggle = nil
			end
		end
  end
  
  if string.find(ataxiaTemp.class, "fire") and ataxia_getPrio("burning") == 26 then
    send("curing priority burning 8",false)
  end  
  
  if ataxia.usegui or ataxia.usegui == nil then
    ataxiagui.basherBar:hide()
  end
	ataxiaTemp.basherRooms = nil
	autoHarvesting = false
  autoExtracting = false
  
if gmcp.Room.Info.area == "Annwyn" then
expandAlias("goto 17435")
end

if gmcp.Room.Info.area == "Annwyn" then
clearedannwyn = true
tempTimer(190,[[clearedannwyn = false]])
elseif gmcp.Room.Info.area == "Moghedu" then
clearedmog = true
tempTimer(180,[[clearedmog = false]])
elseif gmcp.Room.Info.area == "the Azdun Catacombs" then
clearedcatacombs = true
tempTimer(180,[[clearedcatacombs = false]])
elseif gmcp.Room.Info.area == "Tir Murann" then
clearedtir = true
tempTimer(240,[[clearedtir = false]])
elseif gmcp.Room.Info.area == "Quartz Peak" then
clearedquartz = true
tempTimer(180,[[clearedquartz = false]])
elseif gmcp.Room.Info.area == "the Den of the Quisalis" then
clearedquisalis = true
tempTimer(180,[[clearedquisalis = false]])
end


--Auto Move to New Area Stuff
if autoBashRotation then
  if gmcp.Room.Info.area == "Moghedu" and (clearedcatacombs == false or clearedcatacombs == nil) then
    autoMoveAndBash("Azdun Catacombs", "the Azdun Catacombs", 15)
  end

  if gmcp.Room.Info.area == "the Azdun Catacombs" and (clearedtir == false or clearedtir == nil) then
    autoMoveAndBash("21552", "Tir Murann", 10)
  end

  if gmcp.Room.Info.area == "Tir Murann" and (clearedquisalis == false or clearedquisalis == nil) then
    autoMoveAndBash("27338", "the Den of the Quisalis", 20)
  end

  if gmcp.Room.Info.area == "the Den of the Quisalis" and (clearedquartz == false or clearedquartz == nil) then
    autoMoveAndBash("20822", "Quartz Peak", 10)
  end

  if gmcp.Room.Info.area == "Quartz Peak" and (clearedmog == false or clearedmog == nil) then
    autoMoveAndBash("Moghedu", "Moghedu", 12)
  end
  end
end
function basher_engaged()
  if zgui then
    zgui.bwindow.console:clear()
  else
    ataxiagui.bashConsole:clear()
  end
	enableTrigger("Denizen Attacks / Misc Lines")
	enableTrigger("Gold Dropped")
	enableTimer("Clear Bashing Console")
	bashWatcher = bashWatcher or createStopWatch()
	startStopWatch(bashWatcher)
	ataxiaBasher.shielded = false
  
  --Lock Boss Rooms
  lockRoom(32789, true) --Azdun Cata
  lockRoom(37176, true) --Azdun Cata
  lockRoom(37312, true) --Azdun Cata
  lockRoom(8274, true) -- Annwyn Sihde King/Queen
  lockRoom(41018,true)  --Mog
  lockRoom(18678, true)-- Annwyn UnSidhe King\Queen
  lockRoom(9892, true) -- MOG 7 Knight Room
  lockRoom(27663, true) --Den of Qualisis - Grandmaster
  lockRoom(25315, true) -- Den of Qualisus Nishnatoba
  lockRoom(28221, true) -- Den of Qualisus - Enormous FuckHead
  lockRoom(21143, true) -- Quartz Peak 
  lockRoom(33, true) --MOG
  lockRoom(27580, true) -- Gil Den
  guardianofmogcunts = false

	ataxia_saveSettings(false)
	getCurExp = gmcp.Char.Status.level
	getCurGold = gmcp.Char.Status.gold
	if not autoHarvesting and not autoExtracting then
		search_targets()
	end
	send("config mapshow off")
  
  if gmcp.Room.Info.area == "Moghedu" then
    send("say Tulahuar")
  end
  send("drop lily;drop lily;drop lily")
  if gmcp.Char.Status.class == "Pariah" then
    --sendAll("epitaph focus serpent nest bear scarab jackal serpent", "crux let me",false)
    send("epitaph focus serpent nest scales skein scarab jackal serpent;crux let me",false)
    send("unwield left;unwield right;wield right shield")
	elseif ataxia_isClass("Bard") then
    send("remove lyre;wield left lyre")
    tempTimer(.1, [[send("performance end")]])
    tempTimer(.2, [[send("compose gusheh sonata scherzo maqam prelude")]])
    tempTimer(1, [[send("tempo allegro")]])
    
		bardNeedRapierWield = false
		
		--sonata maqam prelude scherzo
  elseif gmcp.Char.Status.class == "Blue Dragon" or gmcp.Char.Status.class == "Golden Dragon" or gmcp.Char.Status.class == "Silver Dragon" or gmcp.Char.Status.class == "Green Dragon" or gmcp.Char.Status.class == "Red Dragon" then
    send("unwield left;unwield right;wield left fang;wield right shield")
  elseif gmcp.Char.Status.class == "Runewarden" then
    if gmcp.Char.Vitals.charstats[3] == "Spec: Dual Cutting" then
      send("unwield left;unwield right;wield left scimitar405398;wield right scimitar405403")
    elseif gmcp.Char.Vitals.charstats[3] == "Spec: Dual Blunt" then
      send("unwield left;unwield right;wield left morningstar511732;wield right morningstar511735")
    elseif gmcp.Char.Vitals.charstats[3] == "Spec: Sword and Shield" then
      send("unwield left;unwield right;wield left longsword;wield right shield")
    elseif gmcp.Char.Vitals.charstats[3] == "Spec: Two Handed" then
      send("unwield left;unwield right;wield bastard") 
    end
    elseif gmcp.Char.Status.class == "Infernal" then
    if gmcp.Char.Vitals.charstats[4] == "Spec: Dual Cutting" then
      send("unwield left;unwield right;wield left scimitar405398;wield right scimitar405403")
    elseif gmcp.Char.Vitals.charstats[4] == "Spec: Dual Blunt" then
      send("unwield left;unwield right;wield left morningstar511732;wield right morningstar511735")
    elseif gmcp.Char.Vitals.charstats[4] == "Spec: Sword and Shield" then
      send("unwield left;unwield right;wield left longsword;wield right shield")
    elseif gmcp.Char.Vitals.charstats[4] == "Spec: Two Handed" then
      send("unwield left;unwield right;wield warhammer") 
    end
  elseif gmcp.Char.Status.class == "Serpent" then
    send("unwield left;unwield right;wield left lash;wield right shield")
  elseif gmcp.Char.Status.class == "Shaman" then
    send("unwield left;unwield right;wield right shield")
    if ataxiaTemp.me == "Leviticus" then
    shaman.spiritlore.bashType = shaman.spiritlore.bashType
    end
  elseif gmcp.Char.Status.class == "Magi" then
    send("unwield left;unwield right;wield left staff569815;wield right shield")
  elseif gmcp.Char.Status.class == "Infernal" then
    send("queue add hyena recall;queue add order hyena follow me")
  elseif gmcp.Char.Status.class == "Psion" then
    send("unwield left;unwield right;wield right shield")
  elseif gmcp.Char.Status.class == "Blademaster" then
    send("unwield left;unwield right")
  elseif gmcp.Char.Status.class == "Depthswalker" then
    send("unwield left;unwield right;wield right shield;wield left scythe")
  elseif gmcp.Char.Status.class == "Apostate" then
    send("unwield left;unwield right;wield right shield")
  elseif gmcp.Char.Status.class == "Monk" then
    if ataxia.settings.crushbash then
      if gmcp.Char.Vitals.charstats[4]:find("Stance") == 1 then
        if ataxia.vitals.stance ~= "Dragon" then
          send("drs")
        end
      elseif gmcp.Char.Vitals.charstats[4]:find("Form") == 1 then
        if ataxia.vitals.form ~= "Rain" then
          send("adopt rain form")
        end
      else
        if ataxia.vitals.form ~= "Rain" then
          send("wield staff;adopt rain form")
        end
      end
    elseif gmcp.Char.Vitals.charstats[4]:find("Stance") == 1 then
      if ataxia.vitals.stance ~= "Scorpion" then
        send("scs")
      end
    else
      if ataxia.vitals.form ~= "Rain" or ataxia.vitals.form ~= "Oak" or ataxia.vitals.form ~= "Willow" then
        send("wield staff489282;adopt rain form")
      end
    end    
	elseif ataxia_isClass("Apostate") then
		send("summon daegger")	
	end
  
  if string.find(ataxiaTemp.class, "fire") and ataxia_getPrio("burning") ~= 26 then
    send("curing priority burning 26;manifest torch",false)
  end  
end

registerAnonymousEventHandler("basher enabled", "basher_engaged")
registerAnonymousEventHandler("basher disabled", "basher_disengaged")