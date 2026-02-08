selectCurrentLine() fg("a_yellow") bg("black") 
replace("" ..target.. " [RUKU: Clumsiness | Healthleech]")

if tAffs.clumsiness then
send("pt " ..target..": clumsiness healthleech")
			tarAffed("healthleech")
			if applyAffV3 then applyAffV3("healthleech") end
			tarAffed("clumsiness")
			if applyAffV3 then applyAffV3("clumsiness") end
elseif not tAffs.clumsiness then
  			send("pt " ..target..": clumsiness")
			tarAffed("clumsiness")
			if applyAffV3 then applyAffV3("clumsiness") end
end		
