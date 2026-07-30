--[[mudlet
type: trigger
name: Mnemosyne Homebound
hierarchy:
- Levi_Ataxia
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
- pattern: ^Homebound\s+\d+\s+\w+
  type: 1
]]--

-- BOONS row: "Returning to your raido cures you of all afflictions and restores you to
-- full health. Not effective in the same location."
--
-- The raido must be laid somewhere we will NOT be standing, and the ripple's HOLDING ROOM
-- is exactly that -- we descend out of it and fight the whole 4x4 below. So the explorer
-- sketches raido on the ground immediately before the one `down` that leaves the holding
-- room, once per ripple (M._exploreMove, mnemosyne/008). Cleared on run start/end.
mnemHomebound = true
