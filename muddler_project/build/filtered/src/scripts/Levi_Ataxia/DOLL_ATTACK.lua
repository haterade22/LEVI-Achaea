function attackdol()
ataxia_lockBreak()
local atk = combatQueue()

ataxiaTemp.dollFashions = ataxiaTemp.dollFashions or 0
if checkAffList({"anorexia", "asthma", "slickness", "bloodfire"},3) then
	local	softlock = true
  else
  softlock = false
	
	end
	if softlock and checkAffList({"impatience", "sandfever"},1) then
	local	hardlock = true
   hardlock = false
	

	end

	if hardlock and haveAff("paralysis") then
	local	truelock = true
 truelock = false
	
	end


rending = true

if ataxiaTemp.dollFashions and ataxiaTemp.dollFashions > 20 and not tAffs.paralysis and curses[1] == "paralysis" then
 doll_para = true
else doll_para = false
end

if ataxia.afflictions.clumsiness and ataxiaTemp.dollFashions <= 20 then
 doll_fashion = true
else doll_fashion = false
end

if ataxiaTemp.dollFashions > 0 and rending and tAffs.manaleech then
need_soulrend = true
else need_soulrend = false
end

if ataxiaTemp.dollFashions > 0 and rending and manapercent and manapercent <= 76 then
need_soulrend2 = true
else need_soulrend2 = false
end



if getTzantzaAffs() >= 5 and ataxiaTemp.dollFashions > 30 then
 bind_tzantza = true 
else bind_tzantza = false
end


if tAffs.paralysis and tAffs.asthma and tAffs.impatience and 
not tAffs.weariness and getLockingAffliction() == "weariness" then
 need_blight = true
else need_blight = false

end

if shaman.spiritisbound("marak") and getTzantzaAffs() >= 5 and ataxiaTemp.canJinx then
jinx_tzantza = true
else
jinx_tzantza = false
end

if ataxiaTemp.canJinx and not tAffs.impatience and not tAffs.anorexia and tAffs.slickness then
jinx_anoimp = true
else jinx_anoimp = false
end

if ataxiaTemp.canJinx and not tAffs.impatience and not tAffs.asthma then
jinx_impasthma = true
else jinx_impasthma = false
end


if ataxiaTemp.canJinx and tAffs.paralysis and tAffs.asthma and not tAffs.impatience and not tAffs.stupidity then
jinx_impstu = true
else jinx_impstu = false
end



if ataxiaTemp.canJinx and not tAffs.paralysis and not tAffs.haemophilia then
jinx_haepar = true
else jinx_haepar = false
end



if ataxiaTemp.canJinx and not tAffs.asthma and not tAffs.manaleech and rending then
jinx_astmana = true
else jinx_astmana = false
end


if truelock and ataxiaTemp.canJinx then
 need_prone = true
else need_prone = false
end

if ataxiaTemp.dollFashions > 20 and tAffs.paralysis and tAffs.impatience and tAffs.asthma and tAffs[getLockingAffliction()] and not tAffs.anorexia and not tAffs.slickness then
    need_imbibe = true
    else need_imbibe = false
end

if ataxiaTemp.dollFashions > 20 and not tBals.tree and tAffs[getLockingAffliction()] and not tAffs.asthma and not tAffs.slickness  and tAffs.impatience then
    need_imbibe2 = true
    else need_imbibe2 = false
end

if ataxiaTemp.dollFashions > 20 and tAffs[getLockingAffliction()] and not tAffs.asthma and not tAffs.slickness and tAffs.paralysis and tAffs.impatience then
    need_imbibe2 = true
    else need_imbibe2 = false
end

if not tBals.tree and tAffs[getLockingAffliction()] and tAffs.haemophilia and tAffs.impatience and tAffs.asthma and tAffs.bleed >= 100 and not tAffs.anorexia and not tAffs.slickness then
   need_coagulate = true
    else need_coagulate = false
end

if not tBals.tree and tAffs[getLockingAffliction()] and tAffs.haemophilia and not tAffs.impatience and tAffs.asthma and tAffs.bleed >= 100 and not tAffs.paralysis and not tAffs.slickness then
   need_coagulate2 = true
    else need_coagulate2 = false
end

if not tAffs.haemophilia and tAffs.paralysis and not ataxiaTemp.bloodlet then
    need_bloodlet = true
    else need_bloodlet = false
    end
   
if shaman.spiritisbound("syvis") and not ataxiaTemp.relapse and not tAffs[getLockingAffliction()] and getLockingAffliction() ~= "weariness" and getLockingAffliction() ~= "confusion" and getLockingAffliction() ~= "plague" then
   need_relapse = true 
    else need_relapse = false
    end




if tAffs.curseward then

    atk = atk.."wield shield doll {"..target.."};vodun status;curse "..target.." breach"
elseif jinx_tzantza then
   atk = atk.."stand;wield shield doll {"..target.."};vodun status;jinx amnesia tzantza "..target


elseif need_imbibe then
    atk = atk.."wield shield doll {"..target.."};vodun status;curse "..target.." anorexia invoke soulscourge vodun imbibe gecko"

elseif need_imbibe2 then
    atk = atk.."wield shield doll {"..target.."};vodun status;curse "..target.." asthma invoke soulscourge vodun imbibe gecko"


elseif bind_tzantza then
    atk = atk.."wield shield doll {"..target.."};vodun status;curse "..target.." tzantza invoke soulscourge vodun bind"

elseif need_coagulate then
    atk = atk.."wield shield doll {"..target.."};vodun status;curse "..target.." anorexia invoke coagulation slickness"

elseif need_coagulate2 then
    atk = atk.."wield shield doll {"..target.."};vodun status;curse "..target.." paralysis invoke coagulation slickness"

elseif jinx_anoimp then
   atk = atk.."stand;wield shield doll {"..target.."};vodun status;jinx anorexia impatience "..target
   
   elseif jinx_asthma then
   atk = atk.."stand;wield shield doll {"..target.."};vodun status;jinx impatience asthma "..target

   
elseif jinx_impstu then
   atk = atk.."stand;wield shield doll {"..target.."};vodun status;jinx impatience stupid "..target

elseif jinx_anostu then
   atk = atk.."stand;wield shield doll {"..target.."};vodun status;jinx anorexia stupid "..target

elseif jinx_clupar then
   atk = atk.."stand;wield shield doll {"..target.."};vodun status;jinx clumsy paralysis "..target

   elseif jinx_astmana then
   atk = atk.."stand;wield shield doll {"..target.."};vodun status;jinx asthma manaleech "..target

elseif jinx_astclu then
   atk = atk.."stand;wield shield doll {"..target.."};vodun status;jinx asthma clumsy "..target
elseif jinx_astwea then
   atk = atk.."stand;wield shield doll {"..target.."};vodun status;jinx asthma weariness "..target
elseif need_soulrend2 then
    atk = atk.."wield shield doll {"..target.."};vodun status;curse "..target.." "..curses[1].." invoke soulrend "..target
elseif need_soulrend then
    atk = atk.."wield shield doll {"..target.."};vodun status;curse "..target.." "..curses[1].." invoke soulrend "..target

elseif need_blight then
    
  atk = atk.."wield shield doll {"..target.."};vodun status;blight "..target.." weariness"



elseif need_bloodlet then
  atk = atk.."wield shield doll {"..target.."};vodun status;curse "..target.." "..curses[1].." invoke bloodlet "..target
elseif need_relapse then

  atk = atk.."wield shield doll {"..target.."};vodun status;curse "..target.." "..getLockingAffliction().." invoke relapse "..getLockingAffliction()

elseif doll_para then
    atk = atk.."wield shield doll {"..target.."};vodun status;vodun paralyse"
elseif doll_fashion then
   if tAffs.manaleech then

  atk = atk.."wield shield doll {"..target.."};vodun status;curse "..target.." breach invoke soulrend"
else


atk = atk.."wield shield doll {"..target.."};vodun status;fashion doll of "..target

end

elseif curseCharge > 1 then
    atk = atk.."wield shield doll {"..target.."};vodun status;swiftcurse "..target.." "..curses[1]
elseif curseCharge <= 1 then
   atk = atk.."wield shield doll {"..target.."};vodun status;swiftcurse"


elseif need_prone then
   atk = atk.."stand;wield shield doll {"..target.."};vodun status;jinx sleep sleep "..target

end


if not ataxia_needLockBreak() then
if not tzantzacurse then
send("queue addclear free "..atk)
elseif tzantzacurse then
send("none")

end
end
end