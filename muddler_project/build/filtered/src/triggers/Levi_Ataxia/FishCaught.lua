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