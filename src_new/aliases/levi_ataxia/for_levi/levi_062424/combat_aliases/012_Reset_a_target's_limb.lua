--[[mudlet
type: alias
name: Reset a target's limb
hierarchy:
- Levi_Ataxia
- Combat
- Combat Aliases
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^limb (\w+)$
command: ''
packageName: ''
]]--

local limbs = {
	h = "head",
	t = "torso",
	rl = "right leg",
	ll = "left leg",
	ra = "right arm",
	la = "left arm",
}
if matches[2] == "all" then
	lb.resetAll(target)
	ataxia_Echo("Reset target's limbs.")
elseif limbs[matches[2]] then
	lb.resetLimb(target, limbs[matches[2]])
	ataxia_Echo("Reset target's "..limbs[matches[2]]..".")
else
	ataxia_Echo("Invalid limb to reset. Try: h, t, rl, ll, la, ra or all.")
end