-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Levi  Scripts > ZulahGUI - Saonji Edit > zGUI Redux > Defences > showDefs

function zgui.showDefs()
  if zgui.defence then
  ----------------------------------------
  -- Player Defences		
	clearWindow("defenceDisplay")
	if table.size(gmcp_defs) > 0 then
		--for i=1, table.size(gmcp_defs), 1 do
		--	cecho("defenceDisplay", "<green> - <grey>"..gmcp_defs[i].."\n")
		--end  
  
		local missingDefs = false
		for i=1, table.size(zgui.defs.classless.combat), 1 do
			if not table.contains(gmcp_defs, zgui.defs.classless.combat[i]) then
				setBackgroundColor("defenceDisplay",40,10,10,255)	
				missingDefs = true
				cecho("defenceDisplay", "<red>Missing:\n")
				break
			end
		end

		if not missingDefs then
			if zgui.defs.class[gmcp.Char.Status.class] then
			for i=1, table.size(zgui.defs.class[gmcp.Char.Status.class]), 1 do
				if not table.contains(gmcp_defs, zgui.defs.class[gmcp.Char.Status.class][i]) then
					setBackgroundColor("defenceDisplay",40,10,10,255)	
					missingDefs = true
					cecho("defenceDisplay", "<red>Missing:\n")
					break
				end
			end		
			end
		end
		
		if not missingDefs then
			setBackgroundColor("defenceDisplay", 0, 0, 0,255)	
		end	
		
		if zgui.defs.class[gmcp.Char.Status.class] then	
		for i=1, table.size(zgui.defs.class[gmcp.Char.Status.class]), 1 do
			if not table.contains(gmcp_defs, zgui.defs.class[gmcp.Char.Status.class][i]) then
				cecho("defenceDisplay", "<red> - <red>"..zgui.defs.class[gmcp.Char.Status.class][i].."\n")
			end		
		end
		end
			
		for i=1, table.size(zgui.defs.classless.combat), 1 do
			if not table.contains(gmcp_defs, zgui.defs.classless.combat[i]) then
				cecho("defenceDisplay", "<red> - <red>"..zgui.defs.classless.combat[i].."\n")
			end
		end

	end	

	if table.contains(gmcp_defs, "prismatic") then
		setBackgroundColor("defenceDisplay",10,40,20,255)
	end
  end
end