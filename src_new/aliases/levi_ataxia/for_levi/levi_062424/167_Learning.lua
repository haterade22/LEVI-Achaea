--[[mudlet
type: alias
name: Learning
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
regex: ^learn (\w+) (\w+)$
command: ''
packageName: ''
]]--

--usage: learn <skill> <tutor>
--example: learn curses dunn
ataxiaTemp.learning = matches[2]
ataxiaTemp.learnFrom = matches[3]

if matches[2] == "none" then
	ataxiaTemp.learning = nil
	ataxiaTemp.learnFrom = nil
	ataxiaEcho("No longer learning.")
else
	send("learn 20 "..matches[2].." from "..matches[3])
	ataxiaEcho("Going to learn "..matches[2].." from "..matches[3].." until stopped.")
end