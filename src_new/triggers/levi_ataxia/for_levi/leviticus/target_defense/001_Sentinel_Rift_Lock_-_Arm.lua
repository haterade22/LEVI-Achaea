--[[mudlet
type: trigger
name: Sentinel Rift Lock - Arm
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Target Defense
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
- pattern: ^\w+ cocks back \w+ arm and throws .+ at your \w+ arm.
  type: 1
- pattern: ^\w+ draws .+ in an expert lateral slice across your \w+ arm.
  type: 1
]]--

if not ataxia.parrying then
 ataxia_createParry()
end
ataxia.settings.use.parry = true
if not ataxia.parry == "randomarm" then
ataxia.parry = "randomarm"
end