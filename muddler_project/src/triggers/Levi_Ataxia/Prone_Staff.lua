selectCurrentLine() fg("a_yellow") bg("black") 
replace("" ..matches[2].. " [PRONE]")
tarAffed("prone")
if applyAffV3 then applyAffV3("prone") end
send("pt " ..matches[2].. ": prone")

