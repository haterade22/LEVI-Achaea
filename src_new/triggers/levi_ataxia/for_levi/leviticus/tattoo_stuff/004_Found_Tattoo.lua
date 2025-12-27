--[[mudlet
type: trigger
name: Found Tattoo
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Misc Triggers
- Tattoo Stuff
- Tattoo List
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
- pattern: ^(Head|Torso|Left arm|Left Arm|Right arm|Right Arm|Left leg|Left Leg|Right leg|Right Leg|Back)\s+ a (\w+) tattoo\s+(\d+)\s+(Y|N)$
  type: 1
- pattern: ^(Head|Torso|Left arm|Left Arm|Right arm|Right Arm|Left leg|Left Leg|Right leg|Right Leg|Back)\s+ a (\w+) tattoo\s+(art|n/a)\s+(Y|N)$
  type: 1
- pattern: ^(Head|Torso|Left arm|Left Arm|Right arm|Right Arm|Left leg|Left Leg|Right leg|Right Leg|Back)\s+ an (\w+) tattoo\s+(\d+)\s+(Y|N)$
  type: 1
- pattern: ^(Head|Torso|Left arm|Left Arm|Right arm|Right Arm|Left leg|Left Leg|Right leg|Right Leg|Back)\s+ an (\w+) tattoo\s+(art|n/a)\s+(Y|N)$
  type: 1
]]--

local slot = matches[2]:lower()
slot = slot:title()
local tat = matches[3]:title()
local cge = matches[4]
local act = matches[5]
for i,v in pairs(tattoosOnMe) do
	if i == slot then
		if tattoosOnMe[i][1] ~= "empty" and #tattoosOnMe[i][1] == 0 then
			tattoosOnMe[i][1] = {tat, cge, act}
		else
			tattoosOnMe[i][2] = {tat, cge, act}
		end
		break
	end
end

if table.contains(crucialTattoos, tat) then
	table.remove(crucialTattoos, table.index_of(crucialTattoos, tat))
end
deleteLine()