-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Ataxia-DownloadThis > Ataxia > System-related > Curing Stuff > Priority-related > Swaps > Class Specific

function prioritySwap_psionBleedChange(event, affliction)
  if not ataxia.prioritySwaps then ataxia_resetSwaps() end

  if not ataxia.prioritySwaps.psionBleed.active then return end
  if event == "aff gained" then
    if affed("haemophilia") and ataxia.vitals.bleed >= 125 and ataxia_getPrio("haemophilia") > 2 then
      ataxia_setAffPrio("haemophilia", 2)
    end
  end
end

function prioritySwap_psionBleedReturn(event, affliction)
  if not ataxia.prioritySwaps then ataxia_resetSwaps() end
  if not ataxia.prioritySwaps.psionBleed.active then return end
  if event == "aff cured" then
 		if affliction == "haemophilia" and ataxia_getPrio("haemophilia") ~= ataxia_defaultPrioAff("haemopilia") then
			ataxia_restorePrio("haemophilia")
		end 
  end
end
registerAnonymousEventHandler("aff gained", "prioritySwap_psionBleedChange")
registerAnonymousEventHandler("aff cured", "prioritySwap_psionBleedReturn")


function prioritySwap_magiSalveChange(event, affliction)
  if not ataxia.prioritySwaps then ataxia_resetSwaps() end
  if not ataxia.prioritySwaps.magi.active then return end
	if event == "aff gained" then
		if affliction == "dehydrated" or (affliction == "burning" and affed("dehydrated")) and ataxia_getPrio("dehydrated") > 1 then
			send("curing priority burning 1", false)
		elseif affliction == "hypothermia" then
			send("curing priority shivering 20;curing priority frozen 20",false)
		end
		
		if affed("frozen") or affed("shivering") and ataxia_getPrio("frozen") ~= 2 then
			send("curing priority frozen 2 shivering 2;curing priority defence insulation 2",false)
		end
	end
end

function prioritySwap_magiSalveReturn(event, affliction)
  if not ataxia.prioritySwaps then ataxia_resetSwaps() end
  if not ataxia.prioritySwaps.magi.active then return end
	if event == "aff cured" then
		if affliction == "hypothermia" then
      if affed("frozen") or affed("shivering") and ataxia_getPrio("frozen") ~= 2 then
				send("curing priority frozen 2 shivering 2;curing priority defence insulation 2",false)
      else
        if ataxia_getPrio("frozen") ~= ataxia_defaultPrioAff("frozen") then
          ataxia_restorePrio("frozen")
        end
        if ataxia_getPrio("shivering") ~= ataxia_defaultPrioAff("shivering") then
          ataxia_restorePrio("shivering")
          send("curing priority defence insulation 20",false)
        end
      end
    elseif affliction == "dehydrated" then
      if ataxia_getPrio("burning") ~= ataxia_getPrio("burning") then
				ataxia_Echo("Dehydrate cured; removing all burn stacks.")
				if ataxia.afflictions.burning then ataxia.afflictions.burning = 1 end
        ataxia_restorePrio("burning")
      end
    end
	end
end
registerAnonymousEventHandler("aff gained", "prioritySwap_magiSalveChange")
registerAnonymousEventHandler("aff cured", "prioritySwap_magiSalveReturn")



--[ Scald stuff ]--
-------------------
function prioritySwap_scaldTimeflux(event, affliction)
  if not ataxia.prioritySwaps then ataxia_resetSwaps() end
	if event == "aff gained" and affliction == "timeflux" then
		if ataxia_getPrio("scalded") < 26 and affed("timeflux") then
			send("curing priority scalded 26")
		end
	end
end

function prioritySwap_restoreScald(event, affliction)
  if not ataxia.prioritySwaps then ataxia_resetSwaps() end
	if event == "aff cured" and affliction == "timeflux" then
		if ataxia_getPrio("scalded") ~= ataxia_defaultPrioAff("scalded") then
			ataxia_restorePrio("scalded")
		end
	end
end
registerAnonymousEventHandler("aff gained", "prioritySwap_scaldTimeflux")
registerAnonymousEventHandler("aff cured", "prioritySwap_restoreScald")