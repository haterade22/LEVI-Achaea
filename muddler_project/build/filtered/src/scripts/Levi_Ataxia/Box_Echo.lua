function ataxia_boxEcho(msg, color)
	deselect()
	local colTbl = {}
	if color then
		colTbl = string.split(color, ":")
		for k = 1,2 do
			if colTbl[k] == "" then
				colTbl[k] = nil
			end
		end
		if colTbl[2] then
			bg(colTbl[2])
		end
    end
	colTbl[1] = colTbl[1] or "red"
	fg(colTbl[1])
	local leng = ((2*string.len(msg)) + 11)
	local mes = string.upper(msg)
	echo("\n ")
	echo( string.rep("-", leng+2) )
	echo(" \n|     " .. mes .. " | " .. mes .. "     |\n ")
	echo( string.rep("-", leng+2) )
	echo(" \n")
	resetFormat()
end