selectCurrentLine() fg("a_yellow") bg("black") 
replace("" ..matches[2].. " [Nervestrike: Paralysis]")
 
send("pt " ..matches[2].. ": paralysis")
tarAffed("paralysis")
if applyAffV3 then applyAffV3("paralysis") end