--[[mudlet
type: trigger
name: Rampage Proc
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
- pattern: ^Iron-sharp claws rip and tear into all around you as your draconic bulk tramples
  type: 1
]]--

-- Draconic Rampage proc CONFIRMED (live capture 2026-07-28): the room-wide cutting
-- nuke landed. Highlight, then restart the 40s proc cooldown from the confirmed
-- moment (the queued trample can land seconds after the pick) and release the
-- in-flight trample hold so the next round returns to the normal swing.
-- FIRST ROW ONLY (v4.7.436): the game wraps the line before "frenzy." (live paste 2026-10-22),
-- and the old pattern ended in "frenzy\.$", so it never fired and the 40s clock ran on the
-- send stamp alone.
selectString(line,1)
setBold(true)
fg("orange_red")
deselect()
resetFormat()

if ataxiaBasher_dragonRampageProc then
	ataxiaBasher_dragonRampageProc()
end
