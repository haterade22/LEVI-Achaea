--[[mudlet
type: trigger
name: Smash High
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Runie
- RuneWarden
- SNB
attributes:
  isActive: 'no'
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
- pattern: ^You swing your shield around, smashing the temple of (\w+) with a backhanded blow\.$
  type: 1
]]--

if isTargeted(matches[2]) and not ataxiaTemp.ignoreShield then
	local smashAffs = {"dizziness", "recklessness", "stupidity", "confusion", "epilepsy"}
	for i=1, #smashAffs do
		if not haveAff(smashAffs[i]) then
			moveCursor(0, getLineNumber())
			tarAffed(smashAffs[i])
			moveCursorEnd()
			break
		end
       if partyrelay then send("pt "..target..": "..smashAffs[i])
      end
	end
end
ataxiaTemp.ignoreShield = nil