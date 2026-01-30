if gmcp.Char.Status.class == "Apostate" and demon() == "nightmare" then

maretick = true
tempTimer(2, [[maretick = false]])


else

maretick = false
disableTimer("NIGHTMARE TICK")

end

