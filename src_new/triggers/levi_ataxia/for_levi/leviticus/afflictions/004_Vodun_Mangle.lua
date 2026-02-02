--[[mudlet
type: trigger
name: Vodun Mangle
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Class Stuff
- Vodun
- Afflictions
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
- pattern: ^You pour your wrath out onto the (.+) of the Vodun doll, mangling it quite horribly.$
  type: 1
]]--

ataxiaTemp.dollFashions = ataxiaTemp.dollFashions - 7
local limb = matches[2]:gsub(" ", "")
tarAffed("damaged"..limb)
if applyAffV3 then applyAffV3("damaged") end
cecho(" <yellow>(<a_red>"..ataxiaTemp.dollFashions.."<yellow>)")