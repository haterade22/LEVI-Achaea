selectCurrentLine() fg("a_yellow") bg("black") 
replace("" ..matches[2].. " [Hiru: Dizziness | Blackout]")
 
if not tAffs.prone then
  		send("pt " ..matches[2].. ": dizziness")
			tarAffed("dizziness")
			if applyAffV3 then applyAffV3("dizziness") end
			
elseif tAffs.prone then
				send("pt " ..matches[2].. ": dizziness blackout")
			tarAffed("dizziness")
			if applyAffV3 then applyAffV3("dizziness") end

end
