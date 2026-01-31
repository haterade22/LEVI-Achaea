--[[mudlet
type: trigger
name: Jack-in-the-Box two
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
- pattern: 'The music of the jack-in-the-box becomes faster and more frantic and a loud voice from within yells, '
  type: 2
- pattern: ^The music of the jack\-in\-the\-box becomes faster and more frantic and a loud voice from within yells, "(\w+),
    I'm a-cooomiiiiing!"$
  type: 1
]]--

if multimatches[2][2] ~= gmcp.Char.Name.name then return end

ataxia_setWarning(matches[2].." Jack-in-the-Box you", 2)