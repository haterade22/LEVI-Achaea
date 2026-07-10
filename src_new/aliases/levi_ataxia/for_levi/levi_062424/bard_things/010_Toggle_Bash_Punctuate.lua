--[[mudlet
type: alias
name: Toggle Bash Punctuate
hierarchy:
- Levi_Ataxia
- Ataxia
- Config
- Bard
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^bashpunctuate$
command: ''
packageName: ''
]]--

if not ataxia_isClass("bard") then
	ataxiaEcho("Class is not currently bard.")
	return
end

ataxia.bardStuff = ataxia.bardStuff or {}
ataxia.bardStuff.bashPunctuate = not ataxia.bardStuff.bashPunctuate
if ataxia.bardStuff.bashPunctuate then
	ataxiaEcho("Bash attack: <cyan>blade punctuate <target> paean<reset> (psychic-resistant mode ON).")
else
	ataxiaEcho("Bash attack: <cyan>blade flick <target><reset> (psychic-resistant mode OFF).")
end
ataxia_saveSettings(false)
