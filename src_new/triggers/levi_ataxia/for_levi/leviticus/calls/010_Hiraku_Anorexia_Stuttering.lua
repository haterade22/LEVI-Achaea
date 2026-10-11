--[[mudlet
type: trigger
name: Hiraku Anorexia Stuttering
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
- pattern: ^The staff smashes into the face of (\w+) with a sickening crunch\.$
  type: 1
]]--
-- v4.7.413: only for OUR target (it recorded and relayed anyone's hit on anyone), and the party
-- message only goes out with party relay on.
-- (A prone target is also stunned briefly; no target stun is tracked yet, so it is only relayed.)
if isTargeted(matches[2]) then
  selectCurrentLine() fg("a_yellow") bg("black")
  replace("" ..matches[2].. " [Hiraku: Anorexia | Stuttering]")
  tarAffed("anorexia")
  tarAffed("stuttering")
  if partyrelay then
    send("pt " ..matches[2].. ": anorexia stuttering" .. (haveAff("prone") and " (stunned)" or ""))
  end
end
