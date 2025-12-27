--[[mudlet
type: trigger
name: Warhammer - Devestate
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- INFERNAL
- 2H Oppression
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
- pattern: You invest necromantic energies into a Hellforge Hammer, preparing to torment the heathens
  type: 3
- pattern: '1'
  type: 5
- pattern: ^Drawing back a Hellforge Hammer, you deliver a single, crippling blow to the legs of \w+. mangling bone and meat
    in a bloody spray\.$
  type: 1
]]--
