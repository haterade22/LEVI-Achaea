--[[mudlet
type: trigger
name: Immolation Staff
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Mage
- Staffcast
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
- pattern: ^As you point a primordial staff at \w+, a scintilla of bright, burning light shoots out, striking \w+ with focused
    elemental power\.$
  type: 1
]]--

timmolation = true
-- Burns are tracked by 011_Scintilla_Ignition.lua when the spark actually ignites
-- Do NOT add burns here — it double-counts with the ignition trigger