if matches[2]==target then
selectCurrentLine() fg("a_yellow") bg("black") 
replace("" ..matches[2].. " [NEEDLE: Crushed Throat]")
end


send("pt " ..matches[2].. ": Crushed Throat")
   
tarAffed("crushedthroat")
if applyAffV3 then applyAffV3("crushedthroat") end
tneedle = 100
