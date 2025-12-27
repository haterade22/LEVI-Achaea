--[[mudlet
type: alias
name: List continents
hierarchy:
- mudlet-mapper
- Mudlet Mapper
- mm Mapping
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^(?:acl|area continents)$
command: ''
packageName: ''
]]--

local continents = mmp.getcontinents()

if not next(continents) then mmp.echo("No continents known.")
else
  for continent, areadata in pairs(continents) do
    mmp.echo(continent.." continent:")

    for _, areaid in ipairs(areadata) do
      cecho("  "..getRoomAreaName(areaid).."\n")
    end
  end
end