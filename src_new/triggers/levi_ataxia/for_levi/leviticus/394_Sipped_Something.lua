--[[mudlet
type: trigger
name: Sipped Something
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Remove Afflictions
- Groups
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
- pattern: ^(\w+) takes a drink from (.+).$
  type: 1
]]--

if isTargeted(matches[2]) then
tdeliverance = false
  if passiveFailsafe then restorePassiveCure() end
	erAff("anorexia")
	if removeAffV3 then removeAffV3("anorexia") end

	if haveAff("voyria") and (pariah and not pariah.latency) then
		erAff("voyria")
		if removeAffV3 then removeAffV3("voyria") end
	end

  if haveAff("voyria") then
		erAff("voyria")
		if removeAffV3 then removeAffV3("voyria") end
	end

	if haveAff("nospeed") then
		tempTimer(3, [[ erAff("nospeed"); if removeAffV3 then removeAffV3("nospeed") end ]])
	end
  
  if ataxiaTemp.lastAssess then ataxiaTemp.lastAssess = ataxiaTemp.lastAssess + 21 end
  
	targetIshere = true
end