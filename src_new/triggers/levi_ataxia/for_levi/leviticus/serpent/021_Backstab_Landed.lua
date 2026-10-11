--[[mudlet
type: trigger
name: Backstab Landed
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes K-S
- Serpent
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
- pattern: You leap from the shadows and plunge your dagger into
  type: 2
- pattern: '^.{0,60}unsuspecting back!$'
  type: 1
]]--

-- OUR BACKSTAB LANDED (v4.7.411, user-supplied):
--
--   You leap from the shadows and plunge your dagger into a fairy Lady of Sidhe's unsuspecting back!
--
-- Start of line for the first row; the anchored tail catches the end of the line when a long
-- denizen name makes the server wrap it, so the whole attack is coloured.
--
-- Leaping from the shadows reveals us, so the hidden window from serpent/020 is dropped
-- (ataxiaBasher_serpentBackstabbed, basher/002) and the next round swings normally until we are
-- hidden again.
--
-- `chartreuse` bold: this package's attack-LANDED colour (see highlighting/068, the camus bite).
if ataxiaBasher_serpentBackstabbed then ataxiaBasher_serpentBackstabbed() end
selectString(line, 1)
fg("chartreuse")
setBold(true)
deselect()
resetFormat()
