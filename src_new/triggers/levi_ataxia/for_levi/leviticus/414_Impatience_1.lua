--[[mudlet
type: trigger
name: Impatience
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Third Person
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
- pattern: ^(\w+) shuffles \w+ feet in boredom.$
  type: 1
- pattern: ^A puzzled expression crosses the face of (\w+).$
  type: 1
- pattern: ^\w+ eyes gleaming, \w+ smiles and quickly sings a jaunty limerick at (\w+).$
  type: 1
]]--

if isTargeted(matches[2]) then
	tAffs.impatience = true
	if applyAffV3 then applyAffV3("impatience") end

	-- V3 integration: collapse branches (proves impatience present)
	if onTargetImpatienceV3 then onTargetImpatienceV3() end

	selectString(line, 1)
	fg("goldenrod")
	resetFormat()
	if ataxia_isClass("depthswalker") then
		if matches[1]:find("in boredom") then
			tAffs.hypochondria = true
			tAffs.nausea = true
			tAffs.addiction = true
			tAffs.lethargy = true
			if applyAffV3 then applyAffV3("hypochondria"); applyAffV3("nausea"); applyAffV3("addiction"); applyAffV3("lethargy") end
		end
	end
end