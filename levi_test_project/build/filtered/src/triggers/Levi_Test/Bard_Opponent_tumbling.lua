if matches[2]:upper() == target:upper() then
	if gmcp.Char.Status.class == "Bard" then send("queue addclear class sing noise at "..target) end
end

if matches[2] == target then
  if partyrelay then send("pt " ..target.. ": tumbling " ..matches[3])
  end
end 


if matches[2] == target then
ataxia_boxEcho(matches[2].." TUMBLING "..matches[3], "orange:black")
ataxia_boxEcho(matches[2].." TUMBLING "..matches[3], "orange:black")
ataxia_boxEcho(matches[2].." TUMBLING "..matches[3], "orange:black")
opptumble = true
end