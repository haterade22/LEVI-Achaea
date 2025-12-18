-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Levi  Scripts > ZulahGUI - Saonji Edit > zGUI Redux > Logger > zgui.sendLogger

function zgui.sendLogger(colorCode, logMessage)
  zgui.trueTime = string.cut(getTime(true, "hh:mm:ss:zzz"), 11)
	cecho("logDisplay", "<gold>"..zgui.trueTime)
	cecho("logDisplay", "<"..colorCode..">-- "..logMessage.."\n")
	deleteLine()
end