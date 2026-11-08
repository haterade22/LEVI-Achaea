--[[mudlet
type: trigger
name: Remove Madness
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Remove Afflictions
- Groups
- Third-Person Removes
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
- pattern: ^Lucidity returns to the eyes of (\w+).$
  type: 1
]]--

if isTargeted(matches[2]) then
  if ataxiaTemp.randomCure and ataxiaTemp.randomCure > 0 then ataxiaTemp.randomCure = ataxiaTemp.randomCure - 1 end
	-- This line comes straight after the target's goldenseal/plumbum eat (X8pRorzR.txt:536-537,
	-- 1643-1644, 5877-5878). herbs/002 charged that eat as a random cure; this line says it took
	-- shadowmadness, so the random cure is undone first and the eat counts once (deep review F14).
	-- With no such eat just before (a tree, a stale line), it only erases, as before.
	if ataxia_knownCureV3 then ataxia_knownCureV3("goldenseal", matches[2], "shadowmadness") end
	erAff("shadowmadness")
	targetIshere = true
end
