--[[mudlet
type: trigger
name: Readaura Get Affs
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes K-S
- Occultist
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
- pattern: ^You perceive that (\w+) suffers from (\d+) physical afflictions and (\d+) mental afflictions.$
  type: 1
]]--

local affcount = tonumber(matches[3]) + tonumber(matches[4])
local instillables = {
	"paralysis", "healthleech", "clumsiness", "darkshade",  "haemophilia", "sensitivity", "asthma", "slickness",
}
readAuraAffs.count = tonumber(matches[3])
if isTargeted(matches[2]) then
	if readAuraAffs.count == 0 then
		for _, aff in pairs(instillables) do
			erAff(aff)
		end
	end
end

if tonumber(matches[4]) == 0 then
  erAff("addiction")
else
  tAffs.addiction = true
end