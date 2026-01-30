setTriggerStayOpen("Fullsense-Hyena", 0)
enableTrigger("Fullsense-Hyena")
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