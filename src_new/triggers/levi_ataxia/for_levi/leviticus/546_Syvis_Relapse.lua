--[[mudlet
type: trigger
name: Syvis Relapse
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes K-S
- Shaman
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
- pattern: ^You sense the insidious power of Syvis strike down (\w+) with (\w+).$
  type: 1
]]--

if isTargeted(matches[2]) then
	ataxiaTemp.relapseAff = curseConvert(matches[3])
	
	tarAffed(ataxiaTemp.relapseAff)
	if applyAffV3 then applyAffV3(ataxiaTemp.relapseAff) end
   if partyrelay then send("pt "..target..": "..ataxiaTemp.relapseAff) end
	ataxiaTemp.relapseAff = nil
end