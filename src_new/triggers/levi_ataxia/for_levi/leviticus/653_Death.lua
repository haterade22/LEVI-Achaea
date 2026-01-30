--[[mudlet
type: trigger
name: Death
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Misc Tracking
- Warnings
- Warnings
- Instakills
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
- pattern: flings a tarot card at you and upon impact, it disappears. An ominous silence overtakes your surroundings.
  type: 0
]]--

cecho("<blue>\n\nDEATH DEATH! DEATH DEATH!\nDEATH DEATH! BEHEAD / CLEAVE!\nDEATH DEATH! DEATH DEATH!\n\n")
ataxia_setWarning("death tarot",  2.5)	