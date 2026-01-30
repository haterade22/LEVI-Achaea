--[[mudlet
type: trigger
name: Rain Form
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- MONK 1
- Monk
- Shikudo Triggers
- Shikudo
- Stances
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
- pattern: ^Dropping into a lower stance, you snap your weapon into an offensive position, tensing your muscles in preparation
    for the form of Willows in Rain Storm\.$
  type: 1
- pattern: ^You are already carrying out the form of Willows in Rain Storm\.$
  type: 1
]]--

selectCurrentLine() fg("gold") bg("black") 
replace("[Levi]: RAIN FORM")
shikudostance = "rain"
katachain = 0
stance = "rain"