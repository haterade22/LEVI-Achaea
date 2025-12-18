-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Ataxia-DownloadThis > Ataxia > Misc Scripts > Queue Scanning

function queue_Scan(stuff)
	instillAff = instillAff or "none"
  ataxiaTemp.hitCount = 0
	moonAff = false
  lastLimbAttack = nil
	local queueStuff = stuff
	local smallStuff = stuff:lower()
	deleteFull()
  enableTrigger("Affs Post Queue - Gated")
	
	if ataxia_isClass("monk") then
    enableTrigger("3rd Person Shikudo")
    if smallStuff:find("combo") then
      --monk_checkCombo(smallStuff)
      shikudo_findCombo(smallStuff)
    end
	end
	
	if ataxiaTemp.butchering then
		table.remove(ataxiaTemp.toButcher, 1)
		if ataxiaTemp.toButcher[1] then
			send("queue addclear free butcher "..ataxiaTemp.toButcher[1].." for reagent",false)
			ataxiaEcho(#ataxiaTemp.toButcher.." corpses left to butcher.")
		else
			ataxiaEcho("Butchering is complete!")
			ataxiaTemp.butchering = nil
		end
	end
  
  if smallStuff:find("trace") and ataxia_isClass("Pariah") then
    tempLastLogograph = smallStuff:match("trace (%w+)")
    tempTimer(0.3, [[ tempLastLogograph = nil ]] )
    if not smallStuff:find("swarm") then
      noSwarm = true
    else
      noSwarm = false
    end
  end
  
  if smallStuff:find("overcharge") then
    sylvan_overcharge = true
  end
  
	if smallStuff:find("moon") then
		local moons = {"stupidity", "masochism", "hallucinations", "hypersomnia", "confusion", "epilepsy","claustrophobia", "agoraphobia"}
		for _, aff in pairs(moons) do
			if smallStuff:find(aff) then
				moonAff = aff
				break
			end
		end
	end
	
	if ataxia_isClass("bard") then
    if smallStuff:find(ataxia.bardStuff.instrument) then
		  bardNeedRapierWield = true
    end
    if smallStuff:find("percussia") then
      ataxiaTemp.percussiaTiming = smallStuff:match("play percussia (%d+)")
    end
	end
	
	if smallStuff:find("curse") and not ataxiaBasher.enabled then
		local tar, curseAff = smallStuff:match("curse (%w+) (%w+)")
		ataxiaTemp.curse = curseConvert(curseAff)
	elseif smallStuff:find("curse") and ataxiaBasher.enabled then
		ataxiaTemp.canJinx = true
	elseif smallStuff:find("jinx") and ataxiaBasher.enabled then
		ataxiaTemp.canJinx = false
	end
	if smallStuff:find("blight") then
		local tar, curseAff = smallStuff:match("curse (%w+) (%w+)")
		ataxiaTemp.curse = curseConvert(curseAff)
	end
	if smallStuff:find("coagulation") then
		ataxiaTemp.coagulateAff = smallStuff:match("coagulation (%w+)")
	end
	if smallStuff:find("swiftcurse") then
		ataxiaTemp.swiftcurse = true
	else
		ataxiaTemp.swiftcurse = false
	end
	
	if smallStuff:find("deadeyes") and not ataxiaBasher.enabled then
		local tar, done, dtwo = smallStuff:match("deadeyes (%w+) (%w+) (%w+)")
		ataxiaTemp.deadeyesOne = curseConvert(done)
		ataxiaTemp.deadeyesTwo = curseConvert(dtwo)
	end
  
  if smallStuff:find("imbibe") then
    local imb = smallStuff:match("imbibe (%w+)")
    ataxiaTemp.imbibeAff = venom_to_aff(imb)
  end
	
	if smallStuff:find("truewrack") then
		local tar, t1, t2 = smallStuff:match("truewrack (%w+) (%w+) (%w+)")
		ataxiaTemp.truewrackOne = t1
		ataxiaTemp.truewrackTwo = t2
	elseif smallStuff:find("wrack") then
		local tar, aff = smallStuff:match("wrack (%w+) (%w+)")
		ataxiaTemp.wrackAff = aff
	end
	
	if smallStuff:find("suggest") then
		local tar, suggest = smallStuff:match("suggest (%w+) (%w+)")
		ataxiaTemp.suggestAff = suggest
	end
	
	if smallStuff:find("sketch") and runeTarget then
		if smallStuff:find("jera") then
			send("queue addclear free sketch berkana on "..runeTarget,false)
		elseif smallStuff:find("berkana") then
			send("queue addclear free sketch algiz on "..runeTarget,false)
		else
			runeTarget = nil
			ataxia_Echo("Rune sketching complete.")
		end
	end
	
	if ataxiaTemp.propagating then
		local part, prop = smallStuff:match("propagate (%w+) with (%w+)")
		ataxiaTemp.currentProps[part] = prop
		ataxia_nextPropagation()
	end
	
	if ataxiaTemp.doRepeat then
		send("queue addclear free "..ataxiaTemp.doRepeat)
	end
	
	if ataxiaTemp.repeatOffence and not ataxiaTemp.doRepeat then
		enableTrigger("Repeat Offence")
	end
end

function rTabSize(tab)
	local size = 0
	for i,v in pairs(tab) do
		size = size + 1
	end
	return size
end