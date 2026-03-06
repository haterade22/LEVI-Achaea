selectCurrentLine() fg("a_yellow") bg("black") 
replace("" ..matches[2].. " [Livestrike: Asthma]")
 
send("pt " ..matches[2].. ": asthma")
tarAffed("asthma")
if applyAffV3 then applyAffV3("asthma") end
