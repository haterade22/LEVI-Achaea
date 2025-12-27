--[[mudlet
type: trigger
name: Bard Performance - Bashing
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Basher
- Bashing
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
- pattern: ^You can hardly manipulate a grand performance when you are not in fact performing
  type: 1
- pattern: ^The sweeping, upbeat music of a gusheh flows unending from your instrument like wine from an amphora\.$
  type: 1
- pattern: ^Your grand performance shall last another (\d+) minutes
  type: 1
]]--

bardperformance = true
enableTimer("Bard Performance")

