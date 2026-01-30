--former name: connect
--slc.push(matches[2], "drawslash")

--dbg(matches[1])
if SLC_blocked(matches[1]) == false then
	SLC_connects(slc_last_limb,"drawslash")
end