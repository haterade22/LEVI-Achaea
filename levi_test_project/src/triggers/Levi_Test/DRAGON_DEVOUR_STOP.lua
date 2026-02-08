ataxia.settings.paused = false
  send("curing on")
ataxiaEcho("System has been "..(ataxia.settings.paused and "<red>paused." or "<green>unpaused."))
ataxia_boxEcho("BUGGER THEY GOT AWAY", "green")