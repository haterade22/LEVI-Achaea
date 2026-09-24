--[[mudlet
type: trigger
name: Mountjump Landed
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
- pattern: ^You pull back the reins on your mount and jump off to the (\w+)\.$
  type: 1
]]--

-- THE MOUNTJUMP LANDED (v4.7.345, user, live: "You pull back the reins on your mount and jump off
-- to the east."). Proof of both facts at once: we are mounted, and the move we were recovering is
-- spent. Arrival itself is the room read's business -- this line only settles the belief that
-- decides the verb.
if ataxiaBasher_mountjumpLanded then ataxiaBasher_mountjumpLanded(matches[2]) end
