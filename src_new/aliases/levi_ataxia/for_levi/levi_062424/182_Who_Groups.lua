--[[mudlet
type: alias
name: Who Groups
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- Ataxia-DownloadThis
- Ataxia
- Ataxia NDB
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^who groups$
command: ''
packageName: ''
]]--

whogroups = {}
enableTrigger("Who Grouping")
send("echo -Parsing Who List: "..ataxia.settings.separator.."who b",false)