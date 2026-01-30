--[[mudlet
type: script
name: SOFTATTACK
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

function bardattacksoft() 
local atk = combatQueue()
tune = "pesante"
targetlimb = ""

if ((bardvenom[1] == "kalmia") or (tAffs.asthma)) and not tAffs.paralysis and not tAffs.prone  and not mentalstack then bardsong[1] = "recite epic" elseif mentalstack and not tAffs.impatience then bardsong[1] = "sing limerick" end
--targetlimb = "left leg"
--if ataxiaTemp.parriedLimb == "left leg" then targetlimb = "right leg" elseif ataxiaTemp.parriedLimb == "right leg" then targetlimb = "left leg" end


--if tAffs.impatience and tAffs.asthma and mentalstack then need_order = true else need_order = false end

if not tAffs.prone and kelpstack and not tAffs.slickness then targetlimb = "" tune = "martellato" bardvenom[1] = "gecko" bardsong[1] = "recite epic" end



if mentalstack and not tAffs.anorexia and ((not tBals.tree) or (tAffs.paralysis)) then
tune = "acciaccatura"
bardvenom[1] = "gecko"
bardsong[1] = "sing qasida"
targetlimb = "left arm"

need_sync = true
else
need_sync = false
end

if not haveAff("anorexia") and not tAffs.slickness and kelpstack and not tBals.tree and haveAff("impatience") then
tune = "acciaccatura"
bardvenom[1] = "gecko"
bardsong[1] = "sing qasida"
targetlimb = "right arm"

need_sync2 = true
else
need_sync2 = false
end

if not tAffs.prone and bardsong[1] == "recite epic" and bardvenom[1] == "curare" then bardvenom[1] = bardvenom[2] end

if tAffs.prone and not tAffs.brokenrightleg then targetlimb = "right leg" tune = "acciaccatura" end
if tAffs.prone and not tAffs.brokenleftleg then targetlimb = "left leg" tune = "acciaccatura" end
if tAffs.prone and not tAffs.brokenrightarm then targetlimb = "right arm" tune = "acciaccatura" end
if tAffs.prone and not tAffs.brokenleftarm then targetlimb = "left arm" tune = "acciaccatura" end


if hardlock and not truelock then bardvenom[1] = "curare" bardsong[1] = "recite epic" end





if  mentalstack then
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


   if ataxiaTemp.needSymphony and bardHarmsInRoom then
      atk = atk.."wield "..ataxia.bardStuff.instrument.." shield"..ataxia.settings.separator.."play symphony"
   elseif not bardHarmsInRoom and not attemptedHarmsRecall then
         attemptedHarmsRecall = tempTimer(1, [[ attemptedHarmsRecall = nil ]])
         atk = atk..ataxia.settings.separator.."call harmonics"
      end

--send("setalias kickass "..atk)
--send("setalias kickassclass "..catk)
if table.contains(ataxia.playersHere, target) then




if needwipe and (not need_sync) and (not need_sync2)  then

send("queue addclear freestand wipe rapier;"..atk)
if not tAffs.deafness then
send("queue addclear class "..catk)
end

elseif need_sync  then
send("cq all")
send("queue addclear full "..atk..";"..catk)


elseif need_sync2  then
send("cq all")
send("queue addclear full "..catk..";"..atk)



--elseif need_order then

--send("queue addclear freestand order "..target.." apply restoration to torso;"..atk)
--if not tAffs.deafness then
--send("queue addclear class "..catk)
--end

elseif (not need_sync) and (not need_sync2) and not needwipe then


send("queue addclear freestand "..atk)
if not tAffs.deafness then
send("queue addclear class "..catk)
end
end
end

end