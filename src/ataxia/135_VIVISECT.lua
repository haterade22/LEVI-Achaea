-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Levi  Scripts > Leviticus > APOSTATE > VIVISECT

function apostate_vivisect()
local atk = combatQueue()
corruptDmg()
demon()


daeggerhunt = daeggerhunt or false
handshere = handshere or false
freshblood = freshblood or false
if not pm then pm = 100 end
fiendthing = fiendthing or "nightmare"



daeggerhere = daeggerhere or false


if tAffs.paralysis and tAffs.impatience and tAffs.slickness and tAffs.anorexia then truelock = true else truelock = false end



if pm and pm < 45 then 
need_catharsis = true else
need_catharsis = false
end

if pm and pm < 45 and daeggerhere == false then 
pretattack =  "summon daegger;wield daegger shield;"
pre = true
else  pre = false
end

if tAffs.prone and daeggerhere == false then
pretattack =  "summon daegger;wield daegger shield;"
 pre2 = true
else  pre2 = false
end

if bloodworm() == false and freshblood then
postattack =  ";summon bloodworms"
 post1 = true
else  post1 = false
end

if daeggerhunt == false and not tAffs.prone and daeggerhere == true then
postattack =  ";wield daegger shield;daegger levitate;daegger hunt "..target
 post = true
else  post = false
end

if daeggerhunt == false and not tAffs.prone and daeggerhere == false then
postattack =  ";summon daegger;wield daegger shield;daegger levitate;daegger hunt "..target
 post2 = true
else  post2 = false
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


if truelock and tAffs.prone and not tAffs.brokenrightarm and not tAffs.brokenleftarm and not tAffs.brokenrightleg and not tAffs.brokenleftleg then
shrivel_ra = true
else shrivel_ra = false
end

if truelock and tAffs.prone and tAffs.brokenrightarm and not tAffs.brokenleftarm and not tAffs.brokenrightleg and not tAffs.brokenleftleg then
shrivel_la = true
else shrivel_la = false
end

if truelock and tAffs.prone and tAffs.brokenrightarm and tAffs.brokenleftarm and not tAffs.brokenrightleg and not tAffs.brokenleftleg then
shrivel_rl = true
else shrivel_rl = false
end

if truelock and tAffs.prone and tAffs.brokenrightarm and  tAffs.brokenleftarm and tAffs.brokenrightleg and not tAffs.brokenleftleg then
shrivel_ll = true
else shrivel_ll = false
end

if truelock and tAffs.prone then need_trample = true else need_trample = false end

if tAffs.brokenrightarm and tAffs.brokenleftarm and tAffs.brokenrightleg and tAffs.brokenleftleg then
need_vivisect = true
else need_vivisect = false
end



if need_vivisect then

atk = atk.."wield shield;dismount;vivisect "..target..";assess "..target


elseif need_catharsis then 

atk = atk.."summon daegger;wield shield daegger;demon catharsis "..target..";assess "..target




elseif corrupted  then

atk = atk.."wield shield;demon catharsis "..target..";assess "..target

elseif need_trample then

atk = atk.."wield shield;trample;assess "..target


elseif shrivel_la then
  
  atk = atk.."wield shield;dismount;shrivel left arm "..target..";assess "..target

elseif shrivel_ra then
  
  atk = atk.."wield shield;dismount;shrivel right arm "..target..";assess "..target

    elseif shrivel_rl then
  
  atk = atk.."wield shield;dismount;shrivel right leg "..target..";assess "..target

 
 elseif shrivel_ll then
  
  atk = atk.."wield shield;dismount;shrivel left leg "..target..";assess "..target

   

    

elseif (daeggerhunt == false or (bloodworm() == false and freshblood)) then

atk = atk.."wield shield;deadeyes "..target.." "..curses[1].." "..curses[2]..";assess "..target
 
else

atk = atk.."wield shield;deadeyes "..target.." "..curses[1].." "..curses[2]..";assess "..target..";contemplate "..target
 

end


if baalzadeen() == false then

send("queue prepend free summon baalzadeen")

end


if (post1 or post or post2 or post3)  then
send("queue addclear free "..atk..""..postattack)

elseif (pre or pre2 or pre3) and not (ataxia.afflictions.paralysis ) then
send("queue addclear free "..preattack..""..atk)




elseif not (ataxia.afflictions.paralysis ) then


send("queue addclear free "..atk)

end
end
