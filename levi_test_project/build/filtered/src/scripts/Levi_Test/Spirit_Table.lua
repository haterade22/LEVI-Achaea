if shaman == nil then
	shaman = { settings = { precommune = "", postcommune = ""} }
end
--cmd_sep = ataxia.settings.separator or "::"
if shaman.spiritlore == nil then
	shaman.spiritlore = { 
		bindings = {}, 
		attunements = {}, 
		wanted_bindings = {}, 
		wanted_attunements = {}, 
		unwanted_bindings = {}, 
		unwanted_attunements = {}, 
		profiles = {},
		attunement_count = 0, 
		bind_count = 0,
		override_tether = false,
    bashType = "swiftcurse",
	}
	send("spirit bindings")
	shecho("Checking current spirit bindings.")
end