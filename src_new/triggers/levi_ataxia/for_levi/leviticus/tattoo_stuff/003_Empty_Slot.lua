--[[mudlet
type: trigger
name: Empty Slot
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
- pattern: ^(Head|Torso|Left arm|Left Arm|Right arm|Right Arm|Left leg|Left Leg|Right leg|Right Leg|Back)\s+<empty>\s+---\s+---$
  type: 1
]]--

local slot = matches[2]:lower()
slot = slot:title()
for i,v in pairs(tattoosOnMe) do
	if i == slot then
		if #tattoosOnMe[i][1] == 0 then
			tattoosOnMe[i][1] = "empty"
		else
			tattoosOnMe[i][2] = "empty"
		end
		break
	end
end
deleteLine()