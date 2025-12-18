-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Ataxia-DownloadThis > Ataxia > System-related > Curing Stuff > Aff gains/losses

function confirmedUnknownAff()
	if line:match("You feel your allergy to the sun going into temporary remission.")
		or line:match("Your insomnia has cleared up.")
		or line:match("Your insulating unguent dissolves as it ameliorates the extreme cold.")
		or line:match("You gasp as your fine-tuned reflexes disappear into a haze of confusion.") 
		or line:match("Your hearing is suddenly restored.") then
	else
		if ataxia.afflictions.unknown == nil then ataxia.afflictions.unknown = 0 end
		ataxia.afflictions.unknown = ataxia.afflictions.unknown + 1
		if ataxiaBasher and ataxiaBasher.enabled and ataxia.afflictions.unknown >= 2 and not sent_diagnose then
			send("queue addclear free diagnose", false)
			sent_diagnose = tempTimer(3, [[sent_diagnose = nil]])
		end
	end
end

function gotUnknownAff()
	if ataxia.vitals.hp == ataxia.vitals.maxhp and ataxia.vitals.mp == ataxia.vitals.maxmp then
		send("curing predict recklessness")
	elseif not ataxiaTemp.lokiCheck then
		tempLineTrigger(1, 1, [[confirmedUnknownAff()]])
	end
end

function affed(what)
	if ataxia.afflictions[what:lower()] then
		return true
	else
		return false
	end
end

function setStackAff(aff, num)
	local affs = {"horror", "pyre", "unweavingspirit", "unweavingmind", "unweavingbody", "temperedsanguine", "temperedcholeric", 
    "temperedmelancholic", "temperedphlegmatic", "pressure", "crackedribs", "torntendons", 
    "skullfractures", "wristfractures", "burning, burns,","crescendo",}
	local tow = ""
	for _, x in pairs(affs) do
		if aff:find(x) then
			tow = x
		end
	end
	
	if num then
		ataxia.afflictions[tow] = 0
	elseif tonumber( string.sub(aff, -2, -2) ) then
		ataxia.afflictions[tow] = tonumber(string.sub(aff, -2, -2))
	else
		ataxia.afflictions[tow] = 1
	end
end

function afflictionList()
	local affs = gmcp.Char.Afflictions.List
  local ignore = {"blindness", "deafness", "insomnia","deathsickness",}
 
	
 
	ataxia.afflictions = {}
	sent_diagnose = nil

	for _, affl in pairs(affs) do
		local aff = affl.name
		if not table.contains(ignore, aff:lower()) then
			if tonumber( string.sub(aff:lower(), -2, -2) ) then
				setStackAff(aff:lower())
			else
				ataxia.afflictions[aff:lower()] = true
				raiseEvent("aff gained", aff:lower())
			end
		end
  Algedonic.AffCount = Algedonic.Count_My_Affs() 
	end
  
  if ataxiaBasher.enabled then
    basher_needAction = true
  end
  if zgui then zgui.showAffs() end
end

function gotAff()
	local ignore = {"blindness", "deafness", "insomnia"}
	local aff = gmcp.Char.Afflictions.Add.name
	if not table.contains(ignore, aff) then
  	if tonumber( string.sub(aff, -2, -2) ) then
			setStackAff(aff)
		else
			ataxia.afflictions[aff:lower()] = true
      local parAff = "incoming_"..aff
      ataxia.afflictions[parAff] = nil
		end
	end

	if aff == "guilt" then
		send("curing focus off")
	elseif aff == "amnesia" then
		send("touch friends")
  elseif aff == "paralysis" then
   send("endure")
  elseif aff == "haemophilia" then
    sentinel_swaphaemophilia()
 elseif aff == "prone" and not ataxia.afflictions.aeon then
  --Smoke for Rebounding - Serverside doesn't put it up
    send("smoke malachite") 
  ---AUTO TUMBLER
  --If we have the below afflictions then tumble
    if ataxia.afflictions.damagedrightleg and ataxia.afflictions.damagedleftleg and ataxiaNDB_getClass(target) ~= "Blademaster" then
    getdirectionn()
    send("tumble " ..random_direction)
    elseif ataxia.afflictions.damagedrightleg and ataxia.afflictions.damagedleftleg and ataxiaNDB_getClass(target) == "Blademaster" then
    expandAlias("hh")
    elseif ataxia.afflictions.brokenrightarm and ataxia.afflictions.brokenleftarm then
    send("restore")    
    end
  --Sentinel Restore to Prevent Rift Lock
  --elseif aff == "brokenrightarm" or aff == "brokenleftarm" and ataxia.afflictions.prone and ataxiaNDB_getClass(target) == "Sentinel" then
    --send("restore")
  -- Sentinel Touch Shield to Prevent Rift Lock
  
  
  --Druid Nonsense
  elseif aff == "damagedrightarm" or aff == "damagedleftarm" and not ataxia.afflictions.prone and ataxiaNDB_getClass(target) == "Druid" then
    send("cq all;goto 11090")
    ataxia_boxEcho("EMBRACE DANGER NEED TO RUN", "goldenrod")
    ataxia_boxEcho("EMBRACE DANGER NEED TO RUN", "goldenrod")

  elseif aff == "entangled" and ataxiaNDB_getClass(target) == "Druid" then
    getdirectionn()
    send("apply mass to arms")
    send("curing queue insert 1 restoration to legs")
    ataxia_boxEcho("WE ARE PREAPPLYING", "yellow")
    send("tumble " ..random_direction)
   elseif aff == "damagedrightleg" or aff == "damagedleftleg" and ataxia.afflictions.prone and ataxiaNDB_getClass(target) == "Druid" then
    getdirectionn()
    send("tumble " ..random_direction)
    
  -- This is to prepare for DISEMBOWEL from /BM
	elseif aff == "internalbleeding" then
    tempTimer(2, [[send("curing queue insert 1 restoration to legs"), ataxia_boxEcho("WE ARE PREAPPLYING", "yellow")]])
    ataxia_boxEcho("PREPARE THINE ANUS FOR ENTRY", "a_darkred")
  -- Handle Blackout
	elseif aff == "blackout" then
  
		if ataxiaBasher.enabled and ataxiaBasher.treeblackout then
			send("touch tree")
		elseif type(target) == "string" and ataxiaNDB_getClass(target) == ("Runewarden" or "Infernal" or "Paladin") then
			tempTimer(2.5, [[send("curing predict impaled",false)]])
		end
	elseif aff == "prone" then
		if ataxiaBasher.enabled then
			send("queue prepend eqbal stand")
		end
	elseif aff == "corruption" then
		send("curing clotat 9999",false)
		ataxia_boxEcho("CORRUPTION ON US - MANUAL CLOT", "a_darkred")
	elseif (aff == "entangled" or aff == "webbed") then
    if ataxia_isClass("bard") then
		  send("queue addclear class recite haidar",false)
    elseif ataxia_isClass("pariah") then
      send("accursed reconstitute", false)
    end
  -- Handle Retardation or Aeon
  elseif aff == "aeon" and not ataxia.retardation then
    send("curing prioaff aeon")
    partyrelay = false
    retardationOn()
  elseif aff == "aeon" and ataxia.afflictions.asthma then
    send("curing prioaff asthma")
    partyrelay = false
  elseif aff == "impatience" and ataxiaNDB_getClass(target) == "Serpent" then
    myaeon = true
	end
  --Are we close to being locked where we need to hit our active ability?
	ataxia_lockBreak()
	raiseEvent("aff gained", aff)
  if zgui then zgui.showAffs() end

--If facing a specific class, call out priorities to ensure we are curing correctly
Algedonic.Prioritize()
-- Calulate Stacks (Kelp/Goldenseal/Bloodroot/etc)
Algedonic.Stack_My_Affs(true, aff)
end

function lostAff()
	local ignore = {"blindness", "deafness", "insomnia"}
	local aff = gmcp.Char.Afflictions.Remove

	if not table.contains(ignore, aff) then
  	if tonumber( string.sub(aff[1]:lower(), -2, -2) ) and tonumber( string.sub(aff[1]:lower(), -2, -2) ) == 1 then
			setStackAff(aff[1]:lower(), true)
		else
			ataxia.afflictions[aff[1]:lower()] = nil
		end
	end

	if aff[1] == "guilt" then
		send("curing focus on")
  elseif aff[1] == "voyria" or aff[1] == "latency" then
    stoplatency = false
	elseif aff[1] == "blackout" then
		if not ataxia.vitals.eq then
			send("curing predict disrupted",false)
		end
		send("allies",false)
	elseif aff[1] == "corruption" then
		send("curing clotat 180",false)
		ataxia_boxEcho("CORRUPTION IS GONE - SAFE", "white")
  elseif aff[1] == "brokenrightarm" or aff[1] == "brokenleftarm" then
    preventriftlock = false
  elseif aff[1] == "paralysis" then
    send("endure stop")
  elseif aff[1] == "haemophilia" or aff[1] == "flushings" then
    stopscourge = false
  elseif aff[1] == "aeon" and ataxia.retardation then
    retardationOff()
    myaeon = false
    partyrelay = true
  elseif aff[1] == "impatience" then
     myaeon = false
  elseif aff[1] == "impatience" and ataxia.prioritySwaps.impSnap and ataxia.prioritySwaps.impSnap.active then
	   ataxia_restorePrio("impatience")
     myaeon = false
  elseif aff[1] == "unweavingmind" then
    ataxia.afflictions.unweavingmind = 0
  elseif aff[1] == "unweavingbody" then
    ataxia.afflictions.unweavingbody = 0
  elseif aff[1] == "unweavingspirit" then
    ataxia.afflictions.unweavingspirit = 0
  elseif aff[1] == "crescendo" then
    ataxia.afflictions.crescendo = 0
  end
	
	raiseEvent("aff cured", aff[1])
  if zgui then zgui.showAffs() end
Algedonic.Prioritize()
Algedonic.Stack_My_Affs(false, aff)
end

registerAnonymousEventHandler("gmcp.Char.Afflictions.List", "afflictionList")
registerAnonymousEventHandler("gmcp.Char.Afflictions.Add", "gotAff")
registerAnonymousEventHandler("gmcp.Char.Afflictions.Remove", "lostAff")