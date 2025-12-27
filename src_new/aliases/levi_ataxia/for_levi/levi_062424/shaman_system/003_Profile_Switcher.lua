--[[mudlet
type: alias
name: Profile Switcher
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
regex: ^sp\s+(\w+)\s?(.*)?$
command: ''
packageName: ''
]]--

if matches[2] ~= "create" and matches[2] ~= "bash" then
  if matches[2] == "list" then
  	shaman.listspiritprofiles()
  elseif matches[2] == "help" then
  	shaman.help()
  elseif matches[2] == "save" then
  	if matches[3] ~= nil then
  		shaman.savecurrentprofile(matches[3])
  	else
  		shecho("Usage: sp save <profile_name>")
  	end
  elseif matches[2] == "precommune" then
  	shaman.settings.precommune = matches[3]
  	shecho("Will run before commune: "..matches[3])
  elseif matches[2] == "postcommune" then
  	shaman.settings.postcommune = matches[3]
  	shecho("Will run after commune: "..matches[3])
  elseif matches[2] == "delete" then
  	shaman.deleteprofile(matches[3])
  else
  	shaman.loadspiritprofile(matches[2])
  end
end