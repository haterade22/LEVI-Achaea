--[[mudlet
type: trigger
name: Sweep Proc
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
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
- pattern: ^Your draconic muscles flex like steel coils as you continue your sweep, demolishing any puny foes
  type: 1
]]--

-- Draconic Sweep proc CONFIRMED (live capture 2026-10-22, 18970 blunt on a barrow bat):
--   "You whip your huge, sinuous tail in a circle, knocking your enemies off their feet."
--   "Your draconic muscles flex like steel coils as you continue your sweep, demolishing any
--    puny foes who happen to be in the path of your rampaging tail."
-- The game wraps the second line after "happen to be in", so the pattern is the first row's
-- start only. Highlight, restart the 30s proc cooldown from the LANDED moment and release the
-- in-flight tailsweep hold (ataxiaBasher_dragonSweepProc, basher/002).
selectString(line,1)
setBold(true)
fg("orange_red")
deselect()
resetFormat()

if ataxiaBasher_dragonSweepProc then
	ataxiaBasher_dragonSweepProc()
end
