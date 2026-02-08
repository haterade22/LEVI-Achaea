bashConsoleEcho("fishing", "Baited line for casting.")
if ataxia.fishing.enabled then
	send("queue addclear free cast line "..ataxia.fishing.direction)
end