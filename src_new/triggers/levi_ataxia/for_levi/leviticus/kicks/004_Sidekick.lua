--[[mudlet
type: trigger
name: Sidekick
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
- pattern: ^You pump out at (\w+) with a powerful side kick.$
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
  lastLimbAttack = "tekuraSDK"
  
  local damage = tonumber(multimatches[3][1])
  if ataxiaTables.limbData.tekuraSNK == 25 then ataxiaTables.limbData.tekuraSNK = math.floor(damage*0.834) end
  if ataxiaTables.limbData.tekuraMNK == 25 then ataxiaTables.limbData.tekuraMNK = math.floor(damage*0.834) end
  if ataxiaTables.limbData.tekuraWWK == 25 then ataxiaTables.limbData.tekuraWWK = math.floor(damage*0.834) end
end