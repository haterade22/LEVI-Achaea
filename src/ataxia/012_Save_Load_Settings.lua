-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Ataxia-DownloadThis > Ataxia > System-related > Save/Load Settings

function ataxia_saveSettings(disp)
	if not ataxia.settings then
		ataxia_Echo("System settings not found; won't save anything.") 
		return false 
	end

	local separator = string.char(getMudletHomeDir():byte()) == "/" and "/" or "\\"
	local file_loc = getMudletHomeDir() .. separator .. "ataxia"
	local bash_loc = getMudletHomeDir() .. separator .. "basher"
	local paths_loc = getMudletHomeDir()..separator.."basherpaths"
	local ndb_loc = getMudletHomeDir()..separator.."andb"
  local ext_loc = getMudletHomeDir()..separator.."extractLocations"

	table.save(file_loc, ataxia)

	if ataxiaBasher then
		table.save(bash_loc, ataxiaBasher)
		if ataxiaBasherPaths then table.save(paths_loc, ataxiaBasherPaths) end
	end

	if ataxiaNDB then
		table.save(ndb_loc, ataxiaNDB)
	end
  
  if ataxiaExtraction then
    table.save(ext_loc, ataxiaExtraction)
  end

	if disp then
		ataxia_Echo("Nap time. Don't come back soon, "..(gmcp and gmcp.Char.Name.name or "thanks")..".")
	end
end

function ataxia_loadSettings()
	if ataxia.loaded then
		ataxia_Echo("Systems have already been initiliased.") 
		return 
	end

	local separator = string.char(getMudletHomeDir():byte()) == "/" and "/" or "\\"
	local file_loc = getMudletHomeDir() .. separator .. "ataxia"
	local bash_loc = getMudletHomeDir() .. separator .. "basher"
	local paths_loc = getMudletHomeDir()..separator.."basherpaths"
	local ndb_loc = getMudletHomeDir()..separator.."andb"
  local ext_loc = getMudletHomeDir()..separator.."extractLocations"

	if not io.exists(file_loc) then 
		ataxia_Echo("I don't believe I recognise you. If you want my abilities, fix that.")
		return
	end

	table.load(file_loc, ataxia)
	ataxia_Echo("I suppose I can lend you my aid. Go and annihilate our foes.")
	ataxia.loaded = true

	if not io.exists(bash_loc) then
		ataxia_Echo("Bashing systems not yet enabled.") 
	else
		ataxiaBasher = {}
		table.load(bash_loc, ataxiaBasher)
		ataxia_Echo("Bashing systems enabled, go and lay waste.")
		if not io.exists(paths_loc) then
			ataxiaBasherPaths = {}
			ataxia_Echo("Area paths not yet enabled. Will have to start those from scratch, I'm afraid.")
		else
			ataxia_Echo("Paths have been acquired for bashing.")
			ataxiaBasherPaths = {}
			table.load(paths_loc, ataxiaBasherPaths)
		end
	end

  if io.exists(ext_loc) then
    ataxiaExtraction = {}
    table.load(ext_loc, ataxiaExtraction)
    ataxiaEcho("Loaded extraction database.")
  end

	if not io.exists(ndb_loc) then
		ataxiaEcho("Name database not initialised. Loading default settings.")
		ataxiaNDB_Install()
	else
		ataxiaNDB = {}
		table.load(ndb_loc, ataxiaNDB)
		ataxiaEcho("Name database loaded in.")
	end

  raiseEvent("ataxia system loaded")
	ataxia_saveSettings(false)
end

function ataxia_defaultSettings()
	ataxia.settings = {
		--Defence related.
		defences = {
			current = "",
			defup = {
			},
			keepup = {
			},
		},
		--Specific skills.
		have = {
			breathing = true,
			clot = true,
			deathsight = true,
			focus = true,
			insomnia = false,
			parry = true,
			rage = true,
			transmute = false,
		},
		--Use said skills.
		use = {
			breathing = true,
			clot = true,
			deathsight = true,
			focus = true,
			insomnia = false,
			parry = false,
			rage = false,
			transmute = false,
		},
		--For vitals-related things.
		sipping = {
			aeonmana = 40,
			aeonhealth = 40,
			manause = 30,
			mosshealth = 70,
			mossmana = 60,
			siphealth = 80,
			sipmana = 70,
			transmuteto = 70,
			usemoss = true,
		},
		--Precaching herbs.
		precache = {
		},
		--Other stuff that doesn't fall into above categories.
		aeoncommandblock = true,
		gagclot = true,
    highlighting = {},
		class = "Unknown",
		looting = true,
		paused = false,
		prompt = {timestamp = true, afflictions = true},
		separator = ";",
		resetonlogin = false,
		customprompt = "",
		roomshorten = "normal",
		autogallop = false,
    raid = {enabled = false},
    fishing = {
      bait = "shrimp",
      type = "normal",
      direction = "n",
      enabled = false,
      count = 0,
    }
	}
	ataxia.curingprio = {}
	ataxia.bardStuff = {symphony = false, harmsList = {}, ariaBash = false, bashHarms = false, instrument = "lyre"}
	ataxia.sylvanStuff = {propagateList = {arms = false, legs = false, head = false, body = false}}
	--ataxia_resetPrios()
	ataxia_Echo("Default systems have been enabled. Enjoy.")
	ataxia_saveSettings(false)
end


registerAnonymousEventHandler("sysDisconnectionEvent", "ataxia_saveSettings", true)
registerAnonymousEventHandler("sysLoadEvent", "ataxia_loadSettings")