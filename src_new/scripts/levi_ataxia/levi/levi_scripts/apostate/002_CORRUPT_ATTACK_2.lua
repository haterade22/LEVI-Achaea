--[[mudlet
type: script
name: CORRUPT ATTACK 2
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- Leviticus
- APOSTATE
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

function apostate_lock()
local atk = combatQueue()
corruptDmg()
demon()
daeggerhunt = daeggerhunt or false
handshere = handshere or false
freshblood = freshblood or false
if not pm then pm = 100 end
fiendthing = fiendthing or "nightmare"
partyrelay = partyrelay or true
clumsycurse = curses[1]


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

if pm and pm > 50 and daeggerhere == false then 
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


if tAffs.asthma and (curses[1] == "sicken" or curses[2] == "sicken") and not tAffs.disloyalty then
postattack =  ";disfigure "..target
 post4 = true
else post4 = false
end




if pm and pm <= 60  and pm < 50 then 
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

    
    
 
elseif (daeggerhunt == false or (bloodworm() == false and freshblood)) then

atk = atk.."wield shield;deadeyes "..target.." "..curse1.." "..curse2..";assess "..target

elseif curse1 == "sicken" or curse2 == "sicken" and not tAffs.disloyalty then

atk = atk.."wield shield;deadeyes "..target.." "..curse1.." "..curse2..";assess "..target

 
else

atk = atk.."wield shield;deadeyes "..target.." "..curse1.." "..curse2..";assess "..target..";contemplate "..target
 

end

if table.contains(ataxia.playersHere, target) then

if baalzadeen() == false then

send("queue prepend free summon baalzadeen")

end

if (post1 or post or post2 or post3 or post4) then
send("queue addclear free "..atk..""..postattack)

elseif (pre or pre2 or pre3) then
send("queue addclear free "..preattack..""..atk)




else

send("queue addclear free "..atk)


end
end
end

function apostate_lockImpale()
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



if bloodworm() == false and freshblood then
postattack =  ";summon bloodworms"
 post1 = true
else  post1 = false
end

if daeggerhunt == false and not tAffs.prone and daeggerhere == true and not apopentagram() then
postattack =  ";wield daegger shield;daegger levitate;daegger hunt "..target
 post = true
else  post = false
end

if daeggerhunt == false and not tAffs.prone and daeggerhere == false and curses[1] ~= "sleep" and curses[2] ~= "sleep" and not apopentagram() then
postattack =  ";summon daegger;wield daegger shield;daegger levitate;daegger hunt "..target
 post2 = true
else  post2 = false
end

if (need_catharsis or currupted) and tAffs.shield then
shield_strip = true
else
shield_strip = false
end

if apopentagram() and not tAffs.impaled then
postattack = ";summon daegger;wield daegger;daegger levitate;daegger shadowstrike "..target
post5 = true
else
post5 = false
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


if tAffs.asthma and (curses[1] == "sicken" or curses[2] == "sicken") and tAffs.manaleech and not tAffs.disloyalty then
postattack =  ";disfigure "..target
 post4 = true
else post4 = false
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

elseif curses[1] == "sicken" or curses[2] == "sicken" and not tAffs.disloyalty then

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

if (post1 or post or post2 or post3 or post4 or post5) and not (ataxia.afflictions.paralysis ) then
send("queue addclear free "..atk..""..postattack)

elseif (pre or pre2 or pre3) and not (ataxia.afflictions.paralysis) then
send("queue addclear free "..preattack..""..atk)




elseif not (ataxia.afflictions.aeon ) then

send("queue addclear free "..atk)


end
end
end