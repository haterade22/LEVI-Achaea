if isTargeted(matches[2]) then
	tarAffed("fangbarrier")
	tarAffed("sileris")
  confirmAffV2("fangbarrier")
  confirmAffV2("sileris")
  if serpent and serpent.state then serpent.state.geckoStripAttempted = false end
end
