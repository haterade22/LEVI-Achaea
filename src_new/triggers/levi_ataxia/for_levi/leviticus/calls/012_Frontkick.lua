--[[mudlet
type: trigger
name: Frontkick
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
- pattern: ^The instep of your foot smashes into the (?:\w+ )?underarm of (\w+), throwing
  type: 1
]]--
-- v4.7.414: the pattern expected "into the underarm of X"; the real line names the side, "into the
-- left underarm of X" (log 2026-10-11), so this never fired. It is ~131 columns and wraps, so
-- it is a start fragment now.
-- v4.7.413: only for OUR target (it recorded and relayed anyone's hit on anyone), and the party
-- message only goes out with party relay on.
if isTargeted(matches[2]) then
  selectCurrentLine() fg("a_yellow") bg("black")
  replace("" ..matches[2].. " [Frontkick: Prone]")
  tarAffed("prone")
  if partyrelay then send("pt " ..matches[2].. ": prone") end
end
