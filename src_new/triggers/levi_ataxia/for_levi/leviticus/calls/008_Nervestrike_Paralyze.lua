--[[mudlet
type: trigger
name: Nervestrike Paralyze
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
- pattern: ^You whip a twisted oaken staff at the side of (\w+)'s neck\.$
  type: 1
]]--

selectCurrentLine() fg("a_yellow") bg("black") 
replace("" ..matches[2].. " [Nervestrike: Paralysis]")
 
send("pt " ..matches[2].. ": paralysis")
tarAffed("paralysis")
if applyAffV3 then applyAffV3("paralysis") end