--[[mudlet
type: trigger
name: BATTLECRY STUN
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
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
- pattern: ^(\w+) falls to (?:his|her) knees and clutches (?:his|her) ears as the shaft of sound strikes (?:him|her)\.$
  type: 1
]]--

selectCurrentLine() fg("a_yellow") bg("black")
replace(matches[2] .. " [STUNNED+PRONE]")
tarAffed("prone", "stun")
send("pt " .. matches[2] .. ": Stunned Proned")
