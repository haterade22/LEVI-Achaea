-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Levi  Scripts > Leviticus > DRAGON > RAGEBLADE > PRIOS

function rageprios()

ragevenom ={}


if not tAffs.paralysis then
   table.insert( ragevenom, "curare" )
end


if not tAffs.slickness and tAffs.asthma then
   table.insert( ragevenom, "gecko" )
end
if not tAffs.asthma then
    table.insert( ragevenom, "kalmia" )
end





if not tAffs.anorexia and tAffs.impatience and tAffs.slickness then
    table.insert( ragevenom, "slike" )
end

if not tAffs.stupidity
and tAffs.impatience then
    table.insert( ragevenom, "aconite" )
    
end

if tAffs.paralysis and tAffs.asthma and tAffs.slickness and tAffs. impatience and tAffs.anorexia then 
 table.insert( ragevenom, "voyria" )
 end

dragoncurse ={}

if not tAffs.paralysis and ragevenom[1] ~= "curare" then
    table.insert( dragoncurse, "paralysis" )
end

if not tAffs.impatience then
    table.insert( dragoncurse, "impatience" )
end


if not tAffs.asthma and ragevenom[1] ~= "kalmia" then
    table.insert( dragoncurse, "asthma" )
end

if not tAffs.weariness then
    table.insert( dragoncurse, "weariness" )
end

if not tAffs.stupidity and ragevenom[1] ~= "aconite" then
    table.insert( dragoncurse, "stupidity" )
end
if not tAffs.recklessness then
    table.insert( dragoncurse, "recklessness" )
end




ragedragon()

end