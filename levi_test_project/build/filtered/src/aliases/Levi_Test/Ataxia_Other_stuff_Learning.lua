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