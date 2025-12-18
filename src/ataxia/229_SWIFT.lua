-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Levi  Scripts > Leviticus > SHAMAN > SWIFT

function attackswift()

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

if tAffs.paralysis and tAffs.impatience and tAffs.asthma and tAffs.anorexia and tAffs.slickness and ataxiaTemp.canJinx then
need_prone = true
else need_prone = false
end

if tAffs.impatience and tAffs.asthma and tAffs.weariness and tAffs.bleed >= 200 and not tAffs.anorexia and not tAffs.slickness then
    need_coagulate = true
    else need_coagulate = false
end

if not tAffs.haemophilia and ataxiaTemp.bloodlet == false then
    need_bloodlet = true
    else need_bloodlet = false
    end
   




if tAffs.curseward then

    atk = atk.."wield shield doll {"..target.."};vodun status;curse "..target.." breach"

elseif jinx_tzantza then
   atk = atk.."stand;wield shield doll {"..target.."};vodun status;jinx amnesia tzantza "..target

elseif need_tzantza and curseCharge > 1 then
     atk = atk.."stand;wield shield doll {"..target.."};vodun status;swiftcurse "..target.." tzantza"

elseif need_tzantza and curseCharge <= 1 then
     atk = atk.."stand;wield shield doll {"..target.."};vodun status;curse "..target.." tzantza"

elseif need_prone then
   atk = atk.."stand;wield shield doll {"..target.."};vodun status;jinx sleep sleep "..target
elseif curseCharge > 1 then
    atk = atk.."wield shield doll {"..target.."};vodun status;swiftcurse "..target.." "..curses[1]
elseif curseCharge <= 1 then
   atk = atk.."wield shield doll {"..target.."};vodun status;swiftcurse"


end


if not ataxia_needLockBreak() then
if not tzantzacurse then
send("queue addclear free "..atk)
elseif tzantzacurse then
send("none")

end
end
end