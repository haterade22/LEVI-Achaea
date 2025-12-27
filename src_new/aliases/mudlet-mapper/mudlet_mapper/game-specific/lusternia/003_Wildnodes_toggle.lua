--[[mudlet
type: alias
name: Wildnodes toggle
hierarchy:
- mudlet-mapper
- Mudlet Mapper
- Game-specific
- Lusternia
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: (?i)^nodes (on|off)$
command: ''
packageName: ''
]]--

if mmp.game ~= "lusternia" then return end
mmp.wildnodes(matches[2]:lower()=="on")
mmp.echo("All astral nodes have been "..(matches[2]:lower()=="on" and "" or "un").."linked.")