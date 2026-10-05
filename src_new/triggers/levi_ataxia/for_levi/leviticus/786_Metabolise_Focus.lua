--[[mudlet
type: trigger
name: Metabolise Focus
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Misc Triggers
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
- pattern: ^You begin to focus upon advanced metabolisation of the (\w+) affliction\.
  type: 1
]]--

-- "You begin to focus upon advanced metabolisation of the paralysis affliction." (the user's
-- log, 2026-10-05). METABOLISE is not a DEF line and GMCP never reports it, so this is the only
-- proof the send landed (deffing/001).
if ataxia_metaboliseConfirmed then ataxia_metaboliseConfirmed(matches[2]) end
