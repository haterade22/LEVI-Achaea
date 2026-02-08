--send("empower priority set kena isaz sleizak")
--send("empower priority set isaz sowulu tiwaz")

if not ataxiaTemp.ignoreShield then
	moveCursor(0, getLineNumber())
if matches[2] == "inguz" then tarAffed("paralysis"); if applyAffV3 then applyAffV3("paralysis") end
elseif matches[2] == "sleizak" then
tarAffed("weariness")
if applyAffV3 then applyAffV3("weariness") end
send("pt " ..target.. ": nausea")
if not wearicheck then wearicheck = true
wearicheck = tempTimer(4, [[ wearicheck = nil ]])

end
elseif matches[2] == "loshre" then tarAffed("addiction"); if applyAffV3 then applyAffV3("addiction") end
end
	moveCursorEnd()

end
ataxiaTemp.ignoreShield = nil