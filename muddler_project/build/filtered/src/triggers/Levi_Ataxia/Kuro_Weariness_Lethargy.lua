selectCurrentLine() fg("a_yellow") bg("black") 
replace("" ..matches[3].. " [KURO: Weariness | Lethargic]")
 
if tAffs.weariness then
        	send("pt " ..matches[3].. ": lethargy")
			tarAffed("lethargy")
elseif not tAffs.weariness then
  			send("pt " ..matches[3].. ": weariness")
			tarAffed("weariness")
end
