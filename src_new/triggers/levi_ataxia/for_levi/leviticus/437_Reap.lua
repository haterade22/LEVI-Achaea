--[[mudlet
type: trigger
name: Reap
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes A-J
- Depthwalker
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
conditonLineDelta: 1
mStayOpen: 0
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ^You unleash a vicious reaping blow at (\w+) with .+.$
  type: 1
]]--

if not affs_to_colour then populate_aff_colours() end


local aff = venom_to_aff(envenomList[1])

if type(target) ~= "number" and isTargeted(matches[2]) then
	tarAffed(aff)
	targetIshere = true
	disableTimer("TargetOutOfRoom")
end
	if haveAff("timeloop") then
		checkTimeloop = false
		enableTrigger("Timeloop Failsafe Update")
	end



--if type(target) ~= "number" and isTargeted(matches[2]) then	
 -- send("assess "..target..(ataxia.settings.separator or "::").."contemplate "..target)--end