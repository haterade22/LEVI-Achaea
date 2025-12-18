-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Levi  Scripts > Leviticus > APOSTATE > SLEEP ATTACK

function apostate_sleepattack()
local atk = combatQueue()
corruptDmg()
demon()
daeggerhunt = daeggerhunt or false
handshere = handshere or false
freshblood = freshblood or false
if not pm then pm = 100 end
fiendthing = fiendthing or "nightmare"
partyrelay = partyrelay or true

daeggerhere = daeggerhere or false

if pm and pm < 50 then 
need_catharsis = true else
need_catharsis = false
end

if pm and pm < 50 and daeggerhere == false then 
pretattack =  "summon daegger;wield daegger shield;"
pre = true
else  pre = false
end

if curses[1] == "sleep" and curses[2] == "sleep" then
pretattack =  "summon daegger;wield daegger shield;"
 pre4 = true
else  pre4 = false
end


if tAffs.prone and daeggerhere == false then
pretattack =  "summon daegger;wield daegger shield;"
 pre2 = true
else  pre2 = false
end


if (need_catharsis or currupted) and tAffs.shield then
shield_strip = true
else
shield_strip = false
end




if freshblood and not apopentagram() then
  
preattack =  "summon daegger;wield daegger shield;demon bloodpact "..target.." for "..fiendthing..";order "..fiendthing.." kill "..target..";"
 pre3 = true
 else pre3 = false 
 end

if apopentagram() and demon() ~= fiendthing and daeggerhunt then
postattack =  ";summon daegger;wield daegger shield;dispel pentagram;summon "..fiendthing
 post3 = true
else post3 = false
end





if pm and pm <= 60  and pm > 50 then 
need_sap = true else
need_sap = false
end

  if ataxiaTemp.lastAssess and ataxiaTemp.lastAssess <= corruptDmg() then
 need_corrupt = true else
 need_corrupt = false
end

  if pm - corruptDmg() <= 15 and not tAffs.anorexia and not tAffs.slickness then
 need_corrupt_cath = true else
 need_corrupt_cath = false
  end




if shield_strip then

atk = atk.."wield shield;demon strip "..target..";assess "..target


elseif need_catharsis and not shield_strip then 

atk = atk.."wield shield;demon catharsis "..target..";assess "..target

elseif need_corrupt then

atk = atk.."wield shield;demon corrupt "..target.." paralysis;assess "..target

elseif not corrupted and need_corrupt_cath  then

atk = atk.."wield shield;demon corrupt "..target.." paralysis;assess "..target

elseif corrupted and not tAffs.shield then

atk = atk.."wield shield;demon catharsis "..target..";assess "..target

    
    

 elseif (daeggerhunt == false or (bloodworm() == false and freshblood)) and curses[1] == "paralysis" and ataxia.afflictions.clumsiness then

atk = atk.."wield shield;deadeyes "..target.." "..curses[2].." "..curses[1]..";assess "..target

elseif curses[1] == "sicken" or curses[2] == "sicken" and not tAffs.disloyalty and curses[1] == "paralysis" and ataxia.afflictions.clumsiness then

atk = atk.."wield shield;deadeyes "..target.." "..curses[2].." "..curses[1]..";assess "..target   

 
elseif (daeggerhunt == false or (bloodworm() == false and freshblood)) then

atk = atk.."wield shield;deadeyes "..target.." "..curses[1].." "..curses[2]..";assess "..target

elseif curses[1] == "sicken" or curses[2] == "sicken" and not tAffs.disloyalty and not tAffs.manaleech then

atk = atk.."wield shield;deadeyes "..target.." "..curses[1].." "..curses[2]..";assess "..target

elseif curses[1] == "paralysis" and ataxia.afflictions.clumsiness then

atk = atk.."wield shield;deadeyes "..target.." "..curses[2].." "..curses[1]..";assess "..target..";contemplate "..target
 

 
else

atk = atk.."wield shield;deadeyes "..target.." "..curses[1].." "..curses[2]..";assess "..target..";contemplate "..target
 

end

if table.contains(ataxia.playersHere, target) then

if baalzadeen() == false then

send("queue prepend free summon baalzadeen")

end

if (post1 or post or post2 or post3 or post4) and not (ataxia.afflictions.paralysis ) then
send("queue addclear free "..atk..""..postattack)

elseif (pre or pre2 or pre3) and not (ataxia.afflictions.paralysis ) then
send("queue addclear free "..preattack..""..atk)




elseif not (ataxia.afflictions.aeon) then

send("queue addclear free "..atk)


end
end
end
