function systemDefup(profile)
	local cur = ataxia.settings.defences.current
	local command = ""
	if profile == "none" then
		ataxia.settings.defences.current = ""
		if cur ~= "" then
			sendAll("curing priority defence list reset",false)
		end
		ataxiaEcho("Switching to empty defence profile.")
	else
		if ataxia.settings.defences.defup[profile] then
			ataxia.settings.defences.current = profile
			cur = ataxia.settings.defences.current
			ataxiaEcho("Deffing up in the "..profile.." profile.")
      command = "curing priority defence "
			for def, val in pairs(ataxia.settings.defences.defup[cur]) do
				command = command..def.." 25 "
			end

			send(command,false)
	
			if deffingFailsafe then killTimer(deffingFailsafe) end
			deffingFailsafe = tempTimer(60, [[defupFailsafe(); deffingFailsafe = nil]])
			
			checkSSCErrors()
			
		else
			ataxiaEcho("That is not a valid defup profile!")
		end
	end
end

function defupFailsafe()
	local cur = ataxia.settings.defences.current
	local command = "curing priority defence "

	if deffingFailsafe then killTimer(deffingFailsafe) end

	for def, val in pairs(ataxia.settings.defences.defup[cur]) do
		if not ataxia.settings.defences.keepup[cur][def] then
			command = command..def.." reset "
		end
	end
	send(command,false)
end

function checkSSCErrors()
	local cur = ataxia.settings.defences.current
	local defl = ataxia.settings.defences.defup[cur]

	if defl.deathsight and not ataxia.settings.have.deathsight and not ataxia.defences.deathsight then
		if defl.lifevision and ataxia_isClass("occultist") then
			send("astralvision",false)
		else
			send("deathsight;lifevision",false)
		end
	end
	
	if ataxia_isClass("magi") or ataxia_isClass("sylvan") then
		send("simultaneity",false)     
	elseif ataxia_isClass("Apostate") and defl.demonarmour then
		sendAll("summon baalzadeen", "queue addclear free mask; queue add free demon syphon",false)
  elseif ataxia_isClass("Alchemist") then
    send("secure mask",false)
	elseif ataxia_isClass("priest") then
		sendAll("recite benediction me", "perform bliss me",false)
  elseif ataxia_isClass("pariah") then
    send("crux let me",false)
  elseif ataxia_isClass("druid") and not isMorphed("hydra") then
    send("morph hydra",false)
  elseif ataxia_isClass("sentinel") and not isMorphed("jaguar") then
    send("morph jaguar",false)
  else
  send("queue add free shroud;queue add free lifevision")
	end

	if defl.regeneration and not ataxia.defences.regeneration and defl.boostedregeneration then
		send("regeneration on",false)
	end
end

function ataxia_nextPropagation()
	if not ataxiaTemp.propagating then return end
	if not ataxia.defences.viridian then
		ataxiaEcho("Need to be in viridian to be able to propagate!")
		ataxiaTemp.propagating = false
	end
	
	local found = false
	for limb, herb in pairs(ataxia.sylvanStuff.propagateList) do
		if not ataxiaTemp.currentProps[limb] and herb ~= false then
			found = true
			send("queue addclear class propagate "..limb.." with "..herb,false)
			break
		end
	end
	if not found then
		ataxiaTemp.propagating = false
		ataxiaEcho("Propagations are now all set!")
	end
end