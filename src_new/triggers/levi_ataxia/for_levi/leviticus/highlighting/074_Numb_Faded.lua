--[[mudlet
type: trigger
name: Numbness Faded
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
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ^You cry out in agony as the effects of your numbness fade away
  type: 1
]]--

-- NUMB WORE OFF (v4.7.512, user: "Highlight and echo when NUMB wears off. Also account for it as
-- we do lose a lot of health.").
--
--   You cry out in agony as the effects of your numbness fade away and you feel your wounds once more.
--
-- The line is 99 columns and fits one row; the pattern still stops at an early phrase. It comes
-- 9.07 to 10.03 s after the up line (highlighting/060), and with it the game takes every hit of
-- those seconds in ONE blow, minus 40%: 1,400 to 11,036 of 20,061 health in our 28 cycles of
-- 2026-11-23 (kb/defences/numbness.md). The blow has no "Health lost:" line.
--
-- `orange_red`, bold: the warm opposite of the turquoise up line, and present in
-- misc_scripts/007_Custom_Colour_Table.lua (that table REPLACES Mudlet's palette).
--
-- The echo and the accounting are in basher/016_Numb_Debt.lua: `ataxia_numbFaded` prints the size
-- of the blow ("NUMB WORE OFF: -8591 HP (20041 -> 11450, 42% of max) from 8 absorbed hits.") and
-- closes the debt that the safeties were reading.
selectString(line, 1)
fg("orange_red")
setBold(true)
deselect()
resetFormat()
if ataxia_numbFaded then ataxia_numbFaded() end
