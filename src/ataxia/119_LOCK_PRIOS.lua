-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Levi  Scripts > Leviticus > MONK > SHIKUDO > LOCK PRIOS


function lock_base_prios()
  
  


preplimb = preplimb or "right leg"
shikudo = {}

if tAffs.prone or tAffs.paralysis then ataxiaTemp.parriedLimb = "none" end


if tLimbs.LA + ataxiaTables.limbData.shikRuku >=  100 then  leftarmpreppedRUK = true else leftarmpreppedRUK = false end
if tLimbs.RA + ataxiaTables.limbData.shikRuku >=  100 then  rightarmpreppedRUK = true else rightarmpreppedRUK = false end
if tLimbs.LA + ataxiaTables.limbData.shikFrontkick >=  100 then  leftarmpreppedFRO = true  else leftarmpreppedFRO = false end
if tLimbs.RA + ataxiaTables.limbData.shikFrontkick >=  100 then  rightarmpreppedFRO = true  else rightarmpreppedFRO = false end


if tLimbs.RL + ataxiaTables.limbData.shikKuro >=  100 and not tAffs.damagedrightleg then  rightlegpreppedKUR = true else rightlegpreppedKUR = false end
if tLimbs.LL + ataxiaTables.limbData.shikKuro >=  100 and not tAffs.damagedleftleg then leftlegpreppedKUR = true else leftlegpreppedKUR = false end
if tLimbs.LL + ataxiaTables.limbData.shikFlashheel >=  100 and not tAffs.damagedleftleg then leftlegpreppedFLASH = true else leftlegpreppedFLASH = false end
if tLimbs.RL + ataxiaTables.limbData.shikFlashheel >=  100 and not tAffs.damagedrightleg then  rightlegpreppedFLASH = true else rightlegpreppedFLASH = false end

if tLimbs.H + ataxiaTables.limbData.shikNervestrike >=  100 then  headpreppedNERV = true else headpreppedNERV = false end
if tLimbs.H + ataxiaTables.limbData.shikSpinkickHead >=  100 then  headpreppedSPIN = true else headpreppedSPIN = false end
if tLimbs.H + ataxiaTables.limbData.shikRisingkick >=  100 then  headpreppedRIS = true else headpreppedRIS = false end
if tLimbs.H + ataxiaTables.limbData.shikHiru >=  100 then  headpreppedHIRU = true else headpreppedHIRU = false end
if tLimbs.H + ataxiaTables.limbData.shikHiraku >=  100 then  headpreppedHIRA = true  else headpreppedHIRA = false end
if tLimbs.H + ataxiaTables.limbData.shikNeedle >=  100 then  headpreppedNEED = true  else headpreppedNEED = false end
if tLimbs.H + ataxiaTables.limbData.shikNervestrike + ataxiaTables.limbData.shikRisingkick >=  100 then  headpreppedNERVRIS = true else headpreppedNERVRIS = false end
if tLimbs.H + ataxiaTables.limbData.shikNeedle >=  100 then  headpreppedNEED = true else headpreppedNEED = false end

  
 
 if tAffs.shield then
 
     table.insert(shikudo,"shatter")
 end
 
 if tAffs.prone and tAffs.damagedhead and tAffs.crushedthroat then
table.insert(shikudo,"dispatch")
end
 
 
-- TYKONOS --




if ataxia.vitals.form == "Tykonos" then

if

 not tAffs.prone then
 table.insert(shikudo,"sweep")
  table.insert(shikudo,"risingkick head")
 table.insert(shikudo,"risingkick head")
end



end

-- WILLOW --

if ataxia.vitals.form == "Willow" then
if
shikudo[1] ~= "shatter" then
if ataxiaTemp.parriedLimb ~= "left leg" and not leftlegpreppedFLASH then
 table.insert(shikudo,"flashheel left")
  table.insert(shikudo,"hiraku")
  table.insert(shikudo,"hiru")
  
  elseif ataxiaTemp.parriedLimb == "left leg" and not rightlegpreppedFLASH then
   table.insert(shikudo,"flashheel right")
  table.insert(shikudo,"hiraku")
  table.insert(shikudo,"hiru")
 end

end

 end
 
 
  -- OAK --


if ataxia.vitals.form == "Oak" then
table.insert(shikudo,"risingkick torso")







if tAffs.brokenleftarm and tAffs.brokenrightarm and tAffs.asthma and not tAffs.slickness then
        table.insert(shikudo,"ruku torso")
end


if not leftlegpreppedKUR then

       table.insert(shikudo,"kuro left")
end


if not rightlegpreppedKUR  then 
       table.insert(shikudo,"kuro right")

  end

if not leftarmpreppedRUK and ataxiaTemp.parriedLimb ~= "left arm" then 

        table.insert(shikudo,"ruku left")
end
if not rightarmpreppedRUK then
       table.insert(shikudo,"ruku right")
end
if not tAffs.asthma then
      table.insert(shikudo,"livestrike")
end



end
 
-- RAIN --



 if ataxia.vitals.form == "Rain" then

if ataxiaTemp.parriedLimb ~= "left arm" and not leftarmpreppedFRO then
  table.insert(shikudo,"frontkick left")
  elseif ataxiaTemp.parriedLimb == "left arm" and not rightarmpreppedFRO then
  table.insert(shikudo,"frontkick right")
  elseif tLimbs.LA >= 90 and not rightarmpreppedFRO then
  table.insert(shikudo,"frontkick right")
  else
table.insert(shikudo,"frontkick right")
 end
 

if  not leftlegpreppedKUR then

       table.insert(shikudo,"kuro left")
end


if not rightlegpreppedKUR  then 
       table.insert(shikudo,"kuro right")

  end
  
 if leftlegpreppedKUR and not rightlegpreppedKUR and not rightarmpreppedRUK then 
          table.insert(shikudo,"ruku right")
            table.insert(shikudo,"kuro right")
 end
 
  if rightlegpreppedKUR and not leftlegpreppedKUR then 
          table.insert(shikudo,"ruku left")
            table.insert(shikudo,"kuro left")
 end
 
 if leftlegpreppedKUR and  rightlegpreppedKUR then 
          table.insert(shikudo,"ruku right")
          
 end
 if rightlegpreppedKUR and not leftarmpreppedRUK then 
          table.insert(shikudo,"ruku left")
 end
 
 if rightlegpreppedKUR and (leftarmpreppedRUK or rightarmpreppedRUK) then
         table.insert(shikudo,"hiru")
 end
 
  if leftlegpreppedKUR and (leftarmpreppedRUK or rightarmpreppedRUK) then
         table.insert(shikudo,"hiru")
 end

end

-- GAITAL --


if ataxia.vitals.form == "Gaital" then





if rightlegpreppedFLASH and leftlegpreppedKUR and rightarmpreppedRUK and leftarmpreppedRUK
then
table.insert(shikudo,"flashheel right")
  table.insert(shikudo,"kuro left")
  table.insert(shikudo,"ruku right")
end

if not tAffs.prone and tAffs.damagedhead then
table.insert(shikudo,"sweep")
  table.insert(shikudo,"spinkick")
end





if not tAffs.damagedleftleg and  not leftlegpreppedFLASH  then

       table.insert(shikudo,"flashheel left")
end

if not tAffs.damagedrightleg and not rightlegpreppedFLASH and shikudo[1] ~= "flashheel left"  then

       table.insert(shikudo,"flashheel right")
end




if not rightlegpreppedKUR and not tAffs.prone  then 
       table.insert(shikudo,"kuro right")

  end
  
  if not leftlegpreppedKUR and not tAffs.prone  then 
       table.insert(shikudo,"kuro left")

  end



if not rightarmpreppedRUK  then

       table.insert(shikudo,"ruku right")
end

if not rightarmpreppedRUK and rightlegpreppedKUR and leftlegpreppedKUR and leftarmpreppedRUK then

       table.insert(shikudo,"ruku right")
end

if not leftarmpreppedRUK  then

       table.insert(shikudo,"ruku left")
end

if
shikudo[1] ~= "shatter" and ataxiaTemp.shikCombo.kick ~= "flashheel" then
  table.insert(shikudo,"spinkick")

end



 


end



-- MAELSTROM --

if ataxia.vitals.form == "Maelstrom" then
if ataxiaTemp.lastAssess and ataxiaTemp.lastAssess <= 50 then
  table.insert(shikudo,"sweep")

 table.insert(shikudo,"crescent")
 end
 
if not tAffs.prone then 
 table.insert(shikudo,"sweep")
 table.insert(shikudo,"risingkick head")
 end
 
 if tAffs.prone then
  table.insert(shikudo,"risingkick head")
  end
 
 if tAffs.prone and not tAffs.damagedrightarm then
  table.insert(shikudo,"ruku right")
 end
 
  if tAffs.prone and not tAffs.damagedleftarm then
  table.insert(shikudo,"ruku left")
 end
 
 if tAffs.prone and not tAffs.addiction then
   table.insert(shikudo,"jinzuku")
 end
 
  if tAffs.prone and not tAffs.asthma then
   table.insert(shikudo,"livestrike")
 end
 
end


lock_base_attack()

end


