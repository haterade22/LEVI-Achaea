--[[mudlet
type: trigger
name: Transcendence Dropped
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Class Stuff
- Psion
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
- pattern: Your body and mind fall out of their transcendent state.
  type: 3
- pattern: Your body and mind are no longer in harmony.
  type: 3
]]--

-- THE BOTTOM OF THE DECAY LADDER (v4.7.349, user's paste). "Your body and mind are no longer in
-- harmony." is what the game prints after the last 10-percent step, and nothing was listening --
-- so the local count stopped at whatever the final decay line said instead of reaching zero.
-- Harmless next to the wrap bug fixed in 001 (the value was low either way), but a counter that
-- never reaches the state it is counting towards is a counter we cannot reason about.
ataxiaTemp.transcendence = 0
if ataxiaBasher.enabled and not ataxiaBasher.manual then
	deleteFull()
end