--[[mudlet
type: alias
name: enemies
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
regex: ^enemy (.+)$
command: ''
packageName: ''
]]--

	for token in matches[2]:gmatch("%w+") do 
		sendAll("unenemy "..token, "enemy "..token)
	end