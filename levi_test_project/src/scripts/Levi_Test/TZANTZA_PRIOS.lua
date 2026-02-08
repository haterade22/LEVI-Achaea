function tzantzaprios()

curses = {}

swiftness = swiftness or false
  
dotzantza = tonumber(dotzantza) or 5



if getTzantzaAffs() >= tonumber(dotzantza) then
    table.insert(curses,"tzantza")
end

if not tAffs.paralysis and ataxiaTemp.relapseAff ~= "paralysis" then
    table.insert(curses,"paralysis")
end
if not tAffs.impatience and ataxiaTemp.relapseAff ~= "impatience" then
    table.insert(curses,"impatience")
end



if not tAffs.vertigo  and ataxiaTemp.relapseAff ~= "vertigo" then
    table.insert(curses,"vertigo")
end

if not tAffs.stupidity and ataxiaTemp.relapseAff ~= "stupid" then
    table.insert(curses,"stupid")
end

if not tAffs.dizziness and ataxiaTemp.relapseAff ~= "dizzy" then
    table.insert(curses,"dizzy")
end

if not tAffs.recklessness and ataxiaTemp.relapseAff ~= "reckless" then
table.insert(curses,"reckless")
end

if not tAffs.epilepsy and ataxiaTemp.relapseAff ~= "epilepsy" then
    table.insert(curses,"epilepsy")
end

if not tAffs.dementia and ataxiaTemp.relapseAff ~= "dementia" then
    table.insert(curses,"dementia")
end





if not tAffs.addiction and ataxiaTemp.relapseAff ~= "addiction" then
    table.insert(curses,"addiction")
end








if not tAffs.masochism and tBals.focus == false and ataxiaTemp.relapseAff ~= "masochism" then
    table.insert(curses,"masochism")
    
    
end










if not tAffs.asthma and ataxiaTemp.relapseAff ~= "asthma" then
    table.insert(curses,"asthma")
end

if not tAffs.addiction and ataxiaTemp.relapseAff ~= "haemophilia" then
    table.insert(curses,"haemophilia")
end






if not tAffs.healthleech and ataxiaTemp.relapseAff ~= "healthleech" then
    table.insert(curses,"healthleech")
end

if not tAffs.weariness and ataxiaTemp.relapseAff ~= "weariness" then
    table.insert(curses,"weariness")
end


if not tAffs.nausea and ataxiaTemp.relapseAff ~= "nausea" then
    table.insert(curses,"vomiting")
end


if not tAffs.voyria and ataxiaTemp.relapseAff ~= "plague" then
    table.insert(curses,"plague")
end




if not swiftness then
attack()
elseif swiftness then
attackswift()
end
end

