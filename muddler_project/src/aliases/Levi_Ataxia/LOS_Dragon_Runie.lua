if gmcp.Char.Status.class == "Blue Dragon" then 
if matches[2] == "n" then
send("breathstream " ..target.. " north;summon ice")
dsdir = "north"
elseif matches[2] == "s" then
send("breathstream " ..target.. " south;summon ice")
dsdir = "south"
elseif matches[2] == "e" then
send("breathstream " ..target.. " east;summon ice")
dsdir = "east"
elseif matches[2] == "w" then
send("breathstream " ..target.. " west;summon ice")
dsdir = "west"
elseif matches[2] == "se" then
send("breathstream " ..target.. " southeast;summon ice")
dsdir = "southeast"
elseif matches[2] == "ne" then
send("breathstream " ..target.. " northeast;summon ice")
dsdir = "northeast"
elseif matches[2] == "nw" then
send("breathstream " ..target.. " northwest;summon ice")
dsdir = "northwest"
elseif matches[2] == "in" then
send("breathstream " ..target.. " in;summon ice")
dsdir = "in"
elseif matches[2] == "out" then
send("breathstream " ..target.. " out;summon ice")
dsdir = "out"
elseif matches[2] == "u" then
send("breathstream " ..target.. " up;summon ice")
dsdir = "up"
elseif matches[2] == "d" then
send("breathstream " ..target.. " down;summon ice")
dsdir = "down"
elseif matches[2] == "sw" then
send("breathstream " ..target.. " southwest;summon ice")
dsdir = "southwest"
end
end

if gmcp.Char.Status.class == "Runewarden" then
if matches[2] == "n" then
send("remove bow;wield bow;shoot " ..target.. " north")
dsdir = "north"
elseif matches[2] == "s" then
send("remove bow;wield bow;remove bow;wield bow;shoot " ..target.. " south")
dsdir = "south"
elseif matches[2] == "e" then
send("remove bow;wield bow;remove bow;wield bow;shoot " ..target.. " east")
dsdir = "east"
elseif matches[2] == "w" then
send("remove bow;wield bow;remove bow;wield bow;shoot " ..target.. " west")
dsdir = "west"
elseif matches[2] == "se" then
send("remove bow;wield bow;remove bow;wield bow;shoot " ..target.. " southeast")
dsdir = "southeast"
elseif matches[2] == "ne" then
send("remove bow;wield bow;remove bow;wield bow;shoot " ..target.. " northeast")
dsdir = "northeast"
elseif matches[2] == "nw" then
send("remove bow;wield bow;remove bow;wield bow;shoot " ..target.. " northwest")
dsdir = "northwest"
elseif matches[2] == "in" then
send("remove bow;wield bow;remove bow;wield bow;shoot " ..target.. " in")
dsdir = "in"
elseif matches[2] == "out" then
send("remove bow;wield bow;remove bow;wield bow;shoot " ..target.. " out")
dsdir = "out"
elseif matches[2] == "u" then
send("remove bow;wield bow;remove bow;wield bow;shoot " ..target.. " up")
dsdir = "up"
elseif matches[2] == "d" then
send("remove bow;wield bow;remove bow;wield bow;shoot " ..target.. " down")
dsdir = "down"
elseif matches[2] == "sw" then
send("remove bow;wield bow;remove bow;wield bow;shoot " ..target.. " southwest")
dsdir = "southwest"
end
end 


if gmcp.Char.Status.class == "Serpent" then
if matches[2] == "n" then
send("remove bow;wield bow;snipe " ..target.. " north")
dsdir = "north"
elseif matches[2] == "s" then
send("remove bow;wield bow;remove bow;wield bow;snipe " ..target.. " south")
dsdir = "south"
elseif matches[2] == "e" then
send("remove bow;wield bow;remove bow;wield bow;snipe " ..target.. " east")
dsdir = "east"
elseif matches[2] == "w" then
send("remove bow;wield bow;remove bow;wield bow;snipe " ..target.. " west")
dsdir = "west"
elseif matches[2] == "se" then
send("remove bow;wield bow;remove bow;wield bow;snipe " ..target.. " southeast")
dsdir = "southeast"
elseif matches[2] == "ne" then
send("remove bow;wield bow;remove bow;wield bow;snipe " ..target.. " northeast")
dsdir = "northeast"
elseif matches[2] == "nw" then
send("remove bow;wield bow;remove bow;wield bow;snipe " ..target.. " northwest")
dsdir = "northwest"
elseif matches[2] == "in" then
send("remove bow;wield bow;remove bow;wield bow;snipe " ..target.. " in")
dsdir = "in"
elseif matches[2] == "out" then
send("remove bow;wield bow;remove bow;wield bow;snipe " ..target.. " out")
dsdir = "out"
elseif matches[2] == "u" then
send("remove bow;wield bow;remove bow;wield bow;snipe " ..target.. " up")
dsdir = "up"
elseif matches[2] == "d" then
send("remove bow;wield bow;remove bow;wield bow;snipe " ..target.. " down")
dsdir = "down"
elseif matches[2] == "sw" then
send("remove bow;wield bow;remove bow;wield bow;snipe " ..target.. " southwest")
dsdir = "southwest"
end
end 