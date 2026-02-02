--[[mudlet
type: trigger
name: Quicksilver
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Remove Afflictions
- Herbs
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
- pattern: ^(\w+) applies a (sileris berry|quicksilver droplet) to \w+\.$
  type: 1
]]--

if isTargeted(matches[2]) then
tdeliverance = false
	erAff("slickness")
	if removeAffV3 then removeAffV3("slickness") end
	erAff("paralysis")
	if removeAffV3 then removeAffV3("paralysis") end
	-- Note: fangbarrier comes later with "metallic shell" message
	targetIshere = true
end