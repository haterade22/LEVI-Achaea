--[[mudlet
type: trigger
name: Vivace
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes A-J
- Bard
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
- pattern: Your feet move in vivace perfected, speeding each step within a new blade's song.
  type: 3
]]--

-- WORDING INFERRED, NOT CAPTURED (v4.7.311). The three known tempo lines are identical but for
-- the tempo word ("Your feet move in moderato perfected, speeding each step within a new blade's
-- song."), so Vivace is assumed to follow. If the real line differs, `bardtempostance` stays at
-- its previous value and the footwork flourish (which reads it) simply does not fire -- the
-- failure direction that costs nothing. Paste the line when TEMPO VIVACE is first sent.
bardtempostance = "Vivace"

--1,6,5
