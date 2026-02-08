if matches[2]== target then
selectCurrentLine() fg("a_yellow") bg("black") 
replace("" ..matches[2].. " [SPINKICK]")
end
if partyrelay and not ataxia.afflictions.aeon then
send("pt " ..matches[2].. ": Spinkicked! A lot of Damage")
end