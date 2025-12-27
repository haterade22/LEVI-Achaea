--[[mudlet
type: script
name: TZANTZA ATTACK
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- Leviticus
- SHAMAN
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

function tzantzaattack()

local atk = combatQueue()
ataxiaTemp.dollFashions = ataxiaTemp.dollFashions or 0
ataxia_lockBreak()




if getTzantzaAffs() >= tonumber(dotzantza)  and ataxiaTemp.dollFashions > 30 then
bind_tzantza = true 
else bind_tzantza = false
end

if ataxia.afflictions.clumsiness and ataxiaTemp.dollFashions > 10 and not tAffs.paralysis and curses[1] == "paralyse" then
local doll_para = true
else doll_para = false
end


if tAffs.paralysis and tAffs.impatience and tAffs.asthma and tAffs.anorexia and tAffs.slickness and ataxiaTemp.canJinx then
need_prone = true
else need_prone = false
end

if ataxiaTemp.dollFashions > 20 and tAffs.impatience and tAffs.asthma and tAffs.weariness and tAffs.bleed >= 200 and not tAffs.anorexia and not tAffs.slickness then
    need_imbibe = true
    else need_imbibe = false
end

if tAffs.haemophilia and tAffs.impatience and tAffs.asthma and tAffs.weariness and tAffs.bleed >= 150 and not tAffs.anorexia and not tAffs.slickness then
    need_coagulate = true
    else need_coagulate = false
end

if not tAffs.haemophilia and ataxiaTemp.bloodlet == false and not tBals.plant then
    need_bloodlet = true
    else need_bloodlet = false
    end
   
if not ataxiaTemp.relapse and not tAffs.impatience and curses[1] ~= "amnesia" then
    need_relapse = true 
    else need_relapse = false
    end




if tAffs.curseward then

    atk = atk.."wield shield doll {"..target.."};vodun status;curse "..target.." breach"
elseif need_imbibe then
    atk = atk.."wield shield doll {"..target.."};vodun status;curse "..target.." anorexia invoke soulscourge vodun imbibe gecko"
elseif need_blight then

  atk = atk.."wield shield doll {"..target.."};vodun status;blight "..target.." weariness"


elseif bind_tzantza then
    atk = atk.."wield shield doll {"..target.."};vodun status;curse "..target.." "..curses[1].." invoke soulscourge vodun bind"

elseif need_coagulate then
    atk = atk.."wield shield doll {"..target.."};vodun status;curse "..target.." anorexia invoke coagulation slickness"
elseif need_bloodlet then
  atk = atk.."wield shield doll {"..target.."};vodun status;curse "..target.." "..curses[1].." invoke bloodlet "..target
elseif need_relapse then

  atk = atk.."wield shield doll {"..target.."};vodun status;curse "..target.." "..curses[1].." invoke relapse "..curses[1]

elseif ataxiaTemp.canJinx then
    atk = atk.."stand;wield shield doll {"..target.."};vodun status;jinx "..curses[1].." "..curses[2].." "..target

elseif doll_para then
    atk = atk.."wield shield doll {"..target.."};vodun status;vodun paralyse"
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