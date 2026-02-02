--[[mudlet
type: trigger
name: NO SHIELD
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- EARTH LORD
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
- pattern: ^You launch a magma-wreathed fist at (\w+), but (he|she) ducks aside at the last moment.$
  type: 1
]]--

tAffs.shield = false
if removeAffV3 then removeAffV3("shield") end
deleteFull()
cecho("<magenta>\n NO SHIELD YOU FOOL !!! GOT SHAPE THOUGH >>>>>>>>>>>>>>> <white>"..gmcp.Char.Vitals.charstats[3])