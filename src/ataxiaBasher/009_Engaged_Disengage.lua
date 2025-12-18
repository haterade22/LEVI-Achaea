-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Ataxia-DownloadThis > Basher > Bashing > genRunning > Engaged/Disengage

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
expandAlias("goto 18280")
end

if gmcp.Room.Info.area == "Annwyn" then
clearedannwyn = true
tempTimer(1900,[[clearedannwyn = false]])
elseif gmcp.Room.Info.area == "Moghedu" then
clearedmog = true
tempTimer(1800,[[clearedmog = false]])
elseif gmcp.Room.Info.area == "the Azdun Catacombs" then
clearedcatacombs = true
tempTimer(1800,[[clearedcatacombs = false]])
elseif gmcp.Room.Info.area == "Tir Murann" then
clearedtir = true
tempTimer(2400,[[clearedtir = false]])
elseif gmcp.Room.Info.area == "Quartz Peak" then
clearedquartz = true
tempTimer(1800,[[clearedquartz = false]])
elseif gmcp.Room.Info.area == "the Den of the Quisalis" then
clearedquisalis = true
tempTimer(1800,[[clearedqusalis = false]])
end


--Auto Move to New Area Stuff

if gmcp.Room.Info.area == "the Azdun Catacombs" and clearedmog == false then
--expandAlias("goto Moghedu")
--tempTimer(20,[[ataxiaBasher_areabash()]])
end
if gmcp.Room.Info.area == "The Digsite of Husks" and clearedtir == false then
--expandAlias("goto 21552")
--tempTimer(14,[[ataxiaBasher_areabash()]])
end
if gmcp.Room.Info.area == "Tir Murann" and clearedquartz == false then
--expandAlias("goto 20822")
--tempTimer(10,[[ataxiaBasher_areabash()]])
end

if gmcp.Room.Info.area == "Quartz Peak" and clearedquisalis == false then
--expandAlias("goto 27338")
--tempTimer(10,[[ataxiaBasher_areabash()]])
end

if gmcp.Room.Info.area == "the Den of the Quisalis" and clearedmog == false then
--expandAlias("goto Moghedu")
--tempTimer(20,[[ataxiaBasher_areabash()]])
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
  
  lockRoom(18678, true)-- Annwyn UnSidhe King\Queen
  lockRoom(9892, true) -- MOG 7 Knight Room
  lockRoom(27663, true) --Den of Qualisis - Grandmaster
  lockRoom(25315, true) -- Den of Qualisus Nishnatoba
  lockRoom(28221, true) -- Den of Qualisus - Enormous FuckHead
  
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
    shaman.spiritlore.bashType = "swiftcurse"
    end
  elseif gmcp.Char.Status.class == "Magi" then
    send("unwield left;unwield right;wield left staff569815;wield right shield")
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