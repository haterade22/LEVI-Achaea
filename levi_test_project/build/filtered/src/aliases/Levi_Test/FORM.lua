send("clearqueue all;prevail")
expandAlias("mconfig gallop false")
ataxia.settings.paused = true
ataxiaEcho("System has been "..(ataxia.settings.paused and "<red>paused." or "<green>unpaused."))
shape = 0