selectCurrentLine() fg("a_yellow") bg("black") 
replace("" ..matches[2].. " [PRONE]")
tarAffed("prone")
send("pt " ..matches[2].. ": prone")

