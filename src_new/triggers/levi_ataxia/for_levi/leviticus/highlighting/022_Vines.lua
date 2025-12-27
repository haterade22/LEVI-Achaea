--[[mudlet
type: trigger
name: Vines
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Highlighting
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
- pattern: Vines suddenly tear their way up through the ground, rapidly overgrowing the entire location.
  type: 3
- pattern: ^Drawing back a Hellforge Hammer, you unleash a flesh-mincing blow at (.+)\.$
  type: 1
- pattern: A figurine of the suffering Maya grows warm to the touch.
  type: 3
]]--

selectString(line, 1)
setBold(true)
fg("OrangeRed")
deselect()
resetFormat()