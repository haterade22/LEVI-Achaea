selectCurrentLine() fg("a_yellow") bg("black") 
replace("" ..matches[2].. " [Hiru: Dizziness | Blackout]")
 
if not tAffs.prone then
  		send("pt " ..matches[2].. ": dizziness")
			tarAffed("dizziness")
			
elseif tAffs.prone then
				send("pt " ..matches[2].. ": dizziness blackout")
			tarAffed("dizziness")

end
