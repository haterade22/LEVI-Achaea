--[[mudlet
type: trigger
name: Green Inhitbit
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Illusions
attributes:
  isActive: 'yes'
  isFolder: 'no'
  isTempTrigger: 'no'
  isMultiline: 'no'
  isPerlSlashGOption: 'no'
  isColorizerTrigger: 'yes'
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
mFgColor: '#00ff00'
mBgColor: '#ffffff'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ^You spit a thick gob of slime at (.+), coating (\w+) and inhibiting (\w+) ability to heal\.$
  type: 1
- pattern: ^You spit a thick gob of slime at the (.+), coating (\w+) and inhibiting (\w+) ability to heal.\$
  type: 0
]]--

send("pt Inhibt delivered to the fat slut " ..matches[2]..  " It will not heal!")


