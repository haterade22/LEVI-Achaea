ataxiaTemp.needSymphony = false
if ataxiaTemp.symphTimer then killTimer(ataxiaTemp.symphTimer) end
ataxiaTemp.symphTimer = tempTimer(600, [[ataxiaTemp.symphTimer = nil;
	ataxiaTemp.needSymphony = true
]])

bashConsoleEchom("HAR", "Symphony used.", "goldenrod", "green")