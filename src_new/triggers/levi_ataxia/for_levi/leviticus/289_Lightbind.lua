--[[mudlet
type: trigger
name: Lightbind
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Psion
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
- pattern: ^You fashion chains of golden light and cast them out to ensnare (\w+).$
  type: 1
- pattern: ^The remnants of golden light surrounding \w+ makes forming new chains impossible.$
  type: 1
- pattern: ^Chains of golden light already ensnare (\w+).$
  type: 1
]]--

lightbind = true
tempTimer(20, [[lightbind = false]])
deleteLine()
cecho("\n<red>[<white>Levi<red>]: LIGHTBIND")