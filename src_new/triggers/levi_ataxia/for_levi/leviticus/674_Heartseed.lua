--[[mudlet
type: trigger
name: Heartseed
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
- pattern: Lunging forward with one palm outstretched,
  type: 2
- pattern: ^Lunging forward with one palm outstretched, (\w+) aims a blow at your heart\. A warm pulse accompanies (?:her|his)
    attack, leaving a dull ache in your chest\.$
  type: 1
]]--

ataxia_setWarning(multimatches[2][2].." heartseed you", 2)