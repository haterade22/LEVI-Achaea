--[[mudlet
type: trigger
name: Blackout
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Affs Post Queue - Gated
- Classes K-S
- Knight
- SnB
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
- pattern: ^You pivot rapidly and bring your shield around to batter the head of (\w+).$
  type: 1
]]--

if isTargeted(matches[2]) and not ataxiaTemp.ignoreShield then
	if haveAff("prone") then
		moveCursor(0, getLineNumber())
		tarAffed("blackout")
		if applyAffV3 then applyAffV3("blackout") end
		moveCursorEnd()
		tempTimer(3.5, [[erAff("blackout"); if removeAffV3 then removeAffV3("blackout") end]])
      if partyrelay and not ataxia.afflictions.aeon then send("pt "..target..": blackout")
      end
	end
end

tinvest = false