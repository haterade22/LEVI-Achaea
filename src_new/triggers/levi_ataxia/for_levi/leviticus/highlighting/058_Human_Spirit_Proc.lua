--[[mudlet
type: trigger
name: Human Spirit Proc
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
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
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
packageName: ''
patterns:
- pattern: ^Your deadly prowess nourishes your body\.$
  type: 1
]]--
-- THE HUMAN SPIRIT (Mnemosyne boon, uncommon) -- the heal proc, captured 2026-08-20.
--
--   "Critical strikes restore 2% of your health."
--
-- Note it is a CRIT proc, not a passive: this line and Baron's Bro (057) both only ever appear
-- on a critical strike, which is why both are erratic and easy to lose in a log.
--
-- One short line, no wrap risk, so it is anchored like the other short self-lines in this
-- folder (the fury and shin-augment captures). Anchoring also keeps it off any third-party
-- phrasing, since only OUR proc says "your body".
--
-- `medium_sea_green` is the house colour for "a beneficial effect landed" -- shared with the
-- necrotic/scorch inhibit lines, the sonata cleanse and dagaz. Deliberately shared: same
-- meaning class, and one colour the eye already reads that way beats a new one.
selectString(line, 1)
fg("medium_sea_green")
deselect()
resetFormat()
