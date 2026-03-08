--[[mudlet
type: trigger
name: Unnamable
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes K-S
- Occultist
- Occultism
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
- pattern: ^(\w+) has been struck down by (\d+) curses of the unnamable.$
  type: 1
]]--

local num = tonumber(matches[3])
if isTargeted(matches[2]) then
	if num == 1 then
		tarAffed("stupidity")
	elseif num == 2 then
		tarAffed("stupidity", "confusion")
	else
		tarAffed("stupidity", "confusion", "dementia")
	end
	if readAuraAffs and readAuraAffs.count then
		readAuraAffs.count = readAuraAffs.count + num 
	end
  
  predictBal("eq", 2.4)	
end