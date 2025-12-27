--[[mudlet
type: alias
name: Low Hp Alert
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- Ataxia-DownloadThis
- Ataxia
- Installation / Configuration
- Toggles/Settings/Etc.
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^lowhp (\d+)$
command: ''
packageName: ''
]]--

--This is percentage, not total health.

local p = tonumber(matches[2])
if p > 100 then p = 100 end

ataxia.lowhpalert = p

ataxiaEcho("Low health alert will now play below "..p.."% health.")
ataxia_saveSettings(false)