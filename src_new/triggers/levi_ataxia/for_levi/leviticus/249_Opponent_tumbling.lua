--[[mudlet
type: trigger
name: Opponent tumbling
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Bard
- Bard
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
- pattern: ^(\w+) begins to tumble towards the (\w+)\.$
  type: 1
]]--

if matches[2]:upper() == target:upper() then
	if gmcp.Char.Status.class == "Bard" then send("queue addclear class sing noise at "..target) end
end

if matches[2] == target then
  if partyrelay then send("pt " ..target.. ": tumbling " ..matches[3])
  end
end 


if matches[2] == target then
ataxia_boxEcho(matches[2].." TUMBLING "..matches[3], "orange:black")
ataxia_boxEcho(matches[2].." TUMBLING "..matches[3], "orange:black")
ataxia_boxEcho(matches[2].." TUMBLING "..matches[3], "orange:black")
opptumble = true
end