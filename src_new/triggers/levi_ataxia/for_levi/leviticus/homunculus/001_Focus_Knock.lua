--[[mudlet
type: trigger
name: Focus Knock
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes A-J
- Alchemist
- Homunculus
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
- pattern: ^Focusing your mind on a diminutive homunculus resembling \w+, you command it to disrupt (\w+)\'s focus. The homunculus
    turns towards \w+ before letting out an ear\-piercing shriek.$
  type: 1
]]--

ataxiaTemp.hombal = true

tBals.focus = false
if haveAff("shadowmadness") then
  tempTimer(5, [[tBals.focus = true]])
else
  tempTimer(2.3, [[tBals.focus = true]])
end
targetIshere = true

selectString(line, 1)
fg("goldenrod")
deselect()
resetFormat()