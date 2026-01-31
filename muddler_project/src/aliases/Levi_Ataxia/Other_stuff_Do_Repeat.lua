if matches[2] then
	ataxiaTemp.doRepeat = matches[2]
	ataxiaEcho("Will repeat "..ataxiaTemp.doRepeat.." until stopped.")
	send("queue addclear free "..ataxiaTemp.doRepeat)
else
	ataxiaTemp.doRepeat = nil
	send("cq eqbal")
	ataxiaEcho("No longer repeating actions.")
end