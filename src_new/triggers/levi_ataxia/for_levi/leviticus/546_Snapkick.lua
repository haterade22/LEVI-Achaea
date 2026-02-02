--[[mudlet
type: trigger
name: Snapkick
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
- Kicks
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
- pattern: ^You let fly at (\w+) with a snap kick.$
  type: 1
- pattern: '1'
  type: 5
- pattern: ^As your blow lands with a crunch, you perceive that you have dealt (.+)% damage to (\w+)'s (left leg|right leg).$
  type: 1
]]--

local person = multimatches[1][2]
if isTargeted(person) then
  targetIshere = true
  tAffs.shield = false
  if removeAffV3 then removeAffV3("shield") end
  lastLimbAttack = "tekuraSNK"
  
  local damage = tonumber(multimatches[3][1])
  if ataxiaTables.limbData.tekuraSDK == 25 then ataxiaTables.limbData.tekuraSNK = math.floor(damage*1.2) end
  if ataxiaTables.limbData.tekuraMNK == 25 then ataxiaTables.limbData.tekuraMNK = damage end
  if ataxiaTables.limbData.tekuraWWK == 25 then ataxiaTables.limbData.tekuraWWK = damage end  
end