-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Levi  Scripts > Leviticus > APOSTATE > LOCK ATTACK

function apostate_lockattack()
local atk = combatQueue()
corruptDmg()
demon()
daeggerhunt = daeggerhunt or false
handshere = handshere or false
freshblood = freshblood or false
if not pm then pm = 100 end
fiendthing = fiendthing or "nightmare"
partyrelay = partyrelay or true
want_disloyalty = want_disloyalty or false
clumsycurse = curses[1]
getLockingAffliction()
checkTargetLocks()

curse1 = curses[1]
curse2 = curses[2]


if curse1 == "paralysis" then
curse2 = "paralysis"
curse1 = curses[2]
end

if not tBals.tree and tAffs.manaleech and 
curse1 == "sicken" and curse2 == "paralysis" then
curse2 = curses[3]
end

daeggerhere = daeggerhere or false

if pm and pm < 50 then 
need_catharsis = true else
need_catharsis = false
end

if pm and pm < 50 and daeggerhere == false then 
preattack =  "summon daegger;wield daegger shield;"
pre = true
else  pre = false
end

if curses[1] == "sleep" and curses[2] == "sleep" then
preattack =  "summon daegger;wield daegger shield;"
 pre4 = true
else  pre4 = false
end


if tAffs.prone and daeggerhere == false then
preattack =  "summon daegger;wield daegger shield;"
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

if daeggerhunt == false and not tAffs.prone and daeggerhere == false and curses[1] ~= "sleep" and curses[2] ~= "sleep" then
postattack =  ";summon daegger;wield daegger shield;daegger levitate;daegger hunt "..target
 post2 = true
else  post2 = false
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


if want_disloyalty and tAffs.asthma and (curses[1] == "sicken" or curses[2] == "sicken") and not tAffs.disloyalty then
postattack =  ";disfigure "..target
 post4 = true
else post4 = false
end


if truelock and tAffs.prone then need_trample = true else need_trample = false end

if tAffs.prone and tAffs.brokenrightarm and tAffs.brokenleftarm and tAffs.brokenrightleg and tAffs.brokenleftleg then
need_vivisect = true
else need_vivisect = false
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


if need_vivisect then

atk = atk.."wield shield;dismount;vivisect "..target..";assess "..target



elseif shield_strip then

atk = atk.."wield shield;demon strip "..target..";assess "..target

elseif need_trample then

atk = atk.."wield shield;trample;assess "..target


elseif need_catharsis and not shield_strip then 

atk = atk.."wield shield;demon catharsis "..target..";assess "..target

    

elseif (daeggerhunt == false or (bloodworm() == false and freshblood)) then

atk = atk.."wield shield;deadeyes "..target.." "..curse1.." "..curse2..";assess "..target

elseif curse1 == "sicken" or curse2 == "sicken" and not tAffs.disloyalty and want_disloyalty then

atk = atk.."wield shield;deadeyes "..target.." "..curse1.." "..curse2..";assess "..target

 
else

atk = atk.."wield shield;deadeyes "..target.." "..curse1.." "..curse2..";assess "..target..";contemplate "..target
 

end

if table.contains(ataxia.playersHere, target) then



if baalzadeen() == false then

send("queue prepend free summon baalzadeen")

end

if (post1 or post or post2 or post3 or post4) and not ataxia.afflictions.aeon then
send("queue addclear freestand "..atk..""..postattack)

elseif (pre or pre2 or pre3) and not ataxia.afflictions.aeon then
send("queue addclear freestand "..preattack..""..atk)




elseif not ataxia.afflictions.aeon then

send("queue addclear freestand "..atk)





end
end
end
