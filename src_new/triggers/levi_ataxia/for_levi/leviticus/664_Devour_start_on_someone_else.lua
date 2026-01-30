--[[mudlet
type: trigger
name: Devour start on someone else
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Misc Tracking
- Warnings
- Warnings
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
- pattern: 'In a single, sinuous motion, '
  type: 2
- pattern: ^In a single, sinuous motion, (\w+) manoeuvres (?:her|his) imposing form to encircle (\w+)'s feet, fixing (?:her|him)
    with a penetrating gaze as (?:her|his) tremendous jaws open wide\.$
  type: 1
]]--

ataxia_setWarning(multimatches[2][2].." devouring "..multimatches[2][3], 2)