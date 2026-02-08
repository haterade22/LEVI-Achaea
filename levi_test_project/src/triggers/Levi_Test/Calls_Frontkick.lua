selectCurrentLine() fg("a_yellow") bg("black") 
replace("" ..matches[2].. " [Frontkick: Prone]")


send("pt " ..matches[2].. ": prone")
tarAffed("prone")
if applyAffV3 then applyAffV3("prone") end
			
