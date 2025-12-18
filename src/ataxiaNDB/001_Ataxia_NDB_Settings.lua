-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Ataxia-DownloadThis > Ataxia > Ataxia NDB > Ataxia NDB Settings

function ataxiaNDB_Install()
	--Will only probably be used on initial loading of system.
	ataxiaNDB = {}
	ataxiaNDB = {
		installed = true,
		players = {},
		highlightNames = true,
		highlighting = {
			Ashtan = "purple",
			Cyrene = "CornflowerBlue",
			Eleusis = "a_darkgreen",
			Hashan = "orange",
			Mhaldor = "a_darkred",
			Targossas = "a_darkcyan",
			Enemies = "red",
			Rogues = "a_brown",
      Underworld = "a_brown",
		},
		special = {},
    player_Notes = {},
		divine = {"Aegis", "Artemis", "Aurora", "Babel", "Deucalion", "Gaia", "Lorielan", "Lupus", "Neraeos",
			"Ourania", "Pandora", "Phaestus", "Prospero", "Sartan", "Scarlatti", "Twilight", "Valnurana",
			"Vastar", "Tlalaiad", "Romeo", "Juliet",},
		cityEnemies = {},
		highlightPriority = "city",
		enemySettings = {bold = false, italics = false, underline = false},
	}

	ataxiaEcho("Systems have been loaded and are ready to go.")
	ataxiaNDB_Unhighlight()
	ataxia_saveSettings(false)
	--Save on install, as a failsafe.
  
	local path = getMudletHomeDir().."/ataxiaNDB"
	if not lfs.attributes(path) then
		--We'll need a folder to store downloaded data. Don't worry, it won't cause issues.
		lfs.mkdir(path)
	end    
end