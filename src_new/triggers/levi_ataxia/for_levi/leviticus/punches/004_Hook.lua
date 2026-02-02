--[[mudlet
type: trigger
name: Hook
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Affs Post Queue - Gated
- Classes K-S
- Monk
- Tekura Limbs
- Punches
attributes:
  isActive: 'yes'
  isFolder: 'no'
  isTempTrigger: 'no'
  isMultiline: 'yes'
  isPerlSlashGOption: 'no'
  isColorizerTrigger: 'no'
  isFilterTrigger: 'no'
  isSoundTrigger: 'no'
  isColorTrigger: 'no'
  isColorTriggerFg: 'no'
  isColorTriggerBg: 'no'
triggerType: 0
conditonLineDelta: 1
mStayOpen: 0
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ^You unleash a powerful hook towards (\w+).$
  type: 1
- pattern: '1'
  type: 5
- pattern: ^As your blow lands with a crunch, you perceive that you have dealt (.+)% damage to (\w+)'s torso.$
  type: 1
]]--

local person = multimatches[1][2]
if isTargeted(person) then
  targetIshere = true
  tAffs.shield = false
  if removeAffV3 then removeAffV3("shield") end
  lastLimbAttack = "tekuraHKP"
  
    local damage = tonumber(multimatches[3][1])
  if ataxiaTables.limbData.tekuraUCP == 14 then ataxiaTables.limbData.tekuraUCP = math.floor(damage*1.05) end
  if ataxiaTables.limbData.tekuraSPP == 14 then ataxiaTables.limbData.tekuraSPP = damage end
  if ataxiaTables.limbData.tekuraHFP == 14 then ataxiaTables.limbData.tekuraHFP = damage end
end