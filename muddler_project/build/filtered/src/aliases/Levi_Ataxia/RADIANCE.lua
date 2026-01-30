radiance = radiance or false


if not radiance then radiance = true
	send("curing off")
  
  send("queue addclear free mind radiance "..target)
  
elseif radiance then radiance = false
	send("curing on")
end

ataxiaEcho("System has been "..(ataxia.settings.paused and "<red>paused." or "<green>unpaused."))