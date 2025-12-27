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
	erAff("slickness")
	erAff("bloodfire")
  erAff("selarnia")
  erAff("frostbite")
	if matches[3] == "body" then
		erAff("anorexia")
		erAff("itching")
  
  
  if tburns == nil then 
    tburns = 0
  elseif tburns == 0 then 
    tburns = 0
  elseif tburns == 1 then
    tburns = 0
  elseif tburns == 2 then
    tburns = 1
  elseif tburns == 3 then
    tburns = 2
  elseif tburns == 4 then
    tburns = 3
  elseif tburns == 5 then
    tburns = 4
  end
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

