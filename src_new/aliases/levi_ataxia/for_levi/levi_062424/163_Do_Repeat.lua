--[[mudlet
type: alias
name: Do Repeat
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- Ataxia-DownloadThis
- Ataxia
- Other stuff
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: '^dor(?: (.+)|)$'
command: ''
packageName: ''
]]--

if matches[2] then
	ataxiaTemp.doRepeat = matches[2]
	ataxiaEcho("Will repeat "..ataxiaTemp.doRepeat.." until stopped.")
	send("queue addclear free "..ataxiaTemp.doRepeat)
else
	ataxiaTemp.doRepeat = nil
	send("cq eqbal")
	ataxiaEcho("No longer repeating actions.")
end