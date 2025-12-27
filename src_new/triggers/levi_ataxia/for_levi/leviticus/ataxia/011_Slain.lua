--[[mudlet
type: trigger
name: Slain
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Basher
- Bashing
- Basher Lines
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
- pattern: ^You have slain (.+), retrieving the corpse.$
  type: 1
]]--

if type(target) == "number" and ataxiaBasher.enabled then
	bashConsoleEcho("denizen", target.." slain!")
	if not ataxiaBasher.manual then
		deleteFull()
	end
	bashStats.slain = bashStats.slain + 1
  ataxiaBasher.shielded = false
	if ataxiaTemp.canJinx then
		ataxiaTemp.canJinx = false
	end
	
	ataxiaTemp.mobhealth = 0
end

	local area = gmcp.Room.Info.area
	if not table.contains(ataxiaBasher.targetList[area], matches[2]) then
		ataxiaBasher_addmob(matches[2])
	end

