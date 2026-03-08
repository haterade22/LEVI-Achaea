selectCurrentLine() fg("a_yellow") bg("black") 
replace("" ..matches[2].. " [RUKU: Slickness]")
 
send("pt " ..matches[2].. ": slickness")
tarAffed("slickness")
