-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Levi  Scripts > Leviticus > Shikudo Script - Levi > Shikudo > Shikudo Needle Logic

function levishikudoneedle()
--Get Stance
--ataxia.vitals.form
--Get Kata Chain
--ataxia.vitals.kata

--Set Target Limb Parry
ataxiaTemp.parriedLimb = ataxiaTemp.parriedLimb or "none"


--ataxia_resetLimbTable()
 -- ataxiaTables.limbData

shikDart = ataxiaTables.limbData.shikDart
shikFlashheel = ataxiaTables.limbData.shikFlashheel
shikFrontkick = ataxiaTables.limbData.shikFrontkick
shikHiraku = ataxiaTables.limbData.shikHiraku
shikHiru = ataxiaTables.limbData.shikHiru
shikJinzuku = ataxiaTables.limbData.shikJinzuku
shikKuro = ataxiaTables.limbData.shikKuro
shikLivestrike = ataxiaTables.limbData.shikLivestrike
shikNeedle = ataxiaTables.limbData.shikNeedle
shikNervestrike = ataxiaTables.limbData.shikNervestrike
shikRisingkick = ataxiaTables.limbData.shikRisingkick
shikRuku = ataxiaTables.limbData.shikRuku
shikSpinkickHead = ataxiaTables.limbData.shikSpinkickHead
shikSpinkickTorso = ataxiaTables.limbData.shikSpinkickTorso
shikThrust = ataxiaTables.limbData.shikThrust

-- Set Prepped
  --Head Staff
if lb[target].hits["head"] + shikNervestrike >= 100 and not tAffs.damagedhead then 
shikNervestrikeprepped_head = true else
shikNervestrikeprepped_head = false
end
if lb[target].hits["head"] + shikNervestrike + shikRisingkick >= 100 and not tAffs.damagedhead then 
shikNervestrike2prepped_head = true else
shikNervestrike2prepped_head = false
end
if lb[target].hits["head"] + shikRisingkick >= 100 and not tAffs.damagedhead then 
shikRisingkickprepped_head = true else
shikRisingkickprepped_head = false
end
if lb[target].hits["head"] + shikNeedle >= 100 and not tAffs.damagedhead then 
shikNeedleprepped_head = true else
shikNeedleprepped_head = false
end
if lb[target].hits["head"] + shikNeedle + shikNeedle >= 100 and not tAffs.damagedhead then 
shikNeedle2prepped_head = true else
shikNeedle2prepped_head = false
end
if lb[target].hits["head"] + shikHiru >= 100 and not tAffs.damagedhead then 
shikHiruprepped_head = true else
shiHiruprepped_head = false
end
if lb[target].hits["head"] + shikHiru + shikHiru >= 100 and not tAffs.damagedhead then 
shikHiru2prepped_head = true else
shiHiru2prepped_head = false
end
if lb[target].hits["head"] + shikHiru + shikHiraku >= 100 and not tAffs.damagedhead then 
shikHiru3prepped_head = true else
shiHiru3prepped_head = false
end
if lb[target].hits["head"] + shikHiraku >= 100 and not tAffs.damagedhead then 
shikHirakuprepped_head = true else
shikHirakuprepped_head = false
end
if lb[target].hits["head"] + shikHiraku + shikHiraku >= 100 and not tAffs.damagedhead then 
shikHiraku2prepped_head = true else
shikHiraku2prepped_head = false
end
if lb[target].hits["head"] + shikHiru + shikHiraku >= 100 and not tAffs.damagedhead then 
shikHiraku3prepped_head = true else
shikHiraku3prepped_head = false
end

--Torso
if lb[target].hits["torso"] + shikRuku >= 100 and not tAffs.mildtramua then 
shikRukuprepped_torso = true else
shikRukuprepped_torso = false
end
if lb[target].hits["torso"] + shikRuku + shikRuku >= 100 and not tAffs.mildtramua then 
shikRuku2prepped_torso = true else
shikRuku2prepped_torso = false
end

if lb[target].hits["torso"] + shikSpinkickTorso >= 100 and not tAffs.mildtramua then 
shikSpinkickTorsoprepped_torso = true else
shikSpinkickTorsoprepped_torso = false
end
if lb[target].hits["torso"] + shikLivestrike >= 100 and not tAffs.mildtramua then 
shikLivestrikeprepped_torso = true else
shikLivestrikeprepped_torso = false
end
if lb[target].hits["torso"] + shikLivestrike + shikLivestrike >= 100 and not tAffs.mildtramua then 
shikLivestrike2prepped_torso = true else
shikLivestrike2prepped_torso = false
end

if lb[target].hits["torso"] + shikJinzuku >= 100 and not tAffs.mildtramua then 
shikJinzukuprepped_torso = true else
shikJinzukuprepped_torso = false
end
if lb[target].hits["torso"] + shikJinzuku + shikJinzuku >= 100 and not tAffs.mildtramua then 
shikJinzuku2prepped_torso = true else
shikJinzuku2prepped_torso = false
end

if lb[target].hits["torso"] + shikJinzuku + shikLivestrike >= 100 and not tAffs.mildtramua then 
shikJinzuku3prepped_torso = true else
shikJinzuku3prepped_torso = false
end

--Left Leg
if lb[target].hits["left leg"] + shikKuro >= 100 and not tAffs.damagedleftleg then 
shikKuroprepped_leftleg = true else
shikKuroprepped_leftleg = false
end
if lb[target].hits["left leg"] + shikKuro + shikKuro >= 100 and not tAffs.damagedleftleg then 
shikKuro2prepped_leftleg = true else
shikKuro2prepped_leftleg = false
end
if lb[target].hits["left leg"] + shikFlashheel >= 100 and not tAffs.damagedleftleg then 
shikFlashheelprepped_leftleg = true else
shikFlashheelprepped_leftleg = false
end

if lb[target].hits["left leg"] + shikFlashheel + shikKuro >= 100 and not tAffs.damagedleftleg then 
shikFlashheelprepped_leftleg = true else
shikFlashheelprepped_leftleg = false
end

--Right Leg
if lb[target].hits["right leg"] + shikKuro >= 100 and not tAffs.damagedrightleg then 
shikKuroprepped_rightleg = true else
shikKuroprepped_rightleg = false
end

if lb[target].hits["right leg"] + shikKuro + shikKuro >= 100 and not tAffs.damagedrightleg then 
shikKuro2prepped_rightleg = true else
shikKuro2prepped_rightleg = false
end

if lb[target].hits["right leg"] + shikFlashheel >= 100 and not tAffs.damagedrightleg then 
shikFlashheelprepped_rightleg = true else
shikFlashheelprepped_rightleg = false
end

--Left Arm
if lb[target].hits["left arm"] + shikFrontkick >= 100 and not tAffs.damagedleftarm then 
shikFrontkickprepped_leftarm = true else
shikFrontkickprepped_leftarm = false
end
if lb[target].hits["left arm"] + shikRuku >= 100 and not tAffs.damagedleftarm then 
shikRukuprepped_leftarm = true else
shikRukuprepped_leftarm = false
end

if lb[target].hits["left arm"] + shikRuku + shikFrontkick >= 100 and not tAffs.damagedleftarm then 
shikRuku3prepped_leftarm = true else
shikRuku3prepped_leftarm = false
end

if lb[target].hits["left arm"] + shikRuku + shikRuku >= 100 and not tAffs.damagedleftarm then 
shikRuku2prepped_leftarm = true else
shikRuku2prepped_leftarm = false
end

--Right Arm
if lb[target].hits["right arm"] + shikFrontkick >= 100 and not tAffs.damagedrightarm then 
shikFrontkickprepped_rightarm = true else
shikFrontkickprepped_rightarm = false
end
if lb[target].hits["right arm"] + shikRuku >= 100 and not tAffs.damagedrightarm then 
shikRukuprepped_rightarm = true else
shikRukuprepped_rightarm = false
end

if lb[target].hits["right arm"] + shikRuku + shikFrontkick >= 100 and not tAffs.damagedrightarm then 
shikRuku3prepped_rightarm = true else
shikRuku3prepped_rightarm = false
end

if lb[target].hits["right arm"] + shikRuku + shikRuku >= 100 and not tAffs.damagedrightarm then 
shikRuku2prepped_rightarm = true else
shikRuku2prepped_rightarm = false
end


--Set Kicked Table
shikudokick = {}

if ataxia.vitals.form == "Rain" then
  if tAffs.prone and tAffs.damagedrightleg or lb[target].hits["right leg"] >= 100 and not tAffs.damageleftleg or lb[target].hits["left leg"] >= 100 then
    table.insert(shikudokick, "frontkick left")
  elseif tAffs.prone and tAffs.damagedleftleg or lb[target].hits["left leg"] >= 100 and not tAffs.damagerightleg or lb[target].hits["right leg"] >= 100 then
    table.insert(shikudokick, "frontkick right")
  elseif shikRuku3prepped_leftarm and ataxiaTemp.parriedLimb ~= "left arm" then
    table.insert(shikudokick, "frontkick left")
  elseif shikRuku3prepped_rightarm and ataxiaTemp.parriedLimb ~= "right arm" then
    table.insert(shikudokick, "frontkick right")
  elseif shikFrontkickprepped_leftarm and not shikFrontkickprepped_rightarm and ataxiaTemp.parriedLimb ~= "right arm" then
    table.insert(shikudokick, "frontkick right")
  elseif not shikFrontkickprepped_leftarm and shikFrontkickprepped_rightarm and ataxiaTemp.parriedLimb ~= "left arm" then
    table.insert(shikudokick, "frontkick left")
  elseif not shikFrontkickprepped_leftarm and ataxiaTemp.parriedLimb ~= "left arm" then
    table.insert(shikudokick, "frontkick left")
  elseif not shikFrontkickprepped_rightarm and ataxiaTemp.parriedLimb ~= "right arm" then
    table.insert(shikudokick, "frontkick right")
  end
elseif ataxia.vitals.form == "Oak" then
  if shikNervestrike2prepped_head and ataxiaTemp.parriedLimb ~= "head" then
    table.insert(shikudokick, "risingkick head")
  elseif shikRisingkickprepped_head and ataxiaTemp.parriedLimb ~= "torso" then
    table.insert(shikudokick, "risingkick torso")
  elseif not shikRisingkickprepped_head and ataxiaTemp.parriedLimb ~= "head" then
    table.insert(shikudokick, "risingkick head")
  end
elseif ataxia.vitals.form == "Gaital" then
  if tAffs.prone and (lb[target].hits["head"] >= 100 or tAffs.damagedhead) then
    table.insert(shikudokick, "spinkick")
  elseif tAffs.prone and shikFlashheelprepped_rightleg and tAffs.damagedleftleg or lb[target].hits["left leg"] >= 100 then
    table.insert(shikudokick, "flashheel right")
  elseif tAffs.prone and shikFlashheelprepped_leftleg and tAffs.damagedrightleg or lb[target].hits["right leg"] >= 100 then
    table.insert(shikudokick, "flashheel left")
  elseif not tAffs.prone and shikFlashheelprepped_rightleg and ataxiaTemp.parriedLimb ~= "right leg" and shikFlashheelprepped_leftleg and shikRukuprepped_rightarm and shikRukuprepped_leftarm  then
    table.insert(shikudokick, "flashheel right")
  elseif not tAffs.prone and shikFlashheelprepped_leftleg and ataxiaTemp.parriedLimb ~= "left leg" and shikFlashheelprepped_rightleg and shikRukuprepped_rightarm and shikRukuprepped_leftarm  then
    table.insert(shikudokick, "flashheel left")
  else
    table.insert(shikudokick, "dawnkick")
  end
elseif ataxia.vitals.form == "Maelstrom" then
  if php <= 40 then 
    table.insert(shikudokick, "crescent")
  elseif shikRisingkickprepped_head and ataxiaTemp.parriedLimb ~= "torso" then
    table.insert(shikudokick, "risingkick torso")
  elseif not shikRisingkickprepped_head and ataxiaTemp.parriedLimb ~= "head" then
    table.insert(shikudokick, "risingkick head")
  end
elseif ataxia.vitals.form == "Willow" then
  if shikFlashheelprepped_leftleg and not shikFlashheelprepped_rightleg and ataxiaTemp.parriedLimb ~= "right leg" then
    table.insert(shikudokick, "flashheel right")
  elseif not shikFlashheelprepped_leftleg and shikFlashheelprepped_rightleg and ataxiaTemp.parriedLimb ~= "left leg" then
    table.insert(shikudokick, "flashheel left")
  elseif not shikFlashheelprepped_leftleg and ataxiaTemp.parriedLimb ~= "left leg" then
    table.insert(shikudokick, "flashheel left")
  elseif not shikFlashheelprepped_rightleg and ataxiaTemp.parriedLimb ~= "right leg" then
    table.insert(shikudokick, "flashheel right")
  end
elseif ataxia.vitals.form == "Tykonos" then
  table.insert(shikudokick, "risingkick torso")
end


--Set Staff One Table
shikudostaffone = {}

if ataxia.vitals.form == "Rain" then
  if not shikKuro2prepped_leftleg and shikKuro2prepped_rightleg and ataxiaTemp.parriedLimb ~= "left leg" then
    table.insert(shikudostafftwo, "kuro left")
  elseif shikKuro2prepped_leftleg and not shikKuro2prepped_rightleg and ataxiaTemp.parriedLimb ~= "right leg" then
    table.insert(shikudostafftwo, "kuro right")
  elseif not shikKuroprepped_leftleg and ataxiaTemp.parriedLimb ~= "left leg" then
    table.insert(shikudostaffone, "kuro left")
  elseif not shikKuroprepped_rightleg and ataxiaTemp.parriedLimb ~= "right leg" then
    table.insert(shikudostaffone, "kuro right")
  elseif not shikHiruprepped_head and ataxiaTemp.parriedLimb ~= "head" then
    table.insert(shikudostaffone, "hiru")
  elseif not shikRukuprepped_rightarm and ataxiaTemp.parriedLimb ~= "right arm" and not shikFrontkickprepped_rightarm then
    table.insert(shikudostaffone, "ruku right")
  elseif not shikRukuprepped_leftarm and ataxiaTemp.parriedLimb ~= "left arm" and not shikFrontkickprepped_leftarm then
    table.insert(shikudostaffone, "ruku left")
  else
    table.insert(shikudostaffone, "ruku torso")
  end
elseif ataxia.vitals.form == "Gaital" then
  if (lb[target].hits["head"] >= 100 or tAffs.damagedhead) and not tAffs.prone then
    table.insert(shikudostaffone, "sweep")
  elseif tAffs.prone and (lb[target].hits["head"] >= 100 or tAffs.damagedhead or tAffs.mangledhead) and not tAffs.crushedthroat then
    table.insert(shikudostaffone, "needle")
  elseif tAffs.prone and tAffs.damagedrightleg and tAffs.damageleftleg and shikRukuprepped_rightarm and not tAffs.damagedrightarm then
    table.insert(shikudostaffone, "ruku right")
  elseif tAffs.prone and tAffs.damagedrightleg and tAffs.damageleftleg and shikRukuprepped_leftarm and not tAffs.damagedleftarm then
    table.insert(shikudostaffone, "ruku left")
  elseif not tAffs.prone and shikFlashheelprepped_leftleg and shikFlashheelprepped_rightleg and shikRukuprepped_rightarm and shikRukuprepped_leftarm  then 
    table.insert(shikudostaffone, "sweep")
  elseif not tAffs.prone and shikFlashheelprepped_rightleg  and shikFlashheelprepped_leftleg and shikRukuprepped_rightarm and shikRukuprepped_leftarm  then
    table.insert(shikudostaffone, "sweep")
  elseif shikNeedle2prepped_head then
    table.insert(shikudostaffone, "needle")
  elseif shikNeedleprepped_head then
    table.insert(shikudostaffone, "needle")
  elseif tAffs.prone and (lb[target].hits["head"] >= 100 or tAffs.damagedhead) and tAffs.crushedthroat then
    table.insert(shikudostaffone, "ruku torso")
  end
elseif ataxia.vitals.form == "Maelstrom" then
  if php <= 40 then
    table.insert(shikudostaffone, "sweep")
  elseif not shikRukuprepped_rightarm and ataxiaTemp.parriedLimb ~= "right arm" then
    table.insert(shikudostaffone, "ruku right")
  elseif not shikRukuprepped_rightarm and ataxiaTemp.parriedLimb ~= "left arm" then
    table.insert(shikudostaffone, "ruku left")
  elseif not tAffs.asthma then
    table.insert(shikudostaffone, "livestrike")
  elseif not tAffs.slickness then
    table.insert(shikudostaffone, "ruku torso")
  elseif not tAffs.addiction then
    table.insert(shikudostaffone, "jinzuku")
  else
    table.insert(shikudostaffone, "sweep")
  end
elseif ataxia.vitals.form == "Oak" then
  if shikKuro2prepped_leftleg and not shikKuro2prepped_rightleg and ataxiaTemp.parriedLimb ~= "right leg" then
    table.insert(shikudostaffone, "kuro right")
  elseif not shikKuro2prepped_leftleg and not shikKuro2prepped_rightleg and ataxiaTemp.parriedLimb ~= "left leg" then
    table.insert(shikudostaffone, "kuro left")
  elseif shikNervestrike2prepped_head and ataxiaTemp.parriedLimb ~= "head" then
    table.insert(shikudostaffone, "livestrike")
  elseif not shikKuroprepped_leftleg and ataxiaTemp.parriedLimb ~= "left leg" then
    table.insert(shikudostaffone, "kuro left")
  elseif not shikKuroprepped_rightleg and ataxiaTemp.parriedLimb ~= "right leg" then
    table.insert(shikudostaffone, "kuro right")
  elseif not shikNervestrike2prepped_head and ataxiaTemp.parriedLimb ~= "head" then
    table.insert(shikudostaffone, "nervestrike")
  elseif not shikRukuprepped_rightarm and ataxiaTemp.parriedLimb ~= "right arm" then
    table.insert(shikudostaffone, "ruku right")
  elseif not shikRukuprepped_leftarm and ataxiaTemp.parriedLimb ~= "left arm" then
    table.insert(shikudostaffone, "ruku left")
  else 
    table.insert(shikudostaffone, "livestrike")
  end
elseif ataxia.vitals.form == "Willow" then
  if not tAffs.prone and shikFlashheelprepped_leftleg and shikFlashheelprepped_rightleg and shikRukuprepped_rightarm and shikRukuprepped_leftarm  then 
    table.insert(shikudostaffone, "sweep")
  elseif not tAffs.prone and shikFlashheelprepped_rightleg and shikFlashheelprepped_leftleg and shikRukuprepped_rightarm and shikRukuprepped_leftarm  then
    table.insert(shikudostaffone, "sweep")
  elseif shikHiruprepped_head then
    table.insert(shikudostaffone, "dart torso")
  elseif not shikHiruprepped_head then
    table.insert(shikudostaffone, "hiru")
  else 
    table.insert(shikudostaffone, "sweep")
  end
end


--Set Staff Two Table
shikudostafftwo = {}

if ataxia.vitals.form == "Rain" then
  if not shikKuro2prepped_leftleg and shikKuro2prepped_rightleg and ataxiaTemp.parriedLimb ~= "left leg" and shikudostaffone[1] ~= "kuro right" then
    table.insert(shikudostafftwo, "kuro left")
  elseif shikKuro2prepped_leftleg and not shikKuro2prepped_rightleg and ataxiaTemp.parriedLimb ~= "right leg" and shikudostaffone[1] ~= "kuro right" then
    table.insert(shikudostafftwo, "kuro right")
  elseif not shikKuroprepped_leftleg and ataxiaTemp.parriedLimb ~= "left leg" and shikudostaffone[1] ~= "kuro left" then
    table.insert(shikudostafftwo, "kuro left")
  elseif not shikKuroprepped_rightleg and ataxiaTemp.parriedLimb ~= "right leg" and shikudostaffone[1] ~= "kuro right" then
    table.insert(shikudostafftwo, "kuro right")
  elseif not shikHiruprepped_head and ataxiaTemp.parriedLimb ~= "head" and shikudostaffone[1] ~= "hiru" then
    table.insert(shikudostafftwo, "hiru")
  elseif not shikRukuprepped_rightarm and ataxiaTemp.parriedLimb ~= "right arm" and not shikFrontkickprepped_rightarm then
    table.insert(shikudostafftwo, "ruku right")
  elseif not shikRukuprepped_leftarm and ataxiaTemp.parriedLimb ~= "left arm" and not shikFrontkickprepped_leftarm then
    table.insert(shikudostafftwo, "ruku left")
  else
    table.insert(shikudostafftwo, "ruku torso")
  end
elseif ataxia.vitals.form == "Gaital" then
  if (lb[target].hits["head"] >= 100 or tAffs.damagedhead) and not tAffs.prone then
    table.insert(shikudostafftwo, "sweep")
  elseif tAffs.prone and (lb[target].hits["head"] >= 100 or tAffs.damagedhead or tAffs.mangledhead) and not tAffs.crushedthroat and shikudostaffone[1] ~= "needle" then
    table.insert(shikudostafftwo, "needle")
  elseif tAffs.prone and tAffs.damagedrightleg and tAffs.damageleftleg and shikRukuprepped_rightarm and not tAffs.damagedrightarm and shikudostaffone[1] ~= "ruku right" then
    table.insert(shikudostafftwo, "ruku right")
  elseif tAffs.prone and tAffs.damagedrightleg and tAffs.damageleftleg and shikRukuprepped_leftarm and not tAffs.damagedleftarm and shikudostaffone[1] ~= "ruku left" then
    table.insert(shikudostafftwo, "ruku left")
  elseif not tAffs.prone and shikFlashheelprepped_leftleg and shikFlashheelprepped_rightleg and shikRukuprepped_rightarm and shikRukuprepped_leftarm  then 
    table.insert(shikudostafftwo, "sweep")
  elseif not tAffs.prone and shikFlashheelprepped_rightleg  and shikFlashheelprepped_leftleg and shikRukuprepped_rightarm and shikRukuprepped_leftarm  then
    table.insert(shikudostafftwo, "sweep")
  elseif shikNeedle2prepped_head and shikudostaffone[1] ~= "needle" then
    table.insert(shikudostafftwo, "needle")
  elseif shikNeedleprepped_head then
    table.insert(shikudostafftwo, "needle")
  elseif tAffs.prone and (lb[target].hits["head"] >= 100 or tAffs.damagedhead) and tAffs.crushedthroat then
    table.insert(shikudostafftwo, "ruku torso")
  end
elseif ataxia.vitals.form == "Maelstrom" then
  if php <= 40 then
    table.insert(shikudostafftwo, "sweep")
  elseif not shikRuku2prepped_rightarm and ataxiaTemp.parriedLimb ~= "right arm" then
    table.insert(shikudostafftwo, "ruku right")
  elseif shikRuku2prepped_rightarm and ataxiaTemp.parriedLimb ~= "left arm" and shikudostaffone[1] ~= "ruku left" then
    table.insert(shikudostafftwo, "ruku left")
  elseif shikRukuprepped_rightarm and ataxiaTemp.parriedLimb ~= "right arm" and shikudostaffone[1] ~= "ruku right" then
    table.insert(shikudostafftwo, "ruku right")
  elseif not shikRukuprepped_rightarm and ataxiaTemp.parriedLimb ~= "left arm" then
    table.insert(shikudostafftwo, "ruku left")
  elseif not tAffs.asthma and shikudostaffone[1] ~= "livestrike" then
    table.insert(shikudostafftwo, "livestrike")
  elseif not tAffs.slickness then
    table.insert(shikudostafftwo, "ruku torso")
  elseif not tAffs.addiction and shikudostaffone[1] ~= "jinzuku" then
    table.insert(shikudostafftwo, "jinzuku")
  else
    table.insert(shikudostafftwo, "jinzuku")
  end
elseif ataxia.vitals.form == "Oak" then
  if shikKuro2prepped_leftleg and not shikKuro2prepped_rightleg and ataxiaTemp.parriedLimb ~= "right leg" and shikudostaffone[1] ~= "kuro right" then
    table.insert(shikudostafftwo, "kuro right")
  elseif not shikKuro2prepped_leftleg and not shikKuro2prepped_rightleg and ataxiaTemp.parriedLimb ~= "left leg" and shikudostaffone[1] ~= "kuro left" then
    table.insert(shikudostafftwo, "kuro left")
  elseif not shikKuroprepped_leftleg and ataxiaTemp.parriedLimb ~= "left leg" then
    table.insert(shikudostafftwo, "kuro left")
  elseif not shikKuroprepped_rightleg and ataxiaTemp.parriedLimb ~= "right leg" then
    table.insert(shikudostafftwo, "kuro right")
  elseif shikNervestrike2prepped_head and ataxiaTemp.parriedLimb ~= "head" and shikudostaffone[1] ~= "livestrike" then
    table.insert(shikudostafftwo, "livestrike")
  elseif not shikNervestrike2prepped_head and ataxiaTemp.parriedLimb ~= "head" and shikudostaffone[1] ~= "nervestrike" then
    table.insert(shikudostafftwo, "nervestrike")
  elseif not shikRuku2prepped_rightarm and ataxiaTemp.parriedLimb ~= "right arm" then
    table.insert(shikudostafftwo, "ruku right")
  elseif not shikRuku2prepped_leftarm and ataxiaTemp.parriedLimb ~= "left arm" then
    table.insert(shikudostafftwo, "ruku left")
  elseif not shikRukuprepped_rightarm and ataxiaTemp.parriedLimb ~= "right arm" and shikudostaffone[1] ~= "ruku right" then
    table.insert(shikudostafftwo, "ruku right")
  elseif not shikRukuprepped_leftarm and ataxiaTemp.parriedLimb ~= "left arm" and shikudostaffone[1] ~= "ruku left" then
    table.insert(shikudostafftwo, "ruku left")
  else 
    table.insert(shikudostafftwo, "livestrike")
  end
elseif ataxia.vitals.form == "Willow" then
  if not tAffs.prone and shikFlashheelprepped_leftleg and shikFlashheelprepped_rightleg and shikRukuprepped_rightarm and shikRukuprepped_leftarm  then 
    table.insert(shikudostafftwo, "sweep")
  elseif not tAffs.prone and shikFlashheelprepped_rightleg and shikFlashheelprepped_leftleg and shikRukuprepped_rightarm and shikRukuprepped_leftarm  then
    table.insert(shikudostafftwo, "sweep")
  elseif shikHirakuprepped_head then
    table.insert(shikudostafftwo, "dart torso")
  elseif not shikHirakuprepped_head and shikudostaffone[1] ~= "hiraku" then
    table.insert(shikudostafftwo, "hiraku")
  else 
    table.insert(shikudostafftwo, "dart torso")
  end
end

levishikudoneedleattack()
end


function levishikudoneedleattack()
local atk = combatQueue()

if tAffs.shield then
  atk = atk.."wield staff489282;combo " ..target.. " shatter " ..shikudokick[1].. " " ..shikudostaffone[1]
elseif not tAffs.prone and shikFlashheelprepped_leftleg and shikFlashheelprepped_rightleg and shikRukuprepped_rightarm and shikRukuprepped_leftarm and ataxia.vitals.form == "Oak" and ataxia.vitals.kata >= 2 then
  atk = atk.."wield staff489282;combo " ..target.. " " ..shikudokick[1].. " " ..shikudostaffone[1].. " " ..shikudostafftwo[1].. ";transition to the gaital form "  

elseif ataxia.vitals.kata == 21 and ataxia.vitals.form == "Gaital" then
  atk = atk.."wield staff489282;combo " ..target.. " " ..shikudokick[1].. " " ..shikudostaffone[1].. " " ..shikudostafftwo[1].. ";transition to the willow form "  
elseif ataxia.vitals.kata >= 19 and ataxia.vitals.form == "Gaital" then
  atk = atk.."wield staff489282;combo " ..target.. " " ..shikudokick[1].. " " ..shikudostaffone[1].. " " ..shikudostafftwo[1].. ";transition to the willow form " 
elseif ataxia.vitals.kata < 19 and ataxia.vitals.form == "Gaital" then
  atk = atk.."wield staff489282;combo " ..target.. " " ..shikudokick[1].. " " ..shikudostaffone[1].. " " ..shikudostafftwo[1]


elseif ataxia.vitals.kata == 21 and ataxia.vitals.form == "Rain" then
  atk = atk.."wield staff489282;combo " ..target.. " " ..shikudokick[1].. " " ..shikudostaffone[1].. " " ..shikudostafftwo[1].. ";transition to the oak form "  
elseif ataxia.vitals.kata >= 19 and ataxia.vitals.form == "Rain" then
  atk = atk.."wield staff489282;combo " ..target.. " " ..shikudokick[1].. " " ..shikudostaffone[1].. " " ..shikudostafftwo[1].. ";transition to the oak form " 
elseif ataxia.vitals.kata < 19 and ataxia.vitals.form == "Rain" then
  atk = atk.."wield staff489282;combo " ..target.. " " ..shikudokick[1].. " " ..shikudostaffone[1].. " " ..shikudostafftwo[1]

elseif ataxia.vitals.kata == 9 and ataxia.vitals.form == "Oak" then
  atk = atk.."wield staff489282;combo " ..target.. " " ..shikudokick[1].. " " ..shikudostaffone[1].. " " ..shikudostafftwo[1].. ";transition to the willow form "  
elseif ataxia.vitals.kata >= 8 and ataxia.vitals.form == "Oak" then
  atk = atk.."wield staff489282;combo " ..target.. " " ..shikudokick[1].. " " ..shikudostaffone[1].. " " ..shikudostafftwo[1].. ";transition to the willow form " 
elseif ataxia.vitals.kata < 8 and ataxia.vitals.form == "Oak" then
  atk = atk.."wield staff489282;combo " ..target.. " " ..shikudokick[1].. " " ..shikudostaffone[1].. " " ..shikudostafftwo[1]

elseif ataxia.vitals.kata == 9 and ataxia.vitals.form == "Willow" then
  atk = atk.."wield staff489282;combo " ..target.. " " ..shikudokick[1].. " " ..shikudostaffone[1].. " " ..shikudostafftwo[1].. ";transition to the rain form "  
elseif ataxia.vitals.kata >= 8 and ataxia.vitals.form == "Willow" then
  atk = atk.."wield staff489282;combo " ..target.. " " ..shikudokick[1].. " " ..shikudostaffone[1].. " " ..shikudostafftwo[1].. ";transition to the rain form " 
elseif ataxia.vitals.kata < 8 and ataxia.vitals.form == "Willow" then
  atk = atk.."wield staff489282;combo " ..target.. " " ..shikudokick[1].. " " ..shikudostaffone[1].. " " ..shikudostafftwo[1]
end

if table.contains(ataxia.playersHere, target) then
send("queue addclear free " ..atk)
end



end







