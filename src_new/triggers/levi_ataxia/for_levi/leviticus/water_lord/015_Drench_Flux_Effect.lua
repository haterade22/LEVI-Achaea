--[[mudlet
type: trigger
name: Drench Flux Effect
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes Other
- Water Lord
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
- pattern: ^Tendrils of water writhe and burrow into the eyes and nose of (\w+)\, seeking and questing\.$
  type: 1
]]--

if isTargeted(matches[2]) then
	tarAffed("asthma", "anorexia", "slickness")
	if applyAffV3 then applyAffV3("asthma"); applyAffV3("anorexia"); applyAffV3("slickness") end
	tarBonusAff("slickness")
end