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
elseif lb[target].hits["right leg"] >= 100 and lb[target].hits["right leg"] <= 199 then
tarAffed("damagedrightleg")
elseif lb[target].hits["right arm"] >= 100 and lb[target].hits["right arm"] <= 199 then
tarAffed("damagedrightarm")
elseif lb[target].hits["left arm"] >= 100 and lb[target].hits["left arm"] <= 199 then
tarAffed("damagedleftarm")
elseif lb[target].hits["torso"] >= 100 and lb[target].hits["torso"] <= 199 then
tarAffed("mildtrauma")
elseif lb[target].hits["head"] >= 100 and lb[target].hits["head"] <= 199 then
tarAffed("damagedhead")
end

if lb[target].hits["left leg"] >= 200 then
tarAffed("mangledleftleg")
elseif lb[target].hits["right leg"] >= 200 then
tarAffed("mangledrightleg")
elseif lb[target].hits["right arm"] >= 200 then
tarAffed("mangledrightarm")
elseif lb[target].hits["left arm"] >= 200 then
tarAffed("mangledleftarm")
elseif lb[target].hits["torso"] >= 200 then
tarAffed("serioustrauma")
elseif lb[target].hits["head"] >= 200 then
tarAffed("concussion")
end


local tar, limb

if tonumber(matches[2]) then
  tar, limb = matches[3], matches[4]
else
  tar, limb = matches[2], matches[5]
end

if not lastLimbAttack then echo("?") return end
if isTargeted(tar) then
  --Colour the line as per the highlighting option.
  if ataxia.settings.highlighting and ataxia.settings.highlighting.limbs then
    local lbHits = lb[target] and lb[target].hits and lb[target].hits[limb] or 0
    selectString(line,1)
    if lbHits + (mylimbattackpercentage or 0) >= 100 then
      fg("red")
    elseif lbHits >= 80 then
      fg("orange")
    elseif lbHits >= 60 then
      fg("yellow")
    elseif lbHits >= 40 then
      fg("GreenYellow")
    else
      fg("powder_blue")
    end
    cecho(" <purple>(<NavajoWhite>"..lbHits.."<purple>%)")
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