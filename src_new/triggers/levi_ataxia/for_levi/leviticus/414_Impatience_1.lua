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
	tarAffed("impatience")

	-- V3 integration: collapse branches (proves impatience present)
	if onTargetImpatienceV3 then onTargetImpatienceV3() end

	selectString(line, 1)
	fg("goldenrod")
	resetFormat()
	-- The boredom line proves IMPATIENCE only. A Depthswalker's impatience
	-- usually arrives as a delayed HYPOCHONDRIA symptom (Classleads #154:
	-- nausea -> lethargy -> impatience), but by now hypochondria and its earlier
	-- symptoms may already be cured, so they are NOT re-added (v4.7.371). The
	-- old back-fill also added addiction, which is not in the current order.
end