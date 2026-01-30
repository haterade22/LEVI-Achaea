ataxiaTemp.embed = true
ataxiaTemp.vibeSpinner = matches[2]

--reset embed timer after 6s
if embedTimer then killTimer(embedTimer) end
embedTimer = tempTimer(6, [[embedTimer = nil;embed = false]])
