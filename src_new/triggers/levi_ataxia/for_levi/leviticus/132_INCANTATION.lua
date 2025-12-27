--[[mudlet
type: trigger
name: INCANTATION
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- DRAGON
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
- pattern: ^Drawing from the well of your puissance, you invoke a dramatic chant in the dragon tongue. Your voice resonates
    with each word, culminating in a wave of magical energy that you bend to your will and thrust towards (.*), bombarding
    (him|her) with the ancient power.$
  type: 1
]]--

deleteFull()
--cecho("\n<magenta>[[  TORE THAT GUY APART MAGICALLY  ::: <red>" .. matches[2] .. " ]]")
