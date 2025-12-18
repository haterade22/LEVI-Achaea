-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Levi  Scripts > Leviticus > SHAMAN > CLUMSY PRIOS

function clumsyprios()
getLockingAffliction()
curses = {}

if checkAffList({"anorexia", "asthma", "slickness", "bloodfire"},3) then
	local	softlock = true
  else
  softlock = false
	
	end
	if softlock and checkAffList({"impatience", "sandfever"},1) then
	local	hardlock = true
   hardlock = false
  end
	
if checkAffList({"healthleech", "asthma", "weariness", "sensitivity", "clumsiness", "hypochondria", "parasite", "rebbies"},3) then
		kelpstack = true
  else
  kelpstack = false

	end
if checkAffList({"addiction", "nausea", "lethargy", "scytherus", "darkshade", "haemophilia", "flushings", "unweavingbody"},3) then
		ginstack = true
  else
  ginstack = false

	end

	if hardlock and haveAff("paralysis") then
	local	truelock = true
 truelock = false
	
	end
  swiftness = swiftness or false
 
  if ataxiaTemp.dollFashions and ataxiaTemp.dollFashions > 0 and ataxiaTemp.dollFashions < 55 then
rending = true
else
rending = false
end

if truelock and not tAffs.voyria  then

    table.insert(curses,"plague")
end

if tAffs.slickness and not tAffs.anorexia and tAffs.impatience then
    table.insert(curses,"anorexia")
end


if not tAffs.paralysis and ataxiaTemp.relapseAff ~= "paralysis" then
    table.insert(curses,"paralysis")
end

if kelpstack and not tAffs.impatience and ataxiaTemp.relapseAff ~= "impatience" then
    table.insert(curses,"impatience")
end


if not tAffs.clumsiness and ataxiaTemp.relapseAff ~= "clumsiness" then
    table.insert(curses,"clumsy")
end

if not tAffs.weariness and ataxiaTemp.relapseAff ~= "weariness" then
    table.insert(curses,"weariness")
end

if not tAffs.asthma and ataxiaTemp.relapseAff ~= "asthma" then
    table.insert(curses,"asthma")
end

if not tAffs.healthleech and ataxiaTemp.relapseAff ~= "healthleech" then
    table.insert(curses,"healthleech")
end



if not tAffs.haemophilia and ataxiaTemp.relapseAff ~= "haemophilia" then
    table.insert(curses,"haemophilia")
end










if getLockingAffliction() ~= "confusion" and getLockingAffliction() ~= "weariness" and getLockingAffliction() ~= "plague" and
 not tAffs[getLockingAffliction()] and ataxiaTemp.relapseAff ~= getLockingAffliction()
then    table.insert(curses,getLockingAffliction())
end

if not tAffs.recklessness and ataxiaTemp.relapseAff ~= "recklessness" then
table.insert(curses,"reckless")
end

if not tAffs.stupidity and ataxiaTemp.relapseAff ~= "stupid" then
    table.insert(curses,"stupid")
end



if not tAffs.addiction and ataxiaTemp.relapseAff ~= "addiction" then
    table.insert(curses,"addiction")
end



if not tAffs.dizziness  and ataxiaTemp.relapseAff ~= "dizzy" then
    table.insert(curses,"dizzy")
end

if not tAffs.dementia  and ataxiaTemp.relapseAff ~= "dementia" then
    table.insert(curses,"dementia")
end

if not tAffs.vertigo  and ataxiaTemp.relapseAff ~= "vertigo" then
    table.insert(curses,"vertigo")
end



if not tAffs.addiction and ataxiaTemp.relapseAff ~= "addiction" then
    table.insert(curses,"addiction")
end

if not tAffs.nausea and ataxiaTemp.relapseAff ~= "nausea" then
    table.insert(curses,"vomiting")
end



if not tAffs.masochism and ataxiaTemp.relapseAff ~= "masochism" then
    table.insert(curses,"masochism")
end







if swiftness == false then
attack()
elseif swiftness == true then
attackswift()
end
end

