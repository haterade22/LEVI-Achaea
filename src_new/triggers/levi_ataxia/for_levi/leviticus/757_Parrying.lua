--[[mudlet
type: trigger
name: Parrying
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Self Limb Tracking
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
- pattern: ^You will now attempt to parry attacks to your (.+).$
  type: 1
- pattern: ^You will now attempt to intercept and counter attacks coming at your (.+).$
  type: 1
]]--

ataxia.parrying.limb = matches[2]:lower()