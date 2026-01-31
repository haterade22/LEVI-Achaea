if ataxiaBasher.jabBash then
  ataxiaBasher.jabBash = false
  ataxiaEcho("Disable the use of jab while in dragonform.")
end

if not ataxiaBasher.wotBash then
	ataxiaBasher.wotBash = true
	ataxiaEcho("Will use whip of taming instead of gut while in dragonform.")
else
	ataxiaBasher.wotBash = false
	ataxiaEcho("Returning to gutting while in dragonform.")
end
ataxia_saveSettings(false)