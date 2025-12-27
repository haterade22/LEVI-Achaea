--[[mudlet
type: trigger
name: Get Skill
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Class Stuff
- Depthswalker
- Grab Terminus Abilities
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
- pattern: ^([A-Z'][a-z']+)\s+(.+).$
  type: 1
]]--

if not matches[1]:find("To gain further") then
	selectString(matches[2], 1)
	if isAnsiFgColor(16) then
		ataxiaTables.depthswalker.abilities[matches[2]:lower()] = true
	end
end

if updating_terminus_abilities then
	deleteLine()
end