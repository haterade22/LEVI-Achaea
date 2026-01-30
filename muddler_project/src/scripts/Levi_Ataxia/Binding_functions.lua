function shaman.checkSpirits(spiritlist)
  local binds = {
    "Daina", "Jhulian", "Arius", "Silvanix", "Ri\'shen", "Maligus", "Aspar", "Aelkesh", "Teraile",
    "Arcanor", "Syvis", "Marak", "Anthius", "Garon", "Tarnel", "Kosuira", "Arayan", "Adchachel", 
  }
cmd_sep = ataxia.settings.separator


  if type(spiritlist) == "string" then
    if not table.contains(binds, spiritlist:title()) then
      return false
    else
      return true
    end
  else
    local valid = true
    for _, bind in pairs(spiritlist) do
      if not table.contains(binds, bind:title()) then
        valid = false
      end
    end
    return valid
  end 
end

function shaman.loadspiritprofile(profile)
	shaman.resetwantedtables()
	
	return_status = shaman.loadprofilesettings(profile)
	if return_status ~= 1 then
		shecho("Profile '".. profile .. "' not found.")
		return 0
	end

	shaman.sortspirits()

	if shaman.spiritlore.profiles[profile]["tether"] ~= nil then
		shecho("Switching to profile <green>".. profile .."<reset>: <SkyBlue>".. table.concat(shaman.spiritlore.profiles[profile]["bindings"], "<reset>,<SkyBlue> ").. "<reset>  <firebrick>"..table.concat(shaman.spiritlore.profiles[profile]["attunements"], "<reset>,<firebrick> ").."<reset> ".. shaman.spiritlore.profiles[profile]["tether"]..".")
	else
		shecho("Switching to profile <green>".. profile .."<reset>: <SkyBlue>".. table.concat(shaman.spiritlore.profiles[profile]["bindings"], "<reset>,<SkyBlue> ").. "<reset>  <firebrick>"..table.concat(shaman.spiritlore.profiles[profile]["attunements"], "<reset>,<firebrick> ").. ".")
	end
	if not table.is_empty(shaman.spiritlore.wanted_bindings) then
		shaman.spiritlore.autobind = true
		shaman.commune()
	else
	-- we only need to worry about switching attunements and maybe tether
		shaman.tetherandattune()
	end

end

function shaman.spiritisbound(spirit)
	if table.contains(shaman.spiritlore.bindings, spirit:title()) or shaman.spiritlore.tether == spirit:title() then
		return true
	else
		return false
	end
end

function shaman.savecurrentprofile(profile_name)
		shaman.spiritlore.profiles[profile_name] = {
			["bindings"] = deepcopy(shaman.spiritlore.bindings),
			["attunements"] = deepcopy(shaman.spiritlore.attunements),
			["tether"] = shaman.spiritlore.tether
		}
		shecho("Saved spirit profile '<green>"..profile_name.."<reset>'.")
		shaman.save()
	return 1
end

function shaman.deleteprofile(profile_name)
	if table.contains(shaman.spiritlore.profiles, profile_name) then
		shaman.spiritlore.profiles[profile_name] = nil
		shecho("Profile '<green>"..profile_name.."<reset>' deleted.")
	else
		shecho("Profile not found.")
	end
end
function shaman.loadprofilesettings(profile_name)
	if table.contains(shaman.spiritlore.profiles, profile_name) then
		local profile_table = deepcopy(shaman.spiritlore.profiles[profile_name])
		shaman.spiritlore.wanted_bindings = profile_table.bindings
		shaman.spiritlore.wanted_attunements = profile_table.attunements
		shaman.spiritlore.wanted_tether = profile_table.tether
	else
		return 0
	end
	return 1
end

function shaman.resetspirittables()
	shaman.spiritlore.attunements = {}
	shaman.spiritlore.bindings = {}
	shaman.spiritlore.tether = nil

	shaman.resetwantedtables()
end

function shaman.resetwantedtables()
	shaman.spiritlore.wanted_attunements = {}
	shaman.spiritlore.unwanted_attunements = {}
	shaman.spiritlore.wanted_bindings = {}
	shaman.spiritlore.unwanted_bindings = {}
end

function shaman.tetherandattune()
		if shaman.spiritlore.wanted_tether ~= nil and ((shaman.spiritlore.wanted_tether ~= shaman.spiritlore.tether and shaman.spiritlore.override_tether) or shaman.spiritlore.tether == nil or shaman.spiritlore.tether == "") then
			shaman.tether(shaman.spiritlore.wanted_tether)
		end
	
		if not table.is_empty(shaman.spiritlore.unwanted_attunements) then
			shaman.unattunespirits()
		end
		if not table.is_empty(shaman.spiritlore.wanted_attunements) then
			
			shaman.attunespirits()
		end
end

function shaman.listspiritprofiles()
	cecho("\n<SeaGreen>(<white>Profile<SeaGreen>)"..string.rep(" ", 12).."<brown>(<white>Bindings<brown>)"..string.rep(" ", 25).."<orange>(<white>Attunes<orange>)"..string.rep(" ", 15).."<violet>(<white>Tether<violet>)\n")                  
	cecho("<DodgerBlue>"..string.rep("-", 90).."\n")
	table.sort(shaman.spiritlore.profiles)
	local bind, attune, tether = "", "", ""
	bind, attune = table.concat(shaman.spiritlore.bindings, ", "), table.concat(shaman.spiritlore.attunements, ", ")
	cecho("<firebrick>(Current): <NavajoWhite>[<DimGrey>"..bind.."<NavajoWhite>] "..string.rep(" ", 39-string.len(bind)).."<orange>[<DarkSlateGrey>"..attune.."<orange>]")
	cecho(string.rep(" ", 24-string.len(attune)).." <green>(<LightSkyBlue>"..(shaman.spiritlore.tether and shaman.spiritlore.tether or "None").."<green>)\n")
	cecho("<DodgerBlue>"..string.rep("-", 90).."\n")
	for profile_name, profile in spairs(shaman.spiritlore.profiles) do
		table.sort(profile.bindings)
		table.sort(profile.attunements)
		bind, attune = table.concat(profile.bindings, ", "), table.concat(profile.attunements, ", ")
		fg("green")
		echoLink("("..profile_name:title()..")", [[shaman.loadspiritprofile("]]..profile_name..[[")]], "Click to switch to this profile", true)
		resetFormat()
		cecho("<blue>:"..string.rep(" ", 8-string.len(profile_name)).."<sienna>["..bind.."] "..string.rep(" ", 39-string.len(bind)).."<DarkGoldenrod>["..attune.."]")
		if profile.tether ~= nil then
			cecho(string.rep(" ", 24-string.len(attune)).." <purple>(<NavajoWhite>"..profile.tether.."<purple>)\n")
		else
			cecho("\n")
		end
	end
	cecho("<DodgerBlue>"..string.rep("-", 90).."\n")
	send(" ")
end

function shaman.commune()
cmd_sep = ataxia.settings.separator



	if not shaman.spiritlore.commune then
		if svo ~= nil then
			svo.ignore.prone=true
		end
		send(shaman.settings.precommune..cmd_sep.."sit"..cmd_sep.."commune")
	end
end

function shaman.sortspirits()
	for i, binding in pairs(shaman.spiritlore.bindings) do
		if not table.contains(shaman.spiritlore.wanted_bindings, binding) then
			table.insert(shaman.spiritlore.unwanted_bindings, binding)
		elseif table.contains(shaman.spiritlore.wanted_bindings, binding) then
			table.remove(shaman.spiritlore.wanted_bindings, table.index_of(shaman.spiritlore.wanted_bindings, binding))
		end
	end 

	for i, spirit in pairs(shaman.spiritlore.attunements) do
		if not table.contains(shaman.spiritlore.wanted_attunements, spirit) then
			table.insert(shaman.spiritlore.unwanted_attunements, spirit)
		elseif table.contains(shaman.spiritlore.wanted_attunements, spirit) then
			local spirit_index = table.index_of(shaman.spiritlore.wanted_attunements, spirit)
			table.remove(shaman.spiritlore.wanted_attunements, spirit_index)
		end
	end

end

function shaman.unbindspirits()
	shecho("Unbinding <SkyBlue>"..table.concat(shaman.spiritlore.unwanted_bindings, "<reset>,<SkyBlue> ").."<reset>.")
	for i, binding in pairs(shaman.spiritlore.unwanted_bindings) do
		shaman.unbind(binding)
	end
end

function shaman.unattunespirits()
	shecho("Unattuning <firebrick>"..table.concat(shaman.spiritlore.unwanted_attunements, "<reset>,<firebrick> ").."<reset>.")
	for i, spirit in pairs(shaman.spiritlore.unwanted_attunements) do
		shaman.unattune(spirit)
	end
end

function shaman.bindspirits()
	shecho("Binding <SkyBlue>"..table.concat(shaman.spiritlore.wanted_bindings, "<reset>,<SkyBlue> ").."<reset>.")
	send("spirit bind "..table.concat(shaman.spiritlore.wanted_bindings, " "), false)
end
	
function shaman.unbind(spirit)
	send("spirit unbind ".. spirit, false)
end

function shaman.boundspirit(spirit)
	if table.contains(shaman.spiritlore.wanted_bindings, spirit) then
		table.remove(shaman.spiritlore.wanted_bindings, table.index_of(shaman.spiritlore.wanted_bindings, spirit))
	end
	if not table.contains(shaman.spiritlore.bindings, spirit) then
		table.insert(shaman.spiritlore.bindings, spirit)
	end

	if table.is_empty(shaman.spiritlore.wanted_bindings) and shaman.spiritlore.autobind then
		send("stand", false)
	end
end

function shaman.attunespirits()
	shecho("Attuning <firebrick>"..table.concat(shaman.spiritlore.wanted_attunements, "<reset>,<firebrick> ").."<reset>.")
	for i, spirit in pairs(shaman.spiritlore.wanted_attunements) do
		shaman.attune(spirit)
	end
end
	
function shaman.attune(spirit)
	send("spirit attune ".. spirit, false)
end

function shaman.unattune(spirit)
	send("spirit unattune ".. spirit, false)
end

function shaman.unboundspirit(spirit)
	if table.contains(shaman.spiritlore.unwanted_bindings,spirit) then
		local spirit_index = table.index_of(shaman.spiritlore.unwanted_bindings, spirit)
		table.remove(shaman.spiritlore.unwanted_bindings, spirit_index)
	end
	if table.contains(shaman.spiritlore.bindings,spirit) then
		local spirit_index = table.index_of(shaman.spiritlore.bindings, spirit)
		table.remove(shaman.spiritlore.bindings, spirit_index)
	end

	if table.contains(shaman.spiritlore.attunements, spirit) then
		local spirit_index = table.index_of(shaman.spiritlore.attunements, spirit)
		table.remove(shaman.spiritlore.attunements, spirit_index)
	end

	if table.contains(shaman.spiritlore.unwanted_attunements, spirit) then
		local spirit_index = table.index_of(shaman.spiritlore.unwanted_attunements, spirit)
		table.remove(shaman.spiritlore.unwanted_attunements, spirit_index)
	end
end

function shaman.unattunedspirit(spirit)
	if table.contains(shaman.spiritlore.unwanted_attunements, spirit) then
		local spirit_index = table.index_of(shaman.spiritlore.unwanted_attunements, spirit)
		table.remove(shaman.spiritlore.unwanted_attunements, spirit_index)
	end
	if table.contains(shaman.spiritlore.attunements,spirit) then
		local spirit_index = table.index_of(shaman.spiritlore.attunements, spirit)
		table.remove(shaman.spiritlore.attunements, spirit_index)
	end
end

function shaman.attunedspirit(spirit)
	if table.contains(shaman.spiritlore.wanted_attunements, spirit) then
		local spirit_index = table.index_of(shaman.spiritlore.wanted_attunements, spirit)
		table.remove(shaman.spiritlore.wanted_attunements, spirit_index)
	end
	if not table.contains(shaman.spiritlore.attunements, spirit) then
		table.insert(shaman.spiritlore.attunements, spirit)
	end
end

function shaman.tether(spirit)
	if shaman.spiritlore.tether ~= spirit then
		shecho("Tethering ".. spirit ..".")
		if shaman.spiritlore.tether ~= nil and shaman.spiritlore.tether ~= "" then
			send("spirit untether ".. shaman.spiritlore.tether, false)
		end
		send("spirit tether "..spirit, false)
	else
		shecho(spirit.." is already tethered.")
	end
end

function shaman.tethered(spirit)
	shaman.spiritlore.tether = spirit
end

function shaman.bindcount()
	local c = 0
	for i, spirit in pairs(shaman.spiritlore.bindings) do
		c = c + 1
	end
	return c
end