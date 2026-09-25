--[[mudlet
type: trigger
name: Rubble Clamber
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Mnemosyne
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
- pattern: You begin to slowly clamber over
  type: 2
]]--

-- "You begin to slowly clamber over the rubble that blocks your way."
-- "You begin to slowly clamber over a pile of rubble that blocks your way."
-- (both already in the mapper's "Rubble at the exit" trigger, which only slows its speedwalk)
--
-- The move is HAPPENING, slowly -- give it time instead of letting the explorer's 5s move timeout
-- re-send it (v4.7.357; the Psion's Earthquake boon piles rubble on our own exits). Start of line,
-- so both wordings match; M.onClamber does nothing unless a move of ours is in flight.
if ataxia.mnemosyne and ataxia.mnemosyne.onClamber then ataxia.mnemosyne.onClamber() end
