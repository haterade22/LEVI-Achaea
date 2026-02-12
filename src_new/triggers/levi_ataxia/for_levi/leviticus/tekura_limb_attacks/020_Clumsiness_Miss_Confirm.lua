--[[mudlet
type: trigger
name: Clumsiness Miss Confirm
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- slc
- Tekura Limb Attacks
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
- pattern: ^\w+ misses\.$
  type: 1
]]--

if clumsiness_lastAttacker and isTargeted(clumsiness_lastAttacker) then
	tarAffed("clumsiness")
	if applyAffV3 then applyAffV3("clumsiness") end

	-- V3 integration: collapse branches (proves clumsiness present)
	if onTargetFumbleV3 then onTargetFumbleV3() end
end
