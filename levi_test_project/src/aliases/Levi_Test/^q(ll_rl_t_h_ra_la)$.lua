if tAffs.shield then
send("queue addclear free soulbleed batter " ..target)
elseif not tAffs.shield then
  if ataxiaTemp.fractures.crackedribs >= 3 then
  send("soulbleed reave " ..target)

elseif matches[2] == "ll" then
send("queue addclear free soulbleed onslaught " ..target.. " left leg")
elseif matches[2] == "rl" then
send("queue addclear free soulbleed onslaught " ..target.. " right leg")
elseif matches[2] == "ra" then
send("queue addclear free soulbleed onslaught " ..target.. " right arm")
elseif matches[2] == "la" then
send("queue addclear free soulbleed onslaught " ..target.. " left arm")
elseif matches[2] == "t" then
send("queue addclear free soulbleed onslaught " ..target.. " torso")
elseif matches[2] == "h" then
send("queue addclear free soulbleed onslaught " ..target.. " head")
  end
end