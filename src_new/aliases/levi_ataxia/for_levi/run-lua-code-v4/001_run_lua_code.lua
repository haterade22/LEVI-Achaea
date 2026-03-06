--[[mudlet
type: alias
name: run lua code
hierarchy:
- Levi_Ataxia
- Utility
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^lua (.*)$
command: ''
packageName: ''
]]--

local f, e = loadstring("return "..matches[2])
if not f then
  f, e = assert(loadstring(matches[2]))
end

local r =
  function(...)
    if not table.is_empty({...}) then
      display(...)
    end
  end
r(f())