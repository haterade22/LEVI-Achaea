--[[mudlet
type: alias
name: Set Flee Threshold
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
regex: ^bash threshold (\d+)$
command: ''
packageName: ''
]]--

ataxiaBasher.fleeThreshold = tonumber(matches[2])
ataxiaEcho("Threshold for fleeing has been set to <a_green>"..ataxiaBasher.fleeThreshold.."hp. <NavajoWhite>We'll re-enter room while autobashing when above this amount.")