--[[mudlet
type: trigger
name: attuned
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Spiritlore System
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
- pattern: Focusing on your binding with the spirit of ([\w']+), .+, you carefully strengthen the connection, allowing more
    of the spirit's power to use your body as a conduit.
  type: 1
]]--

local bond = matches[2]
if bond == "Ri'Shen" then bond = "Ri'shen" end
shaman.attunedspirit(bond)