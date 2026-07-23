--[[mudlet
type: alias
name: dmap
hierarchy:
- Dementia_Mapper
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^dmap(?:\s+(.*))?$
command: ''
packageName: ''
]]--

-- `dmap ...` control alias. Route `dmap attack <raw>` to setAttack with case preserved (the
-- command template needs its original case); everything else to the dispatcher.
local rest = matches[2] or ""
local atk = rest:match("^[Aa][Tt][Tt][Aa][Cc][Kk]%s+(.+)$")
if atk and dmap and dmap.setAttack then
  dmap.setAttack(atk)
elseif dmap and dmap.command then
  dmap.command(rest)
end
