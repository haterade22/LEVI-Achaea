--[[mudlet
type: trigger
name: DSL 1
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- slc
- Knight Limb Attacks
- DSL
attributes:
  isActive: 'yes'
  isFolder: 'no'
  isTempTrigger: 'no'
  isMultiline: 'yes'
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
- pattern: ^(\w+) viciously \w+ ([^\.]+) into your (.*)\.$
  type: 1
- pattern: '1'
  type: 5
]]--


--^\w+ viciously jabs .+ into your (.+)\.$
local weapons = {"Soulpiercer", "Eagle's Scream","rapier"}

for i in pairs(weapons) do
 if not string.find(multimatches[1][3], weapons[i]) then

	slc_last_limb = multimatches[1][4]

	dualcweapcheck = true
	tempTimer(1, [[dualcweapcheck = false]] )	
	
 end
end
