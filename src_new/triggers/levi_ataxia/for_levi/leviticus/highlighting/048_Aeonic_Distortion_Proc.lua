--[[mudlet
type: trigger
name: Aeonic Distortion Proc
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
- pattern: ^Your surroundings crack like broken glass as your aeonic distortion shakes reality, violently wracking everything within$
  type: 1
]]--

-- TIMEQUAKE paying off (captured live 2026-08-12): the boon turns CHRONO DISTORTION into a room
-- nuke, and this is the line that precedes the per-denizen damage -- 2,495 magical x3 in the
-- capture, against a room of three.
--
-- Anchored on the FIRST line only. The sentence wraps ("...within / the fracture's reach.") and
-- the wrap point depends on the client's column count, so matching the whole thing would work on
-- one screen width and silently fail on another. Highlighting the first line is enough to make
-- the proc visible, which is all this does.
--
-- chartreuse bold: the attack-landing family, matching arc and the Thunderclap bisect.
selectString(line, 1)
setBold(true)
fg("chartreuse")
deselect()
resetFormat()
