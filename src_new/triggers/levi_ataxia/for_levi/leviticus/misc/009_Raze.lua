--[[mudlet
type: trigger
name: Raze
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes K-S
- Pariah
- Misc
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
- pattern: ^There is a sharp cracking sound from the air directly in front of (.+), but nothing else seems to happen.$
  type: 1
- pattern: ^A violent cracking sound from the air in front of (.+) heralds \w+ magical shield exploding into a shower of translucent
    shards.$
  type: 1
- pattern: ^A savage slash of your knife trails crimson fire as you carve the logograph of the (\w+) into the air before (.+).$
  type: 1
]]--

if type(target) == "string" and isTargeted(matches[2]) then
	tAffs.shield = false
	if removeAffV3 then removeAffV3("shield") end
	selectString(line,1)
	setBold(true)
	fg("NavajoWhite")
	resetFormat()
end

if ataxiaBasher.enabled then
  if not ataxiaBasher.manual then
    deleteFull()
  end
end