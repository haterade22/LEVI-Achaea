--[[mudlet
type: trigger
name: Undead Squeeze
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Curing Stuff
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
- pattern: ^(\w+) wraps (\w+) unliving arms about you in a false embrace, then begins to squeeze with theinexorable certainty
    of one who has all the time in the world to see you succumb to the march of the undying\.$
  type: 1
]]--

if ataxia.afflictions.mildtrauma == true then
ataxia.afflictions.serioustrauma = true
else 
ataxia.afflictions.mildtrauma = true
end