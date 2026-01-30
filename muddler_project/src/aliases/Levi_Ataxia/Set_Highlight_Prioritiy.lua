local type, colour = matches[2], matches[3]

if ataxiaNDB.highlightPriority ~= matches[2] then
	ataxiaNDB.highlightPriority = matches[2]
	ataxiaEcho("Highlighting will give priority to "..ataxiaNDB.highlightPriority..".")
	ataxiaNDB_enemyHighlights()
else
	ataxiaEcho("Already prioritising highlighting of that.")
end
