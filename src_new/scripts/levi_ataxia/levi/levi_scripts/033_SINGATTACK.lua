--[[mudlet
type: script
name: SINGATTACK
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- Leviticus
- BARD
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

function singattack() 
local atk = combatQueue()
tune = tune or "pesante"
targetlimb = ""

if bardvenom[1] == "kalmia" and not tAffs.paralysis then  bardsong[1] = "recite epic" end
--targetlimb = "left leg"
--if ataxiaTemp.parriedLimb == "left leg" then targetlimb = "right leg" elseif ataxiaTemp.parriedLimb == "right leg" then targetlimb = "left leg" end


--if tAffs.impatience and tAffs.asthma and mentalstack then need_order = true else need_order = false end



if not tAffs.anorexia and ((tAffs.asthma and tAffs.weariness) or not tBals.salve) and tAffs.impatience then
--tune = "acciaccatura"
bardvenom[1] = "gecko"
bardsong[1] = "sing qasida"

need_sync = true
else
need_sync = false
end

if hardlock and not truelock then bardvenom[1] = "curare" bardsong[1] = "recite epic" end


if not tAffs.deafness and not tAffs.prone and mentalstack or tAffs.paralysis then
tune = "martellato"
else
tune = "pesante"

end

if not tAffs.deafness and ataxiaTemp.lastAssess and ataxiaTemp.lastAssess <= 40 then
tune = "accentato"
targetlimb = ""
end

if tAffs.deafness then 
tune = "pesante"
end


if tAffs.rebounding then

atk = atk.."wield rapier shield;tunesmith rapier "..tune..";raze "..target..";assess "..target

elseif tAffs.shield and not tAffs.rebounding then

atk = atk.."wield rapier shield;tunesmith rapier "..tune..";raze "..target..";assess "..target



else

atk = atk.."wield rapier shield;tunesmith rapier "..tune..";jab "..target.." "..targetlimb.." "..bardvenom[1]..";assess "..target
catk = bardsong[1].." at "..target

end

--send("setalias kickass "..atk)
--send("setalias kickassclass "..catk)
if table.contains(ataxia.playersHere, target) then



if not (ataxia.afflictions.paralysis or ataxia.afflictions.stupidity) then


send("queue addclear class "..catk)


end

end
end