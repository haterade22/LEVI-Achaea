-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Levi  Scripts > Leviticus > MONK > SHIKUDO > DISPTACH GROUP


function dispatch_base_attackGROUP()

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

if ataxia.vitals.class >= 50 and tAffs.slickness and tAffs.impatience and tAffs.anorexia then go_cripple = true else go_cripple = false end

if (tAffs.paralysis or tAffs.weariness or tAffs.lethargy or tAffs.asthma) and not tAffs.impatience then need_impatience = true else need_impatience = false end

if tAffs.impatience and not battered then need_batter = true else need_batter = false end

   
if tAffs.shield then shistick[1] = "shatter"

end

 if tAffs.prone and tLimbs.H >= 100 and tAffs.crushedthroat then
shikick = "dispatch"
end



  if (shistick[1] == "sweep" or shistick[1] == "shatter") then
  
  atk = atk.."wield staff489282;dismount;assess "..target..";combo "..target.." "..shistick[1].." "..shikick
 
 elseif need_impatience then
 atk = atk.."mind impatience "..target
 
 elseif need_batter then
  atk = atk.."mind batter "..target
 
 
 
elseif


shikick == "dispatch" then
  
  atk = atk.."wield staff489282;dismount;assess "..target..";incapacitate "..target.." "..form[1]

elseif shikick == "none" then

  atk = atk.."wield staff489282;dismount;assess "..target..";combo "..target.." "..shistick[1].." "..shistick[2]


  
 else

atk = atk.."wield staff489282;dismount;assess "..target..";combo "..target.." "..shikick.." "..shistick[1].." "..shistick[2]
 
end
 
if ataxia.vitals.form ~= form[1] then

send("cq all;transition to the "..form[1].." form")


elseif table.contains(ataxia.playersHere, target) then

if not ataxia.settings.paused and not ataxia_needLockBreak() and not ataxia.afflictions.stupidity then

if go_cripple then
send("queue addclear free kai cripple "..target)
else

send("queue addclear free "..atk)


end
end
end
end