-- Successfully flayed fangbarrier - target no longer has coating
if isTargeted(matches[2]) then
	tAffs.fangbarrier = false
	tAffs.sileris = false
	tarAffed("slickness")
end
