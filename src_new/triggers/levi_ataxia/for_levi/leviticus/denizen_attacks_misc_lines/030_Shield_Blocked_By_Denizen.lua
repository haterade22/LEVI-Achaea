--[[mudlet
type: trigger
name: Shield Blocked By Denizen
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Basher
- Bashing
- Basher Lines
- Denizen Attacks / Misc Lines
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
- pattern: ^(.+) hurls itself against your shield
  type: 1
]]--

-- "A diamond-back rattlesnake hurls itself against your shield in a futile attempt to harm you."
--
-- v4.7.514 (the oryx death, 2026-11-24): our magical shield stopped this denizen's attack. The last
-- stand reads it (basher/001, ataxiaBasher_onShieldBlocked -> ataxiaBasher_lastStandHit): while the
-- shield still blocks one denizen in the room, hits of another that pass it do not end the stand.
-- The pattern stops at an early phrase so a long denizen name cannot push it past the wrap.
-- v4.7.519: every line is also learned into the saved shield record (`blocked`, basher/001,
-- ataxiaBasher_noteShieldBlock), stand or not: a denizen with 2 blocks and no hit through the shield
-- is shield-safe, and a room of them gets the shield instead of a retreat.
-- The folder is switched on while the basher runs (genrunning/003, ataxiaBasher_syncLineTriggers),
-- which is the only time a last stand exists, and the only time the record is in scope.
if ataxiaBasher_onShieldBlocked then ataxiaBasher_onShieldBlocked(matches[2]) end
