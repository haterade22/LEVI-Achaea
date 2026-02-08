function ataxia_reportDefences()
	local x = ""
	local cur = ataxia.settings.defences.current
	local defs = gmcp.Char.Defences.List
	local defLine, ddx, total = 0, "", 0
	local defenceList = {
		system = {},
		other = {},
	}

	for _, def in pairs(defs) do
		x = find_defence(def.name)
		if ataxia.settings.defences.defup[cur][x] then
			table.insert(defenceList.system, x)
		else
			table.insert(defenceList.other, def.name)
		end
	end
	total = #defenceList.other
	table.sort(defenceList.system)

	echo("\n")
	ataxiaEcho(cur:title().." defences:")
	echo("\n")

	for _, def in pairs(defenceList.system) do
		defLine = defLine + 1
		ddx = "<a_darkcyan>[<green>x<a_darkcyan>] "
		total = total + 1
		if (defLine-1)%3 == 0 then
			echo("\n")
		end
		cecho(ddx)
		
		local dspace = def:title()
		if dspace:len() < 25 and (defLine-1)%3 ~= 2 then
			local padding = 25 - dspace:len()
			dspace = dspace..string.rep(" ", padding)
		elseif dspace:len() > 25 then
			dspace:cut(25)
		end
		
		cecho("<DarkSlateBlue>"..dspace)
	end

	for i,v in pairs(ataxia.settings.defences.defup[cur]) do
		if not table.contains(defenceList.system, i) then
			defLine = defLine + 1
			ddx = "<a_darkcyan>[<a_red>-<a_darkcyan>] "
			if (defLine-1)%3 == 0 then
				echo("\n")
			end
			cecho(ddx)

			local dspace = i:title()
			if dspace:len() < 25 and (defLine-1)%3 ~= 2 then
				local padding = 25 - dspace:len()
				dspace = dspace..string.rep(" ", padding)
			elseif dspace:len() > 25 then
				dspace:cut(25)
			end
			cecho("<DarkSlateBlue>"..dspace)
		end
	end

	echo("\n")
	ataxiaEcho("Other defences:")
	echo("\n")
	defLine = 0

	for _,v in pairs(defenceList.other) do
		defLine = defLine + 1
		ddx = "<a_darkcyan>[<NavajoWhite>x<a_darkcyan>] "

		if (defLine-1)%3 == 0 then
			echo("\n")
		end
		cecho(ddx)

		local dspace = v:title()
		if dspace:len() < 25 and (defLine-1)%3 ~= 2 then
			local padding = 25 - dspace:len()
			dspace = dspace..string.rep(" ", padding)
		elseif dspace:len() > 25 then
			dspace:cut(25)
		end

		cecho("<DarkSlateBlue>"..dspace)
	end
	echo("\n")
	ataxiaEcho(total.." total defences.")
	send(" ")
end