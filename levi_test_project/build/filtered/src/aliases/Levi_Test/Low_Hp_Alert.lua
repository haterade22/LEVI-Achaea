--This is percentage, not total health.

local p = tonumber(matches[2])
if p > 100 then p = 100 end

ataxia.lowhpalert = p

ataxiaEcho("Low health alert will now play below "..p.."% health.")
ataxia_saveSettings(false)