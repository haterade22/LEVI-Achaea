--[[mudlet
type: script
name: Burn Handling
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Ataxia
- System-related
- Curing Stuff
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

function ataxia_weAreBurning(stacks)
	if not affed("burning") or ataxia.afflictions.burning ~= stacks then
		ataxia.afflictions.burning = stacks
		raiseEvent("aff gained", "burning")
	end
end

function ataxia_burnsDecreased()
	if not affed("burning") then return end
	local stack = ataxia.afflictions.burning
	if stack > 1 then
		stack = stack - 1
	end
	ataxia.afflictions.burning = stack
	raiseEvent("aff gained", "burning")
end