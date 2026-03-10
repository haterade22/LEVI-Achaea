--[[mudlet
type: trigger
name: Applied Body/Skin
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
- pattern: ^(\w+) takes some salve from a vial and rubs it on \w+ (skin|body).$
  type: 1
]]--

if isTargeted(matches[2]) then
tdeliverance = false
  if passiveFailsafe then restorePassiveCure() end
	-- V2 tracking support: salve cures slickness and other affs
	if matches[3] == "body" then
		if onTargetSalveBodyV2 then onTargetSalveBodyV2(matches[2]) end
	else
		if onTargetSalveSkinV2 then onTargetSalveSkinV2(matches[2]) end
	end
	-- V3 integration: salve cure branching (body or skin)
	if onSalveCureV3 then onSalveCureV3(matches[3]) end
	erAff("slickness")
	erAff("bloodfire")
  erAff("selarnia")
  erAff("frostbite")
	if matches[3] == "body" then
		erAff("anorexia")
		erAff("itching")
  
  
  magi.offense = magi.offense or {}
  magi.offense.state = magi.offense.state or {}
  magi.offense.state.burns = math.max((magi.offense.state.burns or 0) - 1, 0)
  tburns = magi.offense.state.burns
  selectCurrentLine() fg("slate_grey")
  cecho(" <DimGrey>[<red>"..tburns.."/5<DimGrey>]")
    
    
	elseif not haveAff("hypothermia") then
		local freeze = {"frozen", "shivering", "nocaloric"}
		for _, aff in pairs(freeze) do
			if haveAff(aff) then
				erAff(aff)
				break
			end
		end
	end
	targetIshere = true
end

