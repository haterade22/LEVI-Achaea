local limbs = {h = "head", tt = "torso" , rl = "right leg", ll = "left leg", ra = "right arm", la = "left arm",
	c = "center", l = "left", r = "r"
}
if ataxia.parry ~= "manual" then
	ataxia.parry = "manual"
	ataxiaEcho("Parrying method changed to manual.")
end
send((matches[1]:find("tp") and "true" or "").."parry "..limbs[matches[2]],false)
	