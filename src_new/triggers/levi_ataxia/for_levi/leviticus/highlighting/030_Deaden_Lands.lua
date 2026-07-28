--[[mudlet
type: trigger
name: Deaden Lands
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
- pattern: ^You psychically slam your mind into (.+)'s, deadening \w+ reactions\.$
  type: 1
]]--

-- Golden Dragon DEADEN fire line (live capture 2026-07-28): the denizen now has
-- AEON -- every action slowed. (This also settled the 332 question: the "rummage
-- ...deadening it" line there is Psion's, not ours.) Highlight, then confirm the
-- cast landed: restart the 35s cooldown from the LANDED moment and release the
-- in-flight pick hold so the rotation may advance on the next rebuild.
selectString(line,1)
setBold(true)
fg("gold")
deselect()
resetFormat()

if ataxiaBasher_gdragonConfirm then
	ataxiaBasher_gdragonConfirm("deaden")
end

-- Denizen-state capture + (BR) echo, the battlerage-alert idiom (008_Denizen_State).
if type(target) == "number" and ataxiaBasher and ataxiaBasher.enabled and ataxiaBasher_dsSetAff then
	ataxiaBasher_dsSetAff(target, "aeon")
	if ataxiaBasher_dsAlert then
		ataxiaBasher_dsAlert("AEON on " .. tostring(target) .. " -- Deaden landed, mob acts slower", "yellow")
	end
end
