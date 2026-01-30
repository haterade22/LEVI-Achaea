function ataxia_Vitals_Update()
	local stats = gmcp.Char.Vitals.charstats
	local stance = ""
	ataxiaTemp.class = ataxiaTemp.class or gmcp.Char.Status.class	
	if not gmcp.Char.Vitals.hp then return end 
	 ataxiaBasher_stormhammer()  
	if not ataxia.vitals or not ataxia.vitals.hp then
		ataxia.vitals = {
			hp = tonumber(gmcp.Char.Vitals.hp),
			maxhp = tonumber(gmcp.Char.Vitals.maxhp),
			mp = tonumber(gmcp.Char.Vitals.mp),
			maxmp = tonumber(gmcp.Char.Vitals.maxmp),
			ep = tonumber(gmcp.Char.Vitals.ep),
			maxep = tonumber(gmcp.Char.Vitals.maxep),
			wp = tonumber(gmcp.Char.Vitals.wp),
			maxwp = tonumber(gmcp.Char.Vitals.maxwp),
			xp = tonumber(gmcp.Char.Vitals.nl),
		}
	end
	ataxia.vitals.hpp = math.floor((ataxia.vitals.hp/ataxia.vitals.maxhp)*100)
	ataxia.vitals.mpp = math.floor((ataxia.vitals.mp/ataxia.vitals.maxmp)*100)
	ataxia.vitals.stance = false
	ataxia.vitals.class = 0
	
	for _,str in ipairs(stats) do
		local sep = str:find(": ")
		if sep then
			local key = str:sub(1, sep - 1)
			local val = str:sub(sep + 2)
			if key == "Form" then
				stance = val
				if not ataxia.vitals.form then
					ataxia.vitals.form = val
					ataxia.vitals.oldform = val
          shikudo_checkForms()
				else
					if stance ~= ataxia.vitals.form then
						ataxia.vitals.oldform = ataxia.vitals.form
						ataxia.vitals.form = stance
            shikudo_checkForms()
					end
				end
      elseif key == "Spec" then
        ataxia.vitals.knight = val
			elseif key == "Ferocity" or key == "Momentum" or key == "Spark" then
				ataxia.vitals.class = tonumber(val)
      elseif key == "Anathema" then
        ataxia.vitals.anathema = (val == "Yes")
      elseif key == "Kata" then
        ataxia.vitals.kata = tonumber(val)
			elseif key == "Stance" then
				ataxia.vitals.stance = val
      elseif key == "Voice" then
        ataxia.vitals.voice = val
			elseif key == "Morph" then
				ataxia.vitals.morph = val
      elseif key:lower() == "epitaph_length" then
        ataxia.vitals.epitaph = tonumber(val)
			elseif key == "Rage" then
				ataxia.vitals.rage = tonumber(val)
			elseif key == "Kai" or key == "Shin" then
				ataxia.vitals.class = tonumber( string.match(val, "%d+") )
			elseif key == "Wellspring" then
				ataxia.vitals.class = tonumber(string.match(val, "%d+"))
			end
		end
	end

	if ataxiaTemp.class ~= gmcp.Char.Status.class then
		systemDefup("none")
		ataxiaTemp.class = gmcp.Char.Status.class
		if ataxia_isClass("depthswalker") then
			ataxia_depthswalkerReset()
		end
    
    if ataxiaTemp.class:find("Dragon") or ataxiaTemp.class:find("Elemental") then
      mmp.settings:setOption("gallop", false)
    end
    
		load_Combat_Tables()
	end

	ataxia.vitals.oldhealth = ataxia.vitals.hp
	ataxia.vitals.hp = tonumber(gmcp.Char.Vitals.hp)
		if ataxia.vitals.hp < ataxia.vitals.oldhealth and ataxiaBasher.enabled and not denizenAttack then
			enableTrigger("Denizen Attack Find")
		end

	ataxia.vitals.bleed = tonumber(string.match(stats[1], "Bleed: (%d+)"))
	ataxia.vitals.maxhp = tonumber(gmcp.Char.Vitals.maxhp)
	ataxia.vitals.mp = tonumber(gmcp.Char.Vitals.mp)
	ataxia.vitals.maxmp = tonumber(gmcp.Char.Vitals.maxmp)
	ataxia.vitals.hpp = math.floor((ataxia.vitals.hp/ataxia.vitals.maxhp)*100)
		if ataxia.vitals.hpp > 100 then ataxia.vitals.hpp = 100 end
	ataxia.vitals.mpp = math.floor((ataxia.vitals.mp/ataxia.vitals.maxmp)*100)
		if ataxia.vitals.mpp > 100 then ataxia.vitals.mpp = 100 end
	ataxia.vitals.ep = tonumber(gmcp.Char.Vitals.ep)
	ataxia.vitals.maxep = tonumber(gmcp.Char.Vitals.maxep)
	ataxia.vitals.epp = math.floor((ataxia.vitals.ep/ataxia.vitals.maxep)*100)
	ataxia.vitals.wp = tonumber(gmcp.Char.Vitals.wp)
	ataxia.vitals.maxwp = tonumber(gmcp.Char.Vitals.maxwp)
	ataxia.vitals.wpp = math.floor((ataxia.vitals.wp/ataxia.vitals.maxwp)*100)	
	ataxia.vitals.bal = (gmcp.Char.Vitals.bal == "1" and true or false)
	ataxia.vitals.eq = (gmcp.Char.Vitals.eq == "1" and true or false)
	ataxia.vitals.xp = tonumber(gmcp.Char.Vitals.nl)

  if not ataxia.lowhpalert then ataxia.lowhpalert = 35 end
	if ataxia.vitals.hpp < ataxia.lowhpalert and ataxia.vitals.hpp ~= 0 then
		ataxiaBasher_alert("LowHealth")
	elseif ataxia.vitals.hp == 0 then
		if not ataxia_paused() then
			ataxiaToggle("off")
		end
	end


ataxiagui_updateVitals()
end
