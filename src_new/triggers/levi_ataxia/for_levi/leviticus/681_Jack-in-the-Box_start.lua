--[[mudlet
type: trigger
name: Jack-in-the-Box start
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
  isMultiline: 'no'
  isPerlSlashGOption: 'no'
  isColorizerTrigger: 'no'
  isFilterTrigger: 'no'
  isSoundTrigger: 'no'
  isColorTrigger: 'no'
  isColorTriggerFg: 'no'
  isColorTriggerBg: 'no'
triggerType: 0
conditonLineDelta: 99
mStayOpen: 0
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ^(\w+) sets a jack\-in\-the\-box on the ground and quickly winds it while whispering, '(\w+)\.' The cheerful music
    of a lute begins to emanate from it\.$
  type: 1
]]--

--if my name
if matches[3] ~= gmcp.Char.Name.name then return end

ataxia_setWarning(matches[2].." Jack-in-the-Box you", 2)