--[[mudlet
type: trigger
name: Devour
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
  isMultiline: 'yes'
  isPerlSlashGOption: 'no'
  isColorizerTrigger: 'no'
  isFilterTrigger: 'no'
  isSoundTrigger: 'no'
  isColorTrigger: 'no'
  isColorTriggerFg: 'no'
  isColorTriggerBg: 'no'
triggerType: 0
conditonLineDelta: 1
mStayOpen: 0
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: A deathly calm
  type: 2
- pattern: A deathly calm descends upon your surroundings as \w+ draws (\w+) up regally, eyes gleaming with murderous intent\.$
  type: 1
]]--

cecho("<blue>\n\nDevour! DEVOUR!\nDevour! DEVOUR\nDevour! DEVOUR!\n")
ataxia_setWarning("devour incoming",  2.5)	