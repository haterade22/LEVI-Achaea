function attacksalveweary()

local atk = combatQueue()
go_cripple = go_cripple or false

if ataxia.afflictions.clumsiness and ataxiaTemp.dollFashions > 10 and not tAffs.paralysis and curses[1] == "paralyse" then
local doll_para = true
else doll_para = false
end







if ataxiaTemp.dollFashions >= 49 and not go_cripple
and not tAffs.prone
 then

 force_restoration = true
else force_restoration = false
end

if ataxiaTemp.dollFashions >= 48 and go_cripple and
not tAffs.prone and not tAffs.brokenleftleg and not tAffs.brokenrightleg then


 need_cripple = true
else need_cripple = false
end

if tAffs.prone and not tAffs.brokenleftarm and not tAffs.brokenrightarm and tBals.tree then
force_tree = true
else force_tree = false
end


if ataxiaTemp.dollFashions >= 41  and not need_cripple and tAffs.prone and
not tAffs.damagedrightleg  then
mangle_rightleg = true
else mangle_rightleg = false
end

if ataxiaTemp.dollFashions >= 34  and not need_cripple and tAffs.prone and not tAffs.damagedleftleg then
mangle_leftleg = true
else mangle_leftleg = false
end


if not ataxiaTemp.relapse
and (tAffs.damagedrightleg or tAffs.damagedleftleg) and tAffs.prone then

relapse_lockaff = true
else relapse_lockaff = false
end

if ataxiaTemp.relapse
 and tAffs.prone 
and not ataxiaTemp.canJinx then

 need_jinx = true
else need_jinx = false
end

if not tAffs.impatience and not tAffs.anorexia
and not ataxiaTemp.canJinx then

 need_jinx = true
else need_jinx = false
end

if ataxiaTemp.tarTumble and tAffs.prone and (tAffs.damagedrightleg or tAffs.damagedleftleg) and not tAffs.agoraphobia then
cancle_tumble_out = true
else cancle_tumble_out = false
end

if ataxiaTemp.tarTumble and tAffs.prone and (tAffs.damagedrightleg or tAffs.damagedleftleg) and not tAffs.claustrophobia then
cancle_tumble_in = true
else cancle_tumble_in = false
end

if ataxiaTemp.dollFashions >= 20 and
tAffs.impatience and tAffs.asthma and not tAffs.anorexia
 then
 ano_gecko = true
else ano_gecko = false

end

if ataxiaTemp.dollFashions >= 20 and
tAffs.impatience and
tAffs.anorexia  then

 asthma_gecko = true
else asthma_gecko = false
end

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




if ataxiaTemp.dollFashions > 20 and tAffs.impatience and tAffs.asthma and tAffs.weariness and tAffs.bleed >= 100 and not tAffs.anorexia and not tAffs.slickness then
    need_imbibe = true
    else need_imbibe = false
end

if tAffs.impatience and tAffs.asthma and tAffs.bleed >= 100 and not tAffs.anorexia and not tAffs.slickness then
   need_coagulate = true
    else need_coagulate = false
end

if not tAffs.haemophilia and ataxiaTemp.bloodlet == false then
   need_bloodlet = true
    else need_bloodlet = false
    end
   




if tAffs.curseward then

    atk = atk.."wield shield doll {"..target.."};vodun status;curse "..target.." breach"

elseif need_imbibe then
    atk = atk.."wield shield doll {"..target.."};vodun status;curse "..target.." anorexia invoke soulscourge vodun imbibe gecko"

elseif force_tree then
  atk = atk.."stand;wield shield doll {"..target.."};vodun status;vodun command touch tree"

elseif force_restoration then
  atk = atk.."stand;wield shield doll {"..target.."};vodun status;vodun command apply restoration to torso"


elseif need_cripple then
  atk = atk.."stand;wield shield doll {"..target.."};vodun status;vodun cripple"
  
  elseif ano_gecko then
atk = atk.."stand;wield shield doll {"..target.."};curse "..target.." anorexia invoke soulscourge vodun imbibe gecko"

elseif asthma_gecko then
atk = atk.."stand;wield shield doll {"..target.."};curse "..target.." asthma invoke soulscourge vodun imbibe gecko"



elseif mangle_rightleg then
  atk = atk.."stand;wield shield doll {"..target.."};vodun status;vodun mangle right leg"
  elseif mangle_leftleg then
  atk = atk.."stand;wield shield doll {"..target.."};vodun status;vodun mangle left leg"


elseif relapse_lockaff then
  atk = atk.."stand;wield shield doll {"..target.."};vodun status;curse "..target.." weariness invoke relapse weariness"

elseif need_jinx then
  atk = atk.."stand;wield shield doll {"..target.."};vodun status;curse "..target.." breach"




elseif need_prone and ataxiaTemp.canJinx then
   atk = atk.."stand;wield shield doll {"..target.."};vodun status;jinx sleep sleep "..target
   
   
elseif need_coagulate then
    atk = atk.."wield shield doll {"..target.."};vodun status;curse "..target.." anorexia invoke coagulation slickness"
elseif need_bloodlet and ataxiaTemp.dollFashions < 20 then
  atk = atk.."wield shield doll {"..target.."};vodun status;curse "..target.." "..curses[1].." invoke bloodlet "..target

elseif ataxiaTemp.canJinx then
    atk = atk.."stand;wield shield doll {"..target.."};vodun status;jinx "..curses[1].." "..curses[2].." "..target
    elseif doll_para then
    atk = atk.."wield shield doll {"..target.."};vodun status;vodun paralyse"
elseif curseCharge > 1 then
    atk = atk.."wield shield doll {"..target.."};vodun status;swiftcurse "..target.." "..curses[1]
elseif curseCharge <= 1 then
   atk = atk.."wield shield doll {"..target.."};vodun status;swiftcurse"

end
if not tzantzacurse then
send("queue addclear free "..atk)
elseif tzantzacurse then
send("none")

end
end