--[[mudlet
type: trigger
name: Wield Whip
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Highlighting
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
- pattern: ^You must be wielding a whip in order to garrote someone\.$
  type: 1
- pattern: ^You must be wielding a whip in order to flay someone\.$
  type: 1
]]--

-- The game's refusal is the authority: whatever round sent the garrote or the flay, the whip goes
-- into the hand. The flay line was added in v4.7.503 (the basher's shield flay with a dirk in hand).

send("wield left whip;wield right shield")