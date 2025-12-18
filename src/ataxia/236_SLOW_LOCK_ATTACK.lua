-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Levi  Scripts > Leviticus > SHAMAN > SLOW LOCK ATTACK

function attackslow()

local atk = combatQueue()
ataxia_lockBreak()

if tAffs.aeon then tAffs.nospeed = true end


if getTzantzaAffs() >= 5 and ataxiaTemp.canJinx then
jinx_tzantza = true 
else jinx_tzantza = false
end

if getTzantzaAffs() >= 6 then
need_tzantza = true
else need_tzantza = false

end

if tAffs.aeon then
need_prone = true

elseif not tAffs.prone and tAffs.paralysis and tAffs.impatience and tAffs.asthma and tAffs.anorexia and tAffs.slickness and ataxiaTemp.canJinx then
need_prone = true
else need_prone = false
end



if ataxiaTemp.dollFashions > 24 and not tBals.tree and not tAffs.aeon then
speed_strip = true
else speed_strip = false
end

if ataxiaTemp.dollFashions > 24 and tBals.tree and not tAffs.aeon and not tAffs.paralysis and (not tAffs.brokenleftarm and not tAffs.brokenrightarm)  then 
force_tree = true
else force_tree = false
end

if not ataxiaTemp.relapse
and ataxiaTemp.dollFashions >= 21 and tAffs.nospeed 
and not tBals.tree and not ataxiaTemp.relapseAff then
relapse_asthma = true
else 
relapse_asthma = false
end

if not tAffs.aeon and ataxiaTemp.dollFashions >= 21 and tAffs.nospeed and ataxiaTemp.relapseAff == "asthma" then
vodun_slow = true
else 
vodun_slow = false
end

if tAffs.aeon and tAffs.curseward and not tAffs.asthma then
breach_asthma = true
else 
breach_asthma = false
end

if tAffs.aeon and tAffs.curseward and tAffs.asthma and not tAffs.anorexia then
breach_ano = true
else 
breach_ano = false
end



if ataxiaTemp.dollFashions > 20 and tAffs.impatience and tAffs.asthma and tAffs.anorexia and not tAffs.slickness then
    need_imbibe = true
    else need_imbibe = false
end

if tAffs.impatience and tAffs.asthma and tAffs.weariness and tAffs.bleed >= 200 and not tAffs.anorexia and not tAffs.slickness then
    need_coagulate = true
    else need_coagulate = false
end

if not tAffs.haemophilia and ataxiaTemp.bloodlet == false then
    need_bloodlet = true
    else need_bloodlet = false
    end
   





if breach_asthma then
atk = atk.."wield shield doll {"..target.."};vodun status;curse "..target.." breach invoke soulscourge vodun imbibe kalmia"

elseif breach_asthma then
atk = atk.."wield shield doll {"..target.."};vodun status;curse "..target.." breach invoke soulscourge vodun imbibe slike"



elseif need_imbibe then
    atk = atk.."wield shield doll {"..target.."};vodun status;curse "..target.." weariness invoke soulscourge vodun imbibe gecko"



elseif vodun_slow then
  atk = atk.."stand;wield shield doll {"..target.."};vodun status;vodun slow"


elseif relapse_asthma then
  atk = atk.."stand;wield shield doll {"..target.."};vodun status;blight "..target.." asthma invoke relapse asthma"


elseif speed_strip then
  atk = atk.."stand;wield shield doll {"..target.."};vodun status;vodun slow"


elseif force_tree then
  atk = atk.."stand;wield shield doll {"..target.."};vodun status;vodun command touch tree"


elseif need_prone and ataxiaTemp.canJinx then
   atk = atk.."stand;wield shield doll {"..target.."};vodun status;jinx sleep sleep "..target
   
   
elseif need_coagulate then
    atk = atk.."wield shield doll {"..target.."};vodun status;curse "..target.." anorexia invoke coagulation slickness"
elseif need_bloodlet and ataxiaTemp.dollFashions < 20 then
  atk = atk.."wield shield doll {"..target.."};vodun status;curse "..target.." "..curses[1].." invoke bloodlet "..target

elseif ataxiaTemp.canJinx then
    atk = atk.."stand;wield shield doll {"..target.."};vodun status;jinx "..curses[1].." "..curses[2].." "..target
elseif curseCharge > 1 then
    atk = atk.."wield shield doll {"..target.."};vodun status;swiftcurse "..target.." "..curses[1]
elseif curseCharge <= 1 then
   atk = atk.."wield shield doll {"..target.."};vodun status;swiftcurse"

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

if not ataxia_needLockBreak() then
if not tzantzacurse then
send("queue addclear free "..atk)
elseif tzantzacurse then
send("none")

end
end
end