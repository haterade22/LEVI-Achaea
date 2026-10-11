--[[mudlet
type: trigger
name: Jinzuku Addiction
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
- pattern: ^The end of the staff drives viciously into the kidneys of (\w+)\.$
  type: 1
]]--
-- v4.7.413: only for OUR target (it recorded and relayed anyone's hit on anyone), and the party
-- message only goes out with party relay on.
-- It also called tarAff("Addiction"), a function that does not exist, so it threw on every jinzuku line.
if isTargeted(matches[2]) then
  selectCurrentLine() fg("a_yellow") bg("black")
  replace("" ..matches[2].. " [Jinzuku: Addiction]")
  tarAffed("addiction")
  if partyrelay then send("pt " ..matches[2].. ": addiction") end
end
