--[[mudlet
type: trigger
name: Psidaze Lands
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
- pattern: ^You summon sparkles of psi energy around (.+), causing \w+ to forget \w+ actions as the sparkles distract
    \w+\.$
  type: 1
]]--

-- Golden Dragon PSIDAZE fire line (live capture 2026-07-28): the denizen now has
-- recurring AMNESIA. Highlight it, then confirm the cast landed: restart the 41s
-- cooldown from the LANDED moment (send stamps are pick-time; the queued cast can
-- fire seconds later) and release the in-flight pick hold so the rotation may
-- advance on the next rebuild instead of re-sending a cast that already fired.
selectString(line,1)
setBold(true)
fg("gold")
deselect()
resetFormat()

if ataxiaBasher_gdragonConfirm then
	ataxiaBasher_gdragonConfirm("psidaze")
end
