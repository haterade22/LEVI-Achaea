--[[mudlet
type: alias
name: Bashing Type
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- Ataxia-DownloadThis
- Ataxia
- Shaman System
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^sp bash (jinx|swiftcurse|arius)$
command: ''
packageName: ''
]]--

shaman.spiritlore.bashType = matches[2]
cecho("We'll now bash using "..matches[2].." instead.")