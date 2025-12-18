-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Levi  Scripts > Leviticus > SHAMAN > DAMAGE ATTACK

function attackdamage()

local atk = combatQueue()
ataxia_lockBreak()



if getTzantzaAffs() >= 5 and ataxiaTemp.canJinx then
jinx_tzantza = true 
else jinx_tzantza = false
end

if getTzantzaAffs() >= 6 then
need_tzantza = true
else need_tzantza = false

end

if ataxia.afflictions.clumsiness and ataxiaTemp.dollFashions > 10 and not tAffs.paralysis and curses[1] == "paralyse" then
local doll_para = true
else doll_para = false
end




if tAffs.bleed and tAffs.bleed >= 500 and kelpstack and tAffs.haemophilia and tAffs.sensitivity and ataxiaTemp.dollFashions >= 2 then
need_inflamedoll = true
else need_inflamedoll = false
end


if tAffs.paralysis and tAffs.impatience and tAffs.asthma and tAffs.anorexia and tAffs.slickness and ataxiaTemp.canJinx then
need_prone = true
else need_prone = false
end

if ataxiaTemp.dollFashions > 20 and tAffs.impatience and tAffs.asthma and tAffs.weariness and tAffs.bleed >= 150 and not tAffs.anorexia and not tAffs.slickness then
    need_imbibe = true
    else need_imbibe = false
end

if not ataxiaTemp.coagulate and shaman.spiritisbound("aspar") and tAffs.haemophilia and tAffs.bleed >= 100 and not tAffs.anorexia and not tAffs.slickness then
   need_coagulate = true
    else need_coagulate = false
end

if not tAffs.haemophilia and ataxiaTemp.bloodlet == false then
    need_bloodlet = true
    else need_bloodlet = false
    end

if shaman.spiritisbound("syvis") and not ataxiaTemp.relapse and not tAffs.sensitivity then
    need_relapse = true 
    else need_relapse = false
    end

   


if need_imbibe then
    atk = atk.."wield shield doll {"..target.."};vodun status;curse "..target.." anorexia invoke soulscourge vodun imbibe gecko"

elseif need_coagulate then
    atk = atk.."wield shield doll {"..target.."};vodun status;curse "..target.." "..curses[1].." invoke coagulation slickness"
elseif need_relapse then
  atk = atk.."wield shield doll {"..target.."};vodun status;curse "..target.." "..curses[1].." invoke relapse "..curses[1]

elseif need_bloodlet then
  atk = atk.."wield shield doll {"..target.."};vodun status;curse "..target.." "..curses[1].." invoke bloodlet "..target

elseif ataxiaTemp.canJinx then
    atk = atk.."stand;wield shield doll {"..target.."};vodun status;jinx "..curses[1].." "..curses[2].." "..target
    elseif doll_para then
    atk = atk.."wield shield doll {"..target.."};vodun status;vodun paralyse"
elseif curseCharge > 1 then
    atk = atk.."wield shield doll {"..target.."};vodun status;swiftcurse "..target.." "..curses[1]
elseif curseCharge <= 1 then
   atk = atk.."stand;wield shield doll {"..target.."};vodun status;swiftcurse"

end


if need_inflame then
    atk = atk.."wield shield doll {"..target.."};vodun status;swiftcurse "..target.." inflame"
end
if need_inflamedoll then
    atk = atk.."stand;wield shield doll {"..target.."};vodun status;curse "..target.." inflame invoke soulscourge vodun throttle"
end
if need_prone then
   atk = atk.."stand;wield shield doll {"..target.."};vodun status;jinx sleep sleep "..target
end
if jinx_tzantza then
   atk = atk.."stand;wield shield doll {"..target.."};vodun status;jinx amnesia tzantza "..target
   end
if need_tzantza and curseCharge > 1 then
     atk = atk.."stand;wield shield doll {"..target.."};vodun status;swiftcurse "..target.." tzantza"
end
if need_tzantza and curseCharge <= 1 then
     atk = atk.."stand;wield shield doll {"..target.."};vodun status;curse "..target.." tzantza"
end



if not tzantzacurse then
send("queue addclear free "..atk)

end
end