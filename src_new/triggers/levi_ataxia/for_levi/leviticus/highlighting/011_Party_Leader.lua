--[[mudlet
type: trigger
name: Party Leader
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
- pattern: '^\(Party\): (\w+) says, "Target: (\w+)."$'
  type: 1
- pattern: '^\(Party\): (\w+) says, "Target (\w+)."$'
  type: 1
- pattern: '^\(Party\): (\w+) says, "TARGET: (\w+)."$'
  type: 1
- pattern: '^\(Party\): (\w+) says, "Target changed to (\w+)."$'
  type: 1
]]--

-- v4.7.456: this trigger has the same four patterns as party_targetting/002, and both ran `t NAME`.
-- Every leader call ran the whole target switch twice (two "Target acquired" lines, six "[V3]
-- States reset", four "Your target is now", the defence priorities reset), and because this copy
-- never cleared `partyrelay`, the second run said "Target: NAME" back to the party (2026-10-27
-- group log). 002 owns the call now; this one does nothing.