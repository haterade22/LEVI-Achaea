function dispatch_base_attack()

formswapdispatch()
local xmute = math.ceil(ataxia.vitals.maxhp * 0.80)
	local mpl = (ataxia.vitals.mp - (ataxia.vitals.maxmp * 0.30))
	local hpl = (xmute - ataxia.vitals.hp)
	local tomute = 0

	if hpl > 1 then
		tomute = (hpl < mpl and hpl or mpl)
		if tomute > 100 then
			command = command.."transmute "..tomute..ataxia.settings.separator
		end
	end

local atk = combatQueue()
   
if tAffs.shield then shistick[1] = "shatter"

end

 if tAffs.prone and tLimbs.H >= 100 and tAffs.crushedthroat then
shikick = "dispatch"
end



  if (shistick[1] == "sweep" or shistick[2] == "sweep" or shistick[1] == "shatter") then
  
  atk = atk.."wield staff489282;dismount;assess "..target..";combo "..target.." sweep "..shikick
 
elseif

 llKUR and rlKUR and hNEED and ataxia.vitals.form ~= "Gaital" then
atk = atk.."adopt gaital form"

elseif
shikick == "dispatch" then
  
  atk = atk.."wield staff489282;dismount;assess "..target..";incapacitate "..target.." "..form[1]

elseif shikick == "none" then

  atk = atk.."wield staff489282;dismount;assess "..target..";combo "..target.." "..shistick[1].." "..shistick[2]

elseif ataxia.vitals.form == "Oak" and raRUK and laRUK and rlKUR and llKUR then

  atk = atk.."wield staff489282;dismount;assess "..target..";combo "..target.." "..shikick.." "..shistick[1]
  
elseif ataxia.vitals.form == "Gaital" and rlKUR and llKUR and not hNEED then

  atk = atk.."wield staff489282;dismount;assess "..target..";combo "..target.." "..shikick.." "..shistick[1]

 else

atk = atk.."wield staff489282;dismount;assess "..target..";combo "..target.." "..shikick.." "..shistick[1].." "..shistick[2]
 
end
 
if ataxia.vitals.form ~= form[1] then

send("cq all;transition to the "..form[1].." form")


elseif table.contains(ataxia.playersHere, target) then

if not ataxia.settings.paused and not ataxia_needLockBreak() and not ataxia.afflictions.stupidity then


send("queue addclear free "..atk)



end
end
end