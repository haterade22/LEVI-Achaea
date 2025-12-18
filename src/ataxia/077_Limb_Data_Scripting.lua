-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Ataxia-DownloadThis > Ataxia > Combat > Offensive Things > Limb Management > Limb Data/Scripting

function ataxia_resetLimbTable()
  ataxiaTables.limbData = {
    --Shikudo Attacks
    shikThrust = 10,
    shikDart = 10,
    shikFlashheel = 10,
    shikRisingkick = 10,
    shikHiraku = 10,
    shikHiru = 10,
    shikRuku = 10,
    shikFrontkick = 10,
    shikKuro = 10,
    shikLivestrike = 10,
    shikNervestrike = 10,
    shikNeedle = 15,
    shikSpinkickHead = 20,
    shikSpinkickTorso = 13,
    shikJinzuku = 8,
    
    --Tekura Attacks
    tekuraSDK = 25,
    tekuraWWK = 25,
    tekuraAXK = 25,
    tekuraSNK = 25,
    tekuraMNK = 25,
    tekuraHKP = 14,
    tekuraUCP = 14,
    tekuraHFP = 14,
    tekuraSPP = 14,
    
    --Bard
    
    bardRapier = 8,
    
    --Knights
    snbSlice = 8,
    twoHander = 10,
    dwcSlash = 8,
    dwbWhirl = 20,
    dwbMWhirl = 14,
    dwbFWhirl = 22,
    
    --Blademaster
    bmCompass = 19,
    bmSlash = 20,
    bmOffSlash = 13,
    
    bmBaseCompass = 0,
    bmBaseSlash = 0,
    bmBaseOffSlash = 0,
    
    --Forestal
    metaMaul = 25,
    thornrend = 25,
    sentSpear = 9,
    sentTrip = 5,
    
    --Other
    dragonRend = 30,  
    weaponryAxe = 15,
    priestSmite = 14,
    psionweaves = 25,
  }
  cecho("\n<DodgerBlue> >> <a_green>limb values reset <DodgerBlue><<")
end

function ataxia_updateLimbHit(attack, value)
  ataxiaTables.limbData[attack] = value
end

function ataxia_shortLimb(limb)
	local limbs = {
		["head"] = "H",
		["torso"] = "T",
		["left leg"] = "LL",
		["right leg"] = "RL",
		["left arm"] = "LA",
		["right arm"] = "RA",
	}
  return limbs[limb:lower()] or "H"
end

function ataxia_addLimbDamage(attack, limb)	
  local l = ataxia_shortLimb(limb)
  local x = ataxiaTables.limbData[attack]
  tLimbs[l] = tLimbs[l] + x
  if tLimbs[l] > 99.9 then
    cecho("\n<red> -= "..limb.." broke! =-")
    if limb == "head" then tAffs.stupidity = true end
		target_limbBroke(limb)
  end
  targetLimbs_updateTimers(limb)
end

function limbPrepped(limb, attack)
  local l = ataxia_shortLimb(limb)
  local x = ataxiaTables.limbData[attack] or 1
  return (tLimbs[l] + x >= 100)
end