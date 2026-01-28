--[[mudlet
type: trigger
name: Restore
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Remove Afflictions
- Groups
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
- pattern: ^(\w+) crackles with blue energy that wreathes itself about (his|her) limbs.$
  type: 1
]]--

if isTargeted(matches[2]) then
tdeliverance = false
erAff("brokenleftleg")
erAff("brokenrightleg")
erAff("brokenleftarm")
erAff("brokenrightarm")
-- Reset limb counter for all limbs
if lb and lb[target] and lb[target].hits then
    lb[target].hits["left arm"] = 0
    lb[target].hits["right arm"] = 0
    lb[target].hits["left leg"] = 0
    lb[target].hits["right leg"] = 0
end
-- Notify DWC vivisect systems of RESTORE
if infernalDWC then
    infernalDWC.enterRiftlock()
end
if infernalDWC2L then
    infernalDWC2L.enterRiftlock()
end
end
ataxia_boxEcho(" -------------------  USED RESTORE  -------------------", "blue")