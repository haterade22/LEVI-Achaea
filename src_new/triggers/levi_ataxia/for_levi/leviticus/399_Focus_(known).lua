--[[mudlet
type: trigger
name: Focus (known)
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Remove Afflictions
attributes:
  isActive: 'yes'
  isFolder: 'no'
  isTempTrigger: 'no'
  isMultiline: 'yes'
  isPerlSlashGOption: 'no'
  isColorizerTrigger: 'no'
  isFilterTrigger: 'no'
  isSoundTrigger: 'no'
  isColorTrigger: 'no'
  isColorTriggerFg: 'no'
  isColorTriggerBg: 'no'
triggerType: 0
conditonLineDelta: 1
mStayOpen: 0
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ^A look of extreme focus crosses the face of (\w+)\.$
  type: 1
- pattern: '1'
  type: 5
- pattern: (.*)
  type: 1
]]--


-- 398 owns the focus: on the focus line it charges V3's random focus cure, counts the cure for the
-- Serpent offense and starts the focus clock. This trigger only reads the line AFTER it. Until the
-- 2026-11-08 deep review (F43) it repeated all of 398's work behind `tBals.focus`, which 398 had
-- set false a line earlier, so it never ran: 68 focus lines in the six Serpent logs (e.g.
-- kb/raw/logs/ours/2026-11-07_164635_Saibel.log:372) and serpent.trackCure("focus") counted none.
--
-- When the next line says the focus took LOVERS, 398's random removal is undone
-- (ataxia_knownCureV3, ataxia/001_Miscellaneous_Aff_Tracking_Methods), so the focus counts once.
-- other_things_fading/002_Seduce erases lovers itself on that line, so it is not erased here as
-- well; the two can run in either order.
local name = multimatches[1][2]
local nextLine = multimatches[3] and multimatches[3][1]
if isTargeted(name) and (nextLine == name .. " shakes his head and a look of clarity returns to his eyes."
	or nextLine == name .. " shakes her head and a look of clarity returns to her eyes.") then
	if ataxia_knownCureV3 then ataxia_knownCureV3("focus", name, "lovers") end
end