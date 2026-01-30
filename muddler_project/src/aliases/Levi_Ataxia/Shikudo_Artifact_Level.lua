ataxiaEcho("Shikudo artifact level has been set to: <green>"..matches[2]..".")
ataxia.shikudoLevel = tonumber(matches[2])
ataxia_saveSettings(false)