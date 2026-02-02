--[[mudlet
type: trigger
name: Shield Strip
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Remove Afflictions
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
- pattern: ^You cast a spell of erosion at (\w+).$
  type: 1
- pattern: ^You raze (\w+)'s magical shield with .+.$
  type: 1
- pattern: ^You whip .+ through the air in front of (\w+), to no effect.$
  type: 1
- pattern: ^You conjure a blade of ice and drive it straight through the magical shield surrounding (\w+), causing it to explode
    in a shower of prismatic shards.$
  type: 1
- pattern: ^Directing the energy of copper, you send myriad russet streams towards (\w+), shattering \w+ shield.$
  type: 1
- pattern: ^Directing the energy of copper, you send myriad russet streams towards (\w+), which whip around \w+ ineffectually.$
  type: 1
- pattern: ^Your shadow leaps for (\w+), hammering (\w+) shield in a silent frenzy that causes it to explode in a shower of
    prismatic shards.$
  type: 1
- pattern: ^You command your gremlin to shatter the defences surrounding (\w+).$
  type: 1
- pattern: ^You whip up a gale, sending it towards (\w+).$
  type: 1
- pattern: ^You bid your guardian angel to strip a defence from (\w+).$
  type: 1
]]--

if isTargeted(matches[2]) then
	tAffs.shield = false
	if removeAffV3 then removeAffV3("shield") end
	selectString(line,1)
	setBold(true)
	fg("NavajoWhite")
	resetFormat()
end

