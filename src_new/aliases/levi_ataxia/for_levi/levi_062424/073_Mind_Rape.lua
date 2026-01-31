--[[mudlet
type: alias
name: Mind Rape
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- LeviticusREG
- Leviticus
- Monks
- Monk
- Telepathy
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^mrap$
command: ''
packageName: ''
]]--

	if affstrack.score.impatience<100 then
			send("cq all|queue add eqbal mind impatience " ..target)
	
	elseif affstrack.score.confusion<100 then
	send("cq all|queue add eqbal mind confuse " ..target)
		
	elseif affstrack.score.disrupt<100 then
	send("cq all|queue add eqbal mind disrupt " ..target)
	else 
	send("cq all|queue add eqbal mind batter " ..target)
	end