--[[mudlet
type: trigger
name: Rupture Highlight
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
- pattern: ^Your vision sharpens, allowing you to perceive the locations of every vein
  type: 1
- pattern: '^.{0,60}beneath the skin\.$'
  type: 1
- pattern: ^Your blows will already rupture veins and arteries\.$
  type: 1
- pattern: ^Distractions reassert themselves, your mental clarity returning to mundane levels\.$
  type: 1
]]--

-- ENACT RUPTURE, all three lines (v4.7.364, user: "Please highlight the enact rupture lines with a
-- bold bright color"):
--
--   Your vision sharpens, allowing you to perceive the locations of every vein and artery that
--   lies beneath the skin.                                   <- up (can wrap: a tail pattern too)
--   Your blows will already rupture veins and arteries.     <- already up
--   Distractions reassert themselves, your mental clarity returning to mundane levels.   <- down
--
-- Highlight only. The state lives in psion/007 and psion/008 (basher/002's rupture belief).
--
-- `deep_pink` bold: bright, and not already a meaning -- chartreuse is "an attack landed", red is
-- damage, goldenrod / medium_orchid / cadet_blue are the necromancy riders, orange is in reserve.
selectString(line, 1)
fg("deep_pink")
setBold(true)
deselect()
resetFormat()
