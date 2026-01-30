--[[mudlet
type: script
name: ATTACK
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

function bardattack() 
local atk = combatQueue()
tune = "pesante"
targetlimb = ""



if not tAffs.paralysis and not tAffs.prone and kelpstack and not tAffs.slickness then targetlimb = "" tune = "martellato" bardvenom[1] = "gecko" bardsong[1] = "recite epic" end
if bardvenom[1] == "gecko" then tune = "martellato" end


if not tAffs.shield and tAffs.slickness and not tAffs.anorexia and kelpstack and not tAffs.impatience and ((not tBals.tree) or (tAffs.paralysis)) then
tune = "acciaccatura"
bardvenom[1] = "slike"
bardsong[1] = "sing limerick"



need_sync = true
else
need_sync = false
end

if not tAffs.shield and not haveAff("anorexia") and not tAffs.slickness and kelpstack and not tBals.tree and haveAff("impatience") then
tune = "acciaccatura"
bardvenom[1] = "gecko"
bardsong[1] = "sing qasida"


need_sync2 = true
else
need_sync2 = false
end


if tAffs.prone and not tAffs.brokenrightleg then targetlimb = "right leg" tune = "acciaccatura" end
if tAffs.prone and not tAffs.brokenleftleg then targetlimb = "left leg" tune = "acciaccatura" end
if tAffs.prone and not tAffs.brokenrightarm then targetlimb = "right arm" tune = "acciaccatura" end
if tAffs.prone and not tAffs.brokenleftarm then targetlimb = "left arm" tune = "acciaccatura" end







if  mentalstack then
tune = "accentato"
targetlimb = ""
end

if tAffs.deafness then 
tune = "pesante"
end



if tAffs.rebounding or tAffs.shield then

if not tAffs.paralysis then
bardsong[1] = "recite epic" end

atk = atk.."wield rapier shield;tunesmith rapier "..tune..";raze "..target..";assess "..target



else

atk = atk.."wield rapier shield;tunesmith rapier "..tune..";jab "..target.." "..targetlimb.." "..bardvenom[1]..";assess "..target
catk = bardsong[1].." at "..target

end

if ataxia.defences.songbird and ataxia.defences.songbird == true  then
not_need_bird = true
else not_need_bird = false
end

if ataxia.afflictions.prone and not tAffs.paralysis then bardsong[1] = "recite epic" end

if ataxia.afflictions.brokenrightarm and ataxia.afflictions.brokenleftarm and  not tAffs.paralysis then bardsong[1] = "recite epic" end



if tAffs.shield and not tAffs.paralysis then bardsong[1] = "recite epic" end

if bardHarmsInRoom and not not_need_bird  then atk = atk..ataxia.settings.separator.."whistle for songbird" end


   if ataxiaTemp.needSymphony and bardHarmsInRoom then
      atk = atk.."wield "..ataxia.bardStuff.instrument.." shield"..ataxia.settings.separator.."play symphony"
   elseif not bardHarmsInRoom and not attemptedHarmsRecall then
         attemptedHarmsRecall = tempTimer(1, [[ attemptedHarmsRecall = nil ]])
         atk = atk..ataxia.settings.separator.."call harmonics"
      end

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





elseif (not need_sync) and (not need_sync2) and not needwipe then


send("queue addclear freestand "..atk)
if not tAffs.deafness then
send("queue addclear class "..catk)
end
end
end

end