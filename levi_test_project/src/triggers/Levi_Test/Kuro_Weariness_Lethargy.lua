selectCurrentLine() fg("a_yellow") bg("black") 
replace("" ..matches[3].. " [KURO: Weariness | Lethargic]")
 
if tAffs.weariness then
        	send("pt " ..matches[3].. ": lethargy")
			tarAffed("lethargy")
			if applyAffV3 then applyAffV3("lethargy") end
elseif not tAffs.weariness then
  			send("pt " ..matches[3].. ": weariness")
			tarAffed("weariness")
			if applyAffV3 then applyAffV3("weariness") end
end
