if matches[2] == "yourself" then return false end

if matches[2] == target then
	tAffs.deaf = false
	if removeAffV3 then removeAffV3("deaf") end
end