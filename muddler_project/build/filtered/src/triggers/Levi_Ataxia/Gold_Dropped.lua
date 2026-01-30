if not ataxia_paused() then
	if not found_target then
    if ataxia.settings.goldcommand then
      send("queue addclear free "..ataxia.settings.goldcommand)
    else
		  send("queue addclear free get gold"..ataxia.settings.separator.."put gold in pack409321")
    end
	end
end

if type(target) == "number" and ataxiaBasher.enabled then
	bashConsoleEcho("denizen", "Nicely dropped gold for us!")
    if not ataxiaBasher.manual then
			deleteFull()
		end
end
