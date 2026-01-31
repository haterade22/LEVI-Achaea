--[[mudlet
type: trigger
name: Reb Down
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Bard
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
- pattern: ^You raze (\w+)'s aura of rebounding with a Soulpiercer\.$
  type: 1
- pattern: ^You whip .+ through the air in front of (\w+), to no effect\.$
  type: 1
]]--

targreb = false
tAffs.rebounding = false
removeAffV3("rebounding")
-- V2 tracking support
if ataxia and ataxia.settings and ataxia.settings.useAffTrackingV2 then
	if removeAffV2 then
		removeAffV2("rebounding")
	elseif tAffsV2 then
		tAffsV2.rebounding = 0
	end
end