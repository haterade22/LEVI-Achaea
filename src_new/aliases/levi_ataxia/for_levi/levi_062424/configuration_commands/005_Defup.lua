--[[mudlet
type: alias
name: Defup
hierarchy:
- Levi_Ataxia
- Ataxia
- Defence Config
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^defup (\w+)$
command: ''
packageName: ''
]]--

systemDefup(matches[2])
if matches[2] == "apo" then 
send("curing priority defense truestare 1;curing priority defense mindseye 2") end