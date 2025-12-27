--[[mudlet
type: alias
name: Reset a target's limb
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- Ataxia-DownloadThis
- Ataxia
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
	tLimbs = {H=0, T=0, RL=0, LL=0, RA=0, LA=0}
	ataxia_Echo("Reset target's limbs.")
elseif limbs[matches[2]] then
	tLimbs[matches[2]:upper()] = 0
	ataxia_Echo("Reset target's "..limbs[matches[2]]..".")
else
	ataxia_Echo("Invalid limb to reset. Try: h, t, rl, ll, la, ra or all.")
end