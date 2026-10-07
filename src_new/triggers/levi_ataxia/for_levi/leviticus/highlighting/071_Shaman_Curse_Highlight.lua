--[[mudlet
type: trigger
name: Shaman Curse Highlight
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
- pattern: You point an imperious finger at
  type: 2
- pattern: Summoning your malign power, you direct a twin assault of the curses
  type: 2
]]--

-- OUR SHAMAN CURSES (v4.7.388, user: "Please highlight these attacks"), the swiftcurse and the jinx
-- the Shaman basher throws (Thrice Cursed alternates them, v4.7.386):
--
--   You point an imperious finger at an avid junior detective and blood begins to flow from his pores.
--   Summoning your malign power, you direct a twin assault of the curses bleed and bleed at an avid
--   junior detective.
--
-- `chartreuse` bold: our attack landed, as for the Serpent bite (068) and the Jester swings (069/070).
--
-- A LONG NAME WRAPS THEM (the server wraps at 119-124; the jinx line is ~113 characters with this
-- name). The openings are matched at the start of the row. The jinx ENDS with the denizen's name, so
-- its wrapped tail has no fixed words to anchor a pattern on -- instead, a first row that does not
-- finish the sentence colours the next row too (tempLineTrigger). The same rule covers the curse.
-- Highlight only; 339_Shaman_Attacks keeps the counting.
local function paint()
  selectString(line, 1)
  fg("chartreuse")
  setBold(true)
  deselect()
  resetFormat()
end

paint()
if not line:match("%.%s*$") then
  tempLineTrigger(1, 1, paint)
end
