-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Levi  Scripts > Leviticus > MONK > SHIKUDO > DISPTACH LEG PRIOS





  function dispatch_base_priosTEST()
  
  
preplimb = preplimb or "right leg"
shistick = {}

if tAffs.prone or tAffs.paralysis then ataxiaTemp.parriedLimb = "none" end


if tLimbs.LA + ataxiaTables.limbData.shikRuku >=  100 then  laRUK = true else laRUK = false end
if tLimbs.RA + ataxiaTables.limbData.shikRuku >=  100 then  raRUK = true else raRUK = false end
if tLimbs.LA + ataxiaTables.limbData.shikFrontkick >=  100 then  laFRO = true  else laFRO = false end
if tLimbs.RA + ataxiaTables.limbData.shikFrontkick >=  100 then  raFRO = true  else raFRO = false end
if tLimbs.LA + ataxiaTables.limbData.shikDart >=  100 then  laDAR = true else laDAR = false end
if tLimbs.RA + ataxiaTables.limbData.shikDart >=  100 then  raDAR = true else raDAR = false end


if tLimbs.RL + ataxiaTables.limbData.shikKuro >=  100 and not tAffs.damagedrightleg then  rlKUR = true else rlKUR = false end
if tLimbs.LL + ataxiaTables.limbData.shikKuro >=  100 and not tAffs.damagedleftleg then llKUR = true else llKUR = false end
if tLimbs.LL + ataxiaTables.limbData.shikFlashheel >=  100 and not tAffs.damagedleftleg then llFLASH = true else llFLASH = false end
if tLimbs.RL + ataxiaTables.limbData.shikFlashheel >=  100 and not tAffs.damagedrightleg then  rlFLASH = true else rlFLASH = false end
if tLimbs.LL + ataxiaTables.limbData.shikFlashheel + ataxiaTables.limbData.shikKuro >=  100 and not tAffs.damagedleftleg then llFLASHKUR = true else llFLASHKUR = false end
if tLimbs.RL + ataxiaTables.limbData.shikFlashheel + ataxiaTables.limbData.shikKuro >=  100 and not tAffs.damagedrightleg then  rlFLASHKUR = true else rlFLASHKUR = false end
if tLimbs.RL + ataxiaTables.limbData.shikDart >=  100 and not tAffs.damagedrightleg then  rlDAR = true else rlDAR = false end
if tLimbs.LL + ataxiaTables.limbData.shikDart >=  100 and not tAffs.damagedleftleg then llDAR = true else llDAR = false end




if tLimbs.H + ataxiaTables.limbData.shikNervestrike >=  100 then  hNERV = true else hNERV = false end
if tLimbs.H + ataxiaTables.limbData.shikSpinkickHead >=  100 then  hSPIN = true else hSPIN = false end
if tLimbs.H + ataxiaTables.limbData.shikRisingkick >=  100 then  hRIS = true else hRIS = false end
if tLimbs.H + ataxiaTables.limbData.shikHiru >=  100 then  hHIRU = true else hHIRU = false end
if tLimbs.H + ataxiaTables.limbData.shikHiraku >=  100 then  hHIRA = true  else hHIRA = false end
if tLimbs.H + ataxiaTables.limbData.shikNeedle >=  100 then  hNEED = true  else hNEED = false end
if tLimbs.H + ataxiaTables.limbData.shikNervestrike + ataxiaTables.limbData.shikRisingkick >=  100 then  hNERVRIS = true else hNERVRIS = false end
if tLimbs.H + ataxiaTables.limbData.shikHiru + ataxiaTables.limbData.shikHiraku >= 100 then hHIHI = true else hHIHI = false end
if tLimbs.H + ataxiaTables.limbData.shikNeedle + ataxiaTables.limbData.shikNeedle >=  100 then  hNEED2 = true else hNEED2 = false end

 
if rlKUR and raRUK then rightprep = true else rightprep = false end
if llKUR and laRUK then leftprep = true else leftprep = false end


 
 
-- TYKONOS --
-- THRUST, SWEEP, RISINGKICK
-- WILLOW



if ataxia.vitals.form == "Tykonos" then
if

 not tAffs.prone then
 table.insert(shistick,"sweep")
 
 end


if not hRIS then shikick = "risingkick head"
else shikick = "risingkick torso" end
 



end

-- WILLOW --
-- DART, SWEEP, HIRU, FLASHHEEL, HIRAKU
-- RAIN



if ataxia.vitals.form == "Willow" then


if not llFLASH and not llKUR then
shikick = "flashheel left"
  elseif (llFLASH or llKUR) and not rlFLASH and not rlKUR then
  shikick = "flashheel right"
  end
  
  if not hHIHI then
  table.insert(shistick,"hiraku")
  table.insert(shistick,"hiru")
  end

if hHIHI and not laDAR and not laRUK then
  table.insert(shistick,"dart left arm")
  table.insert(shistick,"dart left arm")

 end

if hHIHI and not raDAR and not raRUK then
  table.insert(shistick,"dart right arm")
  table.insert(shistick,"dart right arm")

 end
 
if rlFLASH and llFLASH then
  table.insert(shistick,"sweep")

 end

end


 
 
  -- OAK --
-- LIVESTRIKE, NERVESTRIKE, RUKU, RISINGKICK, KURO
-- WILLOW GAITAL


if ataxia.vitals.form == "Oak" then


if (ataxiaTemp.parriedLimb ~= "head" or ataxiaTemp.hyperLimb == "head") and not hNERV then
      table.insert(shistick,"nervestrike")
end

if (ataxiaTemp.parriedLimb ~= "head" or ataxiaTemp.hyperLimb == "head") and not hNERVRIS then
    shikick = "risingkick head"
end

if hNERVRIS or (ataxiaTemp.parriedLimb == "head" and ataxiaTemp.hyperLimb ~= "head") then 
    shikick = "risingkick torso"
end


if not tAffs.asthma then
      table.insert(shistick,"livestrike")
end

if laRUK and raRUK and not tAffs.slickness and (tAffs.paralysis or shistick[1] == "nervestrike") then
        table.insert(shistick,"ruku torso")
end


if not llKUR then

       table.insert(shistick,"kuro left")

end

if  not rlKUR then 

  table.insert(shistick,"kuro right")
      
end


if not laRUK then
       table.insert(shistick,"ruku left")
end

if not raRUK then
       table.insert(shistick,"ruku right")
end


end
 
-- RAIN --
-- RUKU, KURO, HIRU, FRONTKICK
-- TYKONOS OAK



 if ataxia.vitals.form == "Rain" then
 

if  not laFRO then
  shikick = "frontkick left"
  elseif laFRO and not raFRO then
shikick = "frontkick right" 
else shikick = "none" end
 

if laRUK and raRUK and not tAffs.slickness then
        table.insert(shistick,"ruku torso")
end


if not leftprep and not llKUR then

       table.insert(shistick,"kuro left")
       table.insert(shistick,"ruku left")

end

if not leftprep and  llKUR and not laRUK then

       table.insert(shistick,"ruku left")
       table.insert(shistick,"ruku left")

end

if not rightprep and not rlKUR then 

  table.insert(shistick,"kuro right")
         table.insert(shistick,"ruku right")
end

if not rightprep and rlKUR and not raRUK then 

  table.insert(shistick,"ruku right")
         table.insert(shistick,"ruku right")
end



 if not hHIRU then
         table.insert(shistick,"hiru")
      
 end
end

if raRUK or laRUK and hHIRU then
        table.insert(shistick,"ruku torso")
end

-- GAITAL --
-- NEEDLE, SPINKICK, SWEEP, RUKU, FLASHHEEL, KURO
-- RAIN MAELSTROM


if ataxia.vitals.form == "Gaital" then

if tAffs.prone and llFLASH and hNEED and tLimbs.H < 100
then

shikick = "flashheel left"
  table.insert(shistick,"ruku left")
  table.insert(shistick,"needle")

end

if not hNEED2 and rlFLASH and llFLASH and raRUK and laRUK then
  table.insert(shistick,"needle")
   table.insert(shistick,"needle")
shikick = "spinkick"
 end

if hNEED2 and not hNEED and rlFLASH and llFLASH and raRUK and laRUK then
  table.insert(shistick,"needle")
   table.insert(shistick,"ruku torso")
shikick = "spinkick"
 end

if  tAffs.prone and not tAffs.crushedthroat and tLimbs.H >= 100 then
  table.insert(shistick,"needle")
   table.insert(shistick,"ruku right")
    table.insert(shistick,"ruku right")
shikick = "spinkick"
 end
 

if tAffs.prone and tAffs.damagedhead and not tAffs.crushedthroat then

  table.insert(shistick,"needle")
 end
 
 if not tAffs.prone and rlFLASH and llKUR and hNEED then
table.insert(shistick,"sweep")

shikick = "flashheel right"

end








if   not llFLASH and not tAffs.prone  then

shikick = "flashheel left"
end

if not rlFLASH and llFLASH and not tAffs.prone  then

shikick = "flashheel right"
end

--if rlFLASH and shistick[1] ~= "sweep" and llFLASH then
--shikick = "spinkick"
--end



if not rlKUR and not tAffs.prone and shikick ~= "flashheel right" then 
       table.insert(shistick,"kuro right")

  end
  
if not raRUK  and not tAffs.prone then

       table.insert(shistick,"ruku right")
end
  
  if not llKUR and not tAffs.prone and shikick ~= "flashheel left" then 
       table.insert(shistick,"kuro left")

  end
if not laRUK  and not tAffs.prone then

       table.insert(shistick,"ruku left")
end

if not hNEED and (rlKUR or llKUR) then
       table.insert(shistick,"needle")
end





if  laRUK and tAffs.prone then

       table.insert(shistick,"ruku left")
end



if raRUK and tAffs.prone and tAffs.mangledhead then

       table.insert(shistick,"ruku right")
end

if laRUK and raRUK and not tAffs.slickness and not tAffs.prone and shistick[1] ~= "sweep" then
        table.insert(shistick,"ruku torso")
end

--if
 --not tAffs.prone and not rlFLASH and not  llKUR and not hNEED then
 --shikick = "spinkick"

--end


 
-- if (tAffs.brokenrightleg or tAffs.brokenleftleg) and not tAffs.prone then
 -- table.insert(shistick,"sweep")
 -- end



 


end



-- MAELSTROM --
-- RUKU, RISINGKICK, SWEEP, CRESCENT, LIVESTRIKE, JINZUKU
-- OAK


if ataxia.vitals.form == "Maelstrom" then


if ataxiaTemp.lastAssess and ataxiaTemp.lastAssess <= 50 then
  table.insert(shistick,"sweep")

 shikick = "crescent"
 end
end

dispatch_base_attack()

end

