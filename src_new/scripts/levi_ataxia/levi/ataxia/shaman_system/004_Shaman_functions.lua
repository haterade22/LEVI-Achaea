--[[mudlet
type: script
name: Shaman functions
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Ataxia
- Shaman System
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

function shecho(text)
	cecho("\n<orange_red>[Shaman]:<reset> " .. text .. "\n")
end

function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end