dir = dir or ""
if matches[2] == "ll" then
dir = "left leg"
end
if matches[2] == "rl" then
dir = "right leg"
end
if matches[2] == "ra" then
dir = "right arm"
end
if matches[2] == "la" then
dir = "left arm"
end
if matches[2] == "hh" then
dir = "head"
end
if matches[2] == "tt" then
dir = "torso"
end


if tAffs.shield then
send("queue addclear free stand;stand;blast " ..target.. " ;summon ice")
else
send("queue addclear free stand;rend " ..target.. " " ..dir)
end