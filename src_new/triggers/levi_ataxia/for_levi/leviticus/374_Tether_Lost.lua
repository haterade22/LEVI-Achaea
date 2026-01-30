--[[mudlet
type: trigger
name: Tether Lost
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Spiritlore System
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
- pattern: Your tether to (\w+), .+ is severed.
  type: 1
- pattern: You sever your spiritual tether with (\w+), .+.
  type: 1
]]--

shaman.spiritlore.tether = nil
if matches[2] == "Tarnel" and shaman.spiritisbound("Tarnel") then
	shaman.unboundspirit("Tarnel")
end


if matches[2] == "Marak" and string.find(line, "severed") then
  ataxiaTemp.dollFashions = 0
end