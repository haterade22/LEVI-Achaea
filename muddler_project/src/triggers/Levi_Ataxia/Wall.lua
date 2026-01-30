--mmp.failpath()
--mmp.speedWalkDir = {}
if mmp.autowalking == true then
if ataxiaTemp.class == "Silver Dragon" or gmcp.Char.Status.race == "Undead" or ataxiaTemp.class == "Black Dragon" or ataxiaTemp.me == "Leviticus" or ataxiaTemp.class == "Blue Dragon" or ataxiaTemp.class == "Red Dragon" or ataxiaTemp.class == "Green Dragon" or ataxiaTemp.class == "Golden Dragon" then
expandAlias(command)
send("queue addclearfull freestand leap "..mmp.speedWalkDir[1])
elseif table.contains(mmp.speedWalkDir, "gallop") then
expandAlias(command)
local mountjumpdir = string.gsub(mmp.speedWalkDir[1], "gallop", "mountjump")
cecho(mountjumpdir)
send("queue addclearfull freestand "..mountjumpdir)
else
expandAlias(command)
send("queue addclearfull freestand mountjump "..mmp.speedWalkDir[1])
end
end
walkblocked = true

if mmp.autowalking == false and not tChaseTimer then
if ataxiaTemp.class == "Silver Dragon" or gmcp.Char.Status.race == "Undead" or ataxiaTemp.class == "Black Dragon" or ataxiaTemp.me == "Leviticus" or ataxiaTemp.class == "Blue Dragon" or ataxiaTemp.class == "Red Dragon" or ataxiaTemp.class == "Green Dragon" or ataxiaTemp.class == "Golden Dragon" then
send("queue addclearfull freestand leap "..command)
else
send("queue addclearfull freestand mountjump "..command)
end
end

if mmp.autowalking == false and tChaseTimer then
if ataxiaTemp.class == "Silver Dragon" or gmcp.Char.Status.race == "Undead" or ataxiaTemp.class == "Black Dragon" or ataxiaTemp.me == "Leviticus" or ataxiaTemp.class == "Blue Dragon" or ataxiaTemp.class == "Red Dragon" or ataxiaTemp.class == "Green Dragon" or ataxiaTemp.class == "Golden Dragon" then
send("queue addclearfull freestand leap "..dir_left)
else
send("queue addclearfull freestand mountjump "..dir_left)
end
end




--if walkfriend then 
--if ataxiaTemp.class == "Silver Dragon" then
--send("leap "..walkfriend)
--else
--send("mountjump "..walkfriend)
--end
--end