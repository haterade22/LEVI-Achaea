--[[mudlet
type: trigger
name: Hiru Dizziness Blackout
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
- pattern: ^The staff connects to the side of (\w+)'s head with a resounding crack\.$
  type: 1
]]--
-- v4.7.413: only for OUR target (it recorded and relayed anyone's hit on anyone), and the party
-- message only goes out with party relay on.
-- Hiru gives dizziness, plus CONFUSION if the target is prone (wiki). It used to say "blackout" and
-- record nothing for the prone case.
if isTargeted(matches[2]) then
  selectCurrentLine() fg("a_yellow") bg("black")
  local prone = haveAff("prone")
  replace("" ..matches[2].. (prone and " [Hiru: Dizziness | Confusion]" or " [Hiru: Dizziness]"))
  tarAffed("dizziness")
  if prone then tarAffed("confusion") end
  if partyrelay then send("pt " ..matches[2].. (prone and ": dizziness confusion" or ": dizziness")) end
end
