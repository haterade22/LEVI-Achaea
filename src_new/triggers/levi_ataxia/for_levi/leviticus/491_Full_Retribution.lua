--[[mudlet
type: trigger
name: Full Retribution
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes A-J
- Depthwalker
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
- pattern: ^The white flame leaps from the scythe to (\w+), blazing with a terrible intensity before guttering out\.$
  type: 1
]]--

-- Guarded (v4.7.372, deep review): no target check, and envenomList[1] is
-- nil on a timeloop or cull round -- the concatenation threw.
if isTargeted(matches[2]) then
	tarAffed("justice")
	tarAffed("retribution")
	local venomName = (envenomList and envenomList[1]) or "unknown"
	if partyrelay and tloop == false and tloop2 == false then send("pt "..target..": " ..venomName.. " retribution justice") end
	if partyrelay and (tloop == true or tloop2 == true) then send("pt "..target..": timeloop retribution justice") end
end

		