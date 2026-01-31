--[[mudlet
type: trigger
name: FORMED
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
- pattern: 'As the earth rises to clad your growing form in a skin of stone, you scream '
  type: 2
- pattern: Your draconic form melts away, leaving you suddenly weaker and more vulnerable.
  type: 3
- pattern: You begin to sense for those that would tread upon the hallowed earth.
  type: 3
]]--

ataxia.settings.paused = false
ataxiaEcho("System has been "..(ataxia.settings.paused and "<red>paused." or "<green>unpaused."))
shape = 0
bellow = false
targetlimb = nil
parriedlimb = nil
calcifiedtargettorso = false
