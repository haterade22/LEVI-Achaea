--[[mudlet
type: trigger
name: DSL 3
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
- pattern: ^(\w+) swings ([^\.]+) at your (.+) with all \w+ might\.$
  type: 1
- pattern: '1'
  type: 5
]]--


--^\w+ swings .+ at your (.+) with all (?:his|her) might\.$

local weapons = {"Soulpiercer", "Eagle's Scream","rapier"}

for i in pairs(weapons) do
 if not string.find(multimatches[1][3], weapons[i]) then

	slc_last_limb = multimatches[1][4]

	weapcheck = true
	tempTimer(1, [[weapcheck = false]] )		
	
 end
end