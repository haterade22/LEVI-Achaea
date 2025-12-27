--[[mudlet
type: trigger
name: Instill
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
- pattern: ^You make a sharp gesture toward (\w+), disrupting \w+ aura with the (\w+) affliction.$
  type: 1
]]--

if isTargeted(matches[2]) then
	tarAffed(matches[3])
	if readAuraAffs and readAuraAffs.count then
		readAuraAffs.count = readAuraAffs.count + 1
	end
  
  predictBal("eq", 1.8)	
end