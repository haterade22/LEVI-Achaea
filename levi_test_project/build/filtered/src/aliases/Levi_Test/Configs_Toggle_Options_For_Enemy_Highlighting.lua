local x = { i = "italics", b = "bold", u = "underline" }
local opt = x[matches[2]]
if not ataxiaNDB.enemySettings[opt] then
	ataxiaNDB.enemySettings[opt] = true
	ataxiaEcho("Enemies <green>will now have <NavajoWhite>"..opt.." applied to it.")
else
	ataxiaNDB.enemySettings[opt] = false
	ataxiaEcho("Enemies <red>will no longer have <NavajoWhite>"..opt.." applied to it.")
end
ataxiaNDB_enemyHighlights()