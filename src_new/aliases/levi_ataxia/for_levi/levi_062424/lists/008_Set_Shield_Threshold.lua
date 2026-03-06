--[[mudlet
type: alias
name: Set Shield Threshold
hierarchy:
- Levi_Ataxia
- Ataxia
- Basher
- Lists
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^bash shield (\d+)$
command: ''
packageName: ''
]]--

ataxiaBasher.noShieldBreak.threshold = tonumber(matches[2])
ataxiaEcho("Shielding threshold has been set to <green>"..ataxiaBasher.noShieldBreak.threshold.."hp.")