--[[mudlet
type: trigger
name: Runewarden Falcon Rake Cooldown
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Basher
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
- pattern: ^You whistle to your falcon, commanding it to assail
  type: 1
- pattern: ^You cannot yet order your falcon to rake another foe\.$
  type: 1
]]--

ataxiaBasher_falconRakeCooldown()
