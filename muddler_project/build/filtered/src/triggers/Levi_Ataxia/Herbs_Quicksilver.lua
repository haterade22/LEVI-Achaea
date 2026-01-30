if isTargeted(matches[2]) then
	tdeliverance = false
	erAff("slickness")
	erAff("paralysis")
	-- Note: fangbarrier comes ~10 seconds later with "metallic shell" message
	-- Don't set sileris=true here or we'll keep trying to flay non-existent coating
	targetIshere = true
end