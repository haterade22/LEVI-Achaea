--[[mudlet
type: trigger
name: prompt
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Class Stuff
- Depthswalker
- Fullsense-Monk/DW
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
- pattern: ^You located \d+ subjects.$
  type: 1
- pattern: ''
  type: 7
]]--

setTriggerStayOpen("Fullsense-Monk/DW", 0)
enableTrigger("Fullsense-Monk/DW")
deleteLine()
local sp = ataxia.settings.separator
local pstring = "pt Fullsense info: "

for location, people in pairs(fullSensePeople) do
	cecho("\n<a_blue>[<DimGrey>"..location.."<a_blue>] - ")
	pstring = pstring..sp.."pt ["..location:title().."]: "
	mmp.locateAndEchoSide(location)
	cecho("\n")
	local charstring = "  "
	for ind, person in pairs(fullSensePeople[location]) do
		pstring = pstring..person		
		if ataxiaNDB_Exists(person) then
			charstring = charstring.."<"..ataxiaNDB_getColour(person)..">"..person
		else
			charstring = charstring.."<grey>"..person
		end
		charstring = charstring.."<grey>"..(ind == #fullSensePeople[location] and "." or ", ")
		pstring = pstring..(ind == #fullSensePeople[location] and "." or ", ")
	end
	cecho(charstring.."\n ")
end
ataxiaPromptSub()

if ataxia_raidMode("fullsense") then
  send(pstring)
end