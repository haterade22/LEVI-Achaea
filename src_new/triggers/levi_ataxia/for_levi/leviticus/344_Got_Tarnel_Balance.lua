--[[mudlet
type: trigger
name: Got Tarnel Balance
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
- pattern: You may call upon the primal power of Tarnel once again.
  type: 3
]]--

ataxiaTemp.tarnelCooldown = true
deleteLine()
cecho("\n<yellow>-ϴ<brown>-ϴ<orange>-ϴ<sienna>-ϴ-<DimGrey>Tarnel balance has returned<yellow>-ϴ<brown>-ϴ<orange>-ϴ<sienna>-ϴ-")