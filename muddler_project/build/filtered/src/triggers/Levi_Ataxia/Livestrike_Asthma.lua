selectCurrentLine() fg("a_yellow") bg("black") 
replace("" ..matches[2].. " [Livestrike: Asthma]")
 
send("pt " ..matches[2].. ": asthma")
tarAffed("asthma")
