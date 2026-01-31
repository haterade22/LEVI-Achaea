for i,v in ipairs(matches) do
	if selectString(matches[i], 1) ~= -1 then
		setLink([[openUrl("]]..matches[i]..[[")]], matches[i])
		setUnderline(true)
	end
end

deselect()
resetFormat()