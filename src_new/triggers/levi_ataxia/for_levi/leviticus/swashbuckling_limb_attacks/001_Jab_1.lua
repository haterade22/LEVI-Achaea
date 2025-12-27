--[[mudlet
type: trigger
name: Jab 1
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- slc
- Swashbuckling Limb Attacks
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
- pattern: ^Lightning-quick, (\w+) \w+ your (.*) with ([^\.]+)\.$
  type: 1
- pattern: '1'
  type: 5
]]--



--^Lightning-quick, \w+ (?:stabs|jabs) your (.+) with
local weapons = {"Soulpiercer", "Eagle's Scream","rapier"}

for i in pairs(weapons) do
 if string.find(multimatches[1][4], weapons[i]) then

	slc_last_limb = multimatches[1][3]

	weapcheck = true
	tempTimer(1, [[weapcheck = false]] )
	
 end
end
