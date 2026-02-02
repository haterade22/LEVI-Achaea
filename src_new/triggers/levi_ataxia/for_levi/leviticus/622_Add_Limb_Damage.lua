--[[mudlet
type: trigger
name: Add Limb Damage
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Affs Post Queue - Gated
attributes:
  isActive: 'yes'
  isFolder: 'no'
  isTempTrigger: 'no'
  isMultiline: 'no'
  isPerlSlashGOption: 'no'
  isColorizerTrigger: 'no'
  isFilterTrigger: 'no'
  isSoundTrigger: 'no'
  isColorTrigger: 'no'
  isColorTriggerFg: 'no'
  isColorTriggerBg: 'no'
triggerType: 0
conditonLineDelta: 0
mStayOpen: 0
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ^As your blow lands with a crunch, you perceive that you have dealt ([0-9.]+)\% damage to (\w+)'s (torso|head|left
    arm|right arm|right leg|left leg)\.$
  type: 1
- pattern: ^As you carve into (\w+)\, you perceive that you have dealt ([0-9.]+)\% damage to (\w+) (torso|head|left arm|right
    arm|right leg|left leg)\.$
  type: 1
- pattern: ^As the immaterial cleaves the material, you perceive that you have dealt ([0-9.]+)\% damage to (\w+)'s (torso|head|left
    arm|right arm|right leg|left leg)\.$
  type: 1
]]--

if lb[target].hits["left leg"] >= 100 and lb[target].hits["left leg"] <= 199 then
tarAffed("damagedleftleg")
if applyAffV3 then applyAffV3("damagedleftleg") end
elseif lb[target].hits["right leg"] >= 100 and lb[target].hits["right leg"] <= 199 then
tarAffed("damagedrightleg")
if applyAffV3 then applyAffV3("damagedrightleg") end
elseif lb[target].hits["right arm"] >= 100 and lb[target].hits["right arm"] <= 199 then
tarAffed("damagedrightarm")
if applyAffV3 then applyAffV3("damagedrightarm") end
elseif lb[target].hits["left arm"] >= 100 and lb[target].hits["left arm"] <= 199 then
tarAffed("damagedleftarm")
if applyAffV3 then applyAffV3("damagedleftarm") end
elseif lb[target].hits["torso"] >= 100 and lb[target].hits["torso"] <= 199 then
tarAffed("mildtrauma")
if applyAffV3 then applyAffV3("mildtrauma") end
elseif lb[target].hits["head"] >= 100 and lb[target].hits["head"] <= 199 then
tarAffed("damagedhead")
if applyAffV3 then applyAffV3("damagedhead") end
end

if lb[target].hits["left leg"] >= 200 then
tarAffed("mangledleftleg")
if applyAffV3 then applyAffV3("mangledleftleg") end
elseif lb[target].hits["right leg"] >= 200 then
tarAffed("mangledrightleg")
if applyAffV3 then applyAffV3("mangledrightleg") end
elseif lb[target].hits["right arm"] >= 200 then
tarAffed("mangledrightarm")
if applyAffV3 then applyAffV3("mangledrightarm") end
elseif lb[target].hits["left arm"] >= 200 then
tarAffed("mangledleftarm")
if applyAffV3 then applyAffV3("mangledleftarm") end
elseif lb[target].hits["torso"] >= 200 then
tarAffed("serioustrauma")
if applyAffV3 then applyAffV3("serioustrauma") end
elseif lb[target].hits["head"] >= 200 then
tarAffed("concussion")
if applyAffV3 then applyAffV3("concussion") end
end


local toDam, tar, limb

if tonumber(matches[2]) then
  toDam, tar, limb = tonumber(matches[2]), matches[3], matches[4]
else
  toDam, tar, limb = tonumber(matches[3]), matches[2], matches[5]
end
local toLimb = ataxia_shortLimb(limb)

if not lastLimbAttack then echo("?") return end
if isTargeted(tar) then
  if ataxiaTables.limbData[lastLimbAttack] ~= toDam then
    ataxia_updateLimbHit(lastLimbAttack, toDam)
  end
  ataxia_addLimbDamage(lastLimbAttack, limb)

  --Colour the line as per the highlighting option.
  if ataxia.settings.highlighting and ataxia.settings.highlighting.limbs then
    selectString(line,1)
    if limbPrepped(limb, lastLimbAttack) then
      fg("red")
    elseif tLimbs[toLimb] >= 80 then
      fg("orange")
    elseif tLimbs[toLimb] >= 60 then
      fg("yellow")
    elseif tLimbs[toLimb] >= 40 then
      fg("GreenYellow")
    else
      fg("powder_blue")
    end
    cecho(" <purple>(<NavajoWhite>"..tLimbs[toLimb].."<purple>%)")
  end
  
  if lastLimbAttack == "bmSlash" then
    lastLimbAttack = "bmOffSlash"
    ataxiaTables.limbData.bmCompass = ataxiaTables.limbData.bmSlash - 0.4
  elseif lastLimbAttack == "bmOffSlash" or lastLimbAttack == "bmCompass" then
    ataxia_updateBlademasterBases()
    if ataxiaTables.limbData.bmProblemslash == nil then
      ataxia_blademasterNeedComp()
    end    
  end
end