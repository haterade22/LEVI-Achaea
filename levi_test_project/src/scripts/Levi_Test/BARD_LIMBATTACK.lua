function bardlimbattack() 
local atk = combatQueue()
targetlimb = targetlimb or "" 
almostrebound = almostrebound or false
if ataxiaTables.limbData.bardRapier == 60 then ataxiaTables.limbData.bardRapier = 8 end
if tLimbs.LL + ataxiaTables.limbData.bardRapier >= 101 and tLimbs.LL < 101 then LL_prep = true else LL_prep = false end
if tLimbs.RL + ataxiaTables.limbData.bardRapier >= 101 and tLimbs.RL < 101 then RL_prep = true else RL_prep = false end

tune = "pesante"

if tAffs.prone then tune = "acciaccatura" end

if not tAffs.prone and kelpstack and not tAffs.slickness then targetlimb = "" tune = "martellato" bardvenom[1] = "gecko" bardsong[1] = "recite epic" end


if not  LL_prep and not haveAff("rebounding") and not haveAff("shield") and tLimbs.LL <= 40 and ataxiaTemp.parriedLimb == "right leg" then targetlimb = "left leg" tune = "acciaccatura" bardvenom[1] = "prefarar" bardsong[1] = "sing tremolo" need_sync = true else need_sync = false end
if not  RL_prep and not haveAff("rebounding") and not haveAff("shield") and tLimbs.RL <= 40 and ataxiaTemp.parriedLimb == "left leg" then targetlimb = "right leg" tune = "acciaccatura" bardvenom[1] = "prefarar" bardsong[1] = "sing tremolo" need_sync5 = true else need_sync5 = false end



if  not haveAff("rebounding") and not haveAff("shield") and not LL_prep and ataxiaTemp.parriedLimb == "left leg" and tLimbs.LL >= 40 then bardsong[1] = "recite epic" tune = "pesante" targetlimb = "left leg" need_sync4 = true else need_sync4 = false end
if  not haveAff("rebounding") and not haveAff("shield") and not RL_prep and ataxiaTemp.parriedLimb == "right leg" and tLimbs.RL >= 40 then bardsong[1] = "recite epic" tune = "pesante" targetlimb = "right leg" need_sync6 = true else need_sync6 = false end

if not LL_prep and ataxiaTemp.parriedLimb == "right leg" then targetlimb = "left leg" 
elseif ataxiaTemp.parriedLimb == "left leg" and not RL_prep then targetlimb = "right leg" elseif LL_prep and RL_prep then targetlimb = "" end


if tAffs.prone  and tAffs.weariness and not haveAff("rebounding") and not haveAff("shield") and LL_prep then tune = "pesante" targetlimb = "left leg"  end
if tAffs.prone  and  tAffs.weariness and not haveAff("rebounding") and not haveAff("shield") and RL_prep then tune = "pesante" targetlimb = "right leg"  end

if tAffs.prone and not tAffs.anorexia and not tBals.salve and not haveAff("rebounding") and not haveAff("shield") and tLimbs.LL >= 101 then bardsong[1] = "sing limerick" bardvenom[1] = "slike" targetlimb = "right leg" tune = "acciaccatura" need_sync2 = true else need_sync2 = false end
if tAffs.prone  and not tAffs.anoreixa and not tBals.salve and not haveAff("rebounding") and not haveAff("shield") and tLimbs.RL >= 101 then bardsong[1] = "sing limerick" bardvenom[1] = "slike"  targetlimb = "left leg" tune = "acciaccatura" need_sync7 = true else need_sync7 = false end


if not tAffs.prone and bardsong[1] == "recite epic" and bardvenom[1] == "curare" then bardvenom[1] = bardvenom[2] end

if not tAffs.prone and kelpstack and not tAffs.slickness and LL_prep and RL_prep then targetlimb = "left leg" tune = "martellato" bardvenom[1] = "gecko" bardsong[1] = "recite epic" end


if (need_sync2 or need_sync7) and bardsong[1] == "sing qasida" then bardsong[1] = bardsong[2] end


if tAffs.prone and targetlimb == "" and not tAffs.brokenrightarm then targetlimb = "right arm" tune = "acciaccatura"  end
if tAffs.prone and targetlimb == "" and not tAffs.brokenleftarm  then targetlimb = "left arm" tune = "acciaccatura" end
if tAffs.prone and targetlimb == "" and not tAffs.brokenleftleg then targetlimb = "left leg" tune = "acciaccatura" end
if tAffs.prone and targetlimb == "" and not  tAffs.brokenrightleg then targetlimb = "right leg" tune = "acciaccatura" end



--if tAffs.prone and tAffs.anorexia and tAffs.impatience and not tAffs.slickness and not tAffs.paralysis and tAffs.asthma then
--tune = "pesante"
--bardvenom[1] = "gecko"
--bardsong[1] = "recite epic"


--end

if hardlock and not truelock then bardvenom[1] = "curare" bardsong[1] = "recite epic" end




if not tAffs.deafness and mentalstack then
tune = "accentato"
targetlimb = ""
end




if tAffs.rebounding then

atk = atk.."wield rapier shield;tunesmith rapier "..tune..";raze "..target..";assess "..target

elseif tAffs.shield and not tAffs.rebounding then

atk = atk.."wield rapier shield;tunesmith rapier "..tune..";raze "..target..";assess "..target

elseif
bardsong[1] == "sing tremolo" then catk = bardsong[1].." at "..target.." "..targetlimb 
atk = atk.."wield rapier shield;tunesmith rapier "..tune..";jab "..target.." "..targetlimb.." "..bardvenom[1]..";assess "..target



else

atk = atk.."wield rapier shield;tunesmith rapier "..tune..";jab "..target.." "..targetlimb.." "..bardvenom[1]..";assess "..target
catk = bardsong[1].." at "..target

end

--send("setalias kickass "..atk)
--send("setalias kickassclass "..catk)



if needwipe and (not need_sync) and (not need_sync2) and (not need_sync3) and (not need_sync4) and (not need_sync5) and (not need_sync6) and (not need_sync7) then

send("queue addclear freestand wipe rapier;"..atk)
if not tAffs.deafness then
send("queue addclear class "..catk)
end
elseif (need_sync or need_sync3 or need_sync5 or need_sync2 or need_sync7) then
send("cq all")
send("queue addclear full "..atk..";"..catk..";whistle for songbird")


elseif ( need_sync4 or need_sync6) then
send("cq all")
send("queue addclear full "..catk..";"..atk..";whistle for songbird")


--elseif need_order then

--send("queue addclear freestand order "..target.." apply restoration to torso;"..atk)
--if not tAffs.deafness then
--send("queue addclear class "..catk)
--end

elseif (not need_sync) and (not need_sync2) and (not need_sync3) and (not need_sync4) and (not need_sync5) and (not need_sync6) and (not need_sync7) and not needwipe then
   if ataxiaTemp.needSymphony and bardHarmsInRoom then
      atk = atk.."wield "..ataxia.bardStuff.instrument.." shield"..ataxia.settings.separator.."play symphony"
   elseif not bardHarmsInRoom and not attemptedHarmsRecall then
         attemptedHarmsRecall = tempTimer(1, [[ attemptedHarmsRecall = nil ]])
         atk = atk..ataxia.settings.separator.."call harmonics"
      end

send("queue addclear freestand "..atk)

if not tAffs.deafness then
send("queue addclear class "..catk)
end


end



end

