--[[mudlet
type: trigger
name: SoulShield - Infernal - GAG
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Basher
- Bashing
- Basher Lines
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
- pattern: A torrent of black flame rushes out and back at you in a small loop, burning you.
  type: 3
- pattern: The miasma of black flames around you dissipates.
  type: 3
- pattern: Your soulshield absorbs the damage but the black flames intensify.
  type: 3
- pattern: ^Horror overcomes (.+)'s face as \w+ body freezes solidly and collapses into a hundred brittle pieces\.$
  type: 1
]]--

deleteFull()