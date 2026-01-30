--send("empower priority set kena isaz sleizak")
--send("empower priority set isaz sowulu tiwaz")

if not ataxiaTemp.ignoreShield then
	moveCursor(0, getLineNumber())
if matches[2] == "inguz" then tarAffed("paralysis") 
elseif matches[2] == "sleizak" then 
tarAffed("weariness") 
send("pt " ..target.. ": nausea")
if not wearicheck then wearicheck = true
wearicheck = tempTimer(4, [[ wearicheck = nil ]])

end
elseif matches[2] == "loshre" then tarAffed("addiction")
end
	moveCursorEnd()

end
ataxiaTemp.ignoreShield = nil