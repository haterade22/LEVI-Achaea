--[[mudlet
type: trigger
name: Acciaccatura fired
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Bard
- Bard
- Swashbuckling
- Tunesmithing
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
- pattern: ^You viciously jab .* into (\w+)\'s (left leg|right leg|left arm|right arm)\.$
  type: 1
- pattern: ^\A bell\-like tone rings out from your songblessed rapier\, echoed by the sound of cracking bone as( |  )(\w+)\'s
    (left leg|right leg|left arm|right arm) snaps\.$
  type: 1
]]--

tunesmithing = "none"