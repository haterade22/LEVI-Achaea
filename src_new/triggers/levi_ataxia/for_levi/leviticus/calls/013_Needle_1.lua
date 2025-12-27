--[[mudlet
type: trigger
name: Needle
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
- Calls
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
- pattern: ^With pinpoint precision\, you drive .+ at the throat of ([\w'\-]+)\.$
  type: 1
- pattern: ^Reversing your grip on .+\, you drive the top of the weapon into the throat of ([\w'\-]+).$
  type: 1
- pattern: ^The end of the staff smashes into the exposed throat of (\w+), crushing cartilage\.$
  type: 1
]]--

if matches[2]==target then
selectCurrentLine() fg("a_yellow") bg("black") 
replace("" ..matches[2].. " [NEEDLE: Crushed Throat]")
end


send("pt " ..matches[2].. ": Crushed Throat")
   
tarAffed("crushedthroat")
tneedle = 100
