--[[mudlet
type: trigger
name: Shikudo No Staff
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
- pattern: ^You may not carry out a combination utilising Shikudo strikes without the required staff\.$
  type: 1
]]--

-- The combo was refused: the item in hand is not a Shikudo staff. In the 2026-10-27 group log the
-- bare `wield staff` had picked the user's illusion staff (a Shar'ilian lightspire) on about half
-- the rounds. 006 drops the inventory id it sent and the [SK] line says FAILED (v4.7.456).
selectCurrentLine() fg("red") resetFormat()
if shikudo and shikudo.staffRefused then shikudo.staffRefused() end
