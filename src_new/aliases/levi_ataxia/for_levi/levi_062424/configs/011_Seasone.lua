--[[mudlet
type: alias
name: Seasone
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- Ataxia-DownloadThis
- Ataxia
- Autobashing
- Configs
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^aconfig seasone$
command: ''
packageName: ''
]]--


if not ataxiaBasher.seasone then
	ataxiaBasher.seasone = true
	ataxiaEcho("Will use LDECK Seasone for 10 percent health elixir boost.")
else
	ataxiaBasher.seasone = false
	ataxiaEcho("Will NOT use LDECK Seasone for 10 percent health elixir boost.")
end
ataxia_saveSettings(false)



    