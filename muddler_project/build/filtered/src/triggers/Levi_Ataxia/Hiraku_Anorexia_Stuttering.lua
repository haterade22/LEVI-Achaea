selectCurrentLine() fg("a_yellow") bg("black") 
replace("" ..matches[2].. " [Hiraku: Anorexia | Stuttering]")

if not tAffs.prone then
send("pt " ..matches[2].. ": anorexia stuttering")
tarAffed("anorexia")
tarAffed("stuttering")
if applyAffV3 then applyAffV3("anorexia"); applyAffV3("stuttering") end
end

if tAffs.prone then
				send("pt " ..matches[2].. ": Anorexia Stuttering Stunned")
			tarAffed("anorexia")
			tarAffed("stuttering")
			if applyAffV3 then applyAffV3("anorexia"); applyAffV3("stuttering") end
      
      
end