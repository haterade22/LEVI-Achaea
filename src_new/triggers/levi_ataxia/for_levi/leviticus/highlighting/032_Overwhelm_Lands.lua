--[[mudlet
type: trigger
name: Overwhelm Lands
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
- pattern: ^You charge quickly at (.+), throwing your mighty form into \w+ and sending \w+ staggering back\.$
  type: 1
]]--

-- Golden Dragon OVERWHELM fire line (live capture 2026-07-28): the damage filler
-- landed. Highlight (orange_red = damage family; gold is the control casts), then
-- confirm: restart the 16s cooldown from the LANDED moment and release the
-- in-flight pick hold so the rotation may advance on the next rebuild.
selectString(line,1)
setBold(true)
fg("orange_red")
deselect()
resetFormat()

if ataxiaBasher_gdragonConfirm then
	ataxiaBasher_gdragonConfirm("overwhelm")
end
