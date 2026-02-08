enableTrigger("Hyperfocus Detection")

local short = {rl = "right leg", ll = "left leg", t = "torso", h = "head", ra = "right arm", la = "left arm"}
local limb = (short[matches[3]] or matches[3])

send("queue addclear free hyperfocus "..limb,false)