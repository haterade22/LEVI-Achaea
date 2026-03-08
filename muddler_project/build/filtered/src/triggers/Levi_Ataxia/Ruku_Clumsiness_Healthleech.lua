selectCurrentLine() fg("a_yellow") bg("black") 
replace("" ..target.. " [RUKU: Clumsiness | Healthleech]")

if tAffs.clumsiness then
send("pt " ..target..": clumsiness healthleech")
			tarAffed("healthleech")
			tarAffed("clumsiness")
elseif not tAffs.clumsiness then
  			send("pt " ..target..": clumsiness")
			tarAffed("clumsiness")
end		
