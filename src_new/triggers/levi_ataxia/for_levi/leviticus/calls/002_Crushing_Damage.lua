--[[mudlet
type: trigger
name: Crushing Damage
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
- pattern: ^Whirling around, you bring the ball of your foot crashing into the temple of (\w+).
  type: 1
]]--

if matches[2]== target then
selectCurrentLine() fg("a_yellow") bg("black") 
replace("" ..matches[2].. " [SPINKICK]")
end
if partyrelay and not ataxia.afflictions.aeon then
send("pt " ..matches[2].. ": Spinkicked! A lot of Damage")
end