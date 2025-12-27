--[[mudlet
type: trigger
name: FishCaught
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Fishing
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
conditonLineDelta: 12
mStayOpen: 0
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: '^With a final tug, you finish reeling in the line and land (.+) weighing (\d+) pounds(?: and (\d+) ounces?)?!$'
  type: 1
- pattern: '^With a style born of skill, you reel in (.+) in a single smooth motion\. It looks to weigh (\d+) pounds(?: and
    (\d+) ounces?)?\.$'
  type: 1
- pattern: '^You quickly reel in (.+), landing it with ease! It looks to weigh (\d+) pounds(?: and (\d+) ounces?)?\.$'
  type: 1
- pattern: '^You reel in the last bit of line and your struggle is over\. You''ve landed (.+) weighing (\d+) pounds(?: and
    (\d+) ounces?)?\.$'
  type: 1
- pattern: '^You''ve landed (.+) weighing (\d+) pounds(?: and (\d+) ounces?)?\.$'
  type: 1
]]--

--deleteLine()
--fishParse(matches[2],matches[3],matches[4])
--growlNotify("Fishing","Fish was caught!")
linelength = 0

local comm = ""
if ataxia.fishing.enabled then
	bashConsoleEcho("fishing", "We caught a fishy!")
	fishParse(matches[2],matches[3],matches[4])
	if ataxia.fishing.type == "normal" then
		comm = "get "..ataxia.fishing.bait.." from bucket"..ataxia.settings.separator.."bait hook with "..ataxia.fishing.bait
		send("queue addclear free "..comm)
	end
end