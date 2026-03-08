--[[mudlet
type: script
name: Save/Load Settings
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Ataxia
- System-related
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

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

  -- Save Legend Deck Manager state
  if ldm and ldm.save then
    ldm.save()
  end

  -- Save SLC config
  if selfLimbDamage and selfLimbDamage.config then
    local slc_loc = getMudletHomeDir() .. separator .. "slcconfig"
    table.save(slc_loc, selfLimbDamage.config)
  end

  -- Profile backup (persists via Mudlet saved variables)
  -- Re-read from just-saved files to get clean serialized data (avoids
  -- deepcopy stack overflow on tables with circular refs like GUI objects)
  _ataxia_backup = _ataxia_backup or {}
  _ataxia_backup.ataxia = {}
  table.load(file_loc, _ataxia_backup.ataxia)
  if ataxiaBasher then
    _ataxia_backup.basher = {}
    table.load(bash_loc, _ataxia_backup.basher)
  end
  if ataxiaBasherPaths then
    _ataxia_backup.basherpaths = {}
    table.load(paths_loc, _ataxia_backup.basherpaths)
  end
  if ataxiaNDB then
    _ataxia_backup.ndb = {}
    table.load(ndb_loc, _ataxia_backup.ndb)
  end
  if ataxiaExtraction then
    _ataxia_backup.extraction = {}
    table.load(ext_loc, _ataxia_backup.extraction)
  end
  if selfLimbDamage and selfLimbDamage.config then
    local slc_loc2 = getMudletHomeDir() .. separator .. "slcconfig"
    _ataxia_backup.slcconfig = {}
    table.load(slc_loc2, _ataxia_backup.slcconfig)
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
    -- Try profile backup before giving up
    if _ataxia_backup and _ataxia_backup.ataxia then
      ataxia_Echo("Disk save not found -- restoring from profile backup.")
      for k, v in pairs(_ataxia_backup.ataxia) do ataxia[k] = v end
    else
      ataxia_Echo("I don't believe I recognise you. If you want my abilities, fix that.")
      return
    end
	else
    table.load(file_loc, ataxia)
  end
	ataxia_Echo("I suppose I can lend you my aid. Go and annihilate our foes.")
	ataxia.loaded = true

	if not io.exists(bash_loc) then
    if _ataxia_backup and _ataxia_backup.basher then
      ataxiaBasher = deepcopy(_ataxia_backup.basher)
      ataxia_Echo("Bashing systems restored from profile backup.")
    else
      ataxia_Echo("Bashing systems not yet enabled.")
    end
	else
		ataxiaBasher = {}
		table.load(bash_loc, ataxiaBasher)
		ataxia_Echo("Bashing systems enabled, go and lay waste.")
	end
  -- Initialize hyena maul cooldown for Infernal PVE (30s cooldown, starts ready)
  if ataxiaBasher and ataxiaBasher.hyenaMaulReady == nil then
    ataxiaBasher.hyenaMaulReady = true
  end

  if ataxiaBasher then
    if not io.exists(paths_loc) then
      if _ataxia_backup and _ataxia_backup.basherpaths then
        ataxiaBasherPaths = deepcopy(_ataxia_backup.basherpaths)
        ataxia_Echo("Paths restored from profile backup.")
      else
        ataxiaBasherPaths = {}
        ataxia_Echo("Area paths not yet enabled. Will have to start those from scratch, I'm afraid.")
      end
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
  elseif _ataxia_backup and _ataxia_backup.extraction then
    ataxiaExtraction = deepcopy(_ataxia_backup.extraction)
    ataxiaEcho("Extraction database restored from profile backup.")
  end

	if not io.exists(ndb_loc) then
    if _ataxia_backup and _ataxia_backup.ndb then
      ataxiaNDB = deepcopy(_ataxia_backup.ndb)
      ataxiaEcho("Name database restored from profile backup.")
    else
      ataxiaEcho("Name database not initialised. Loading default settings.")
      ataxiaNDB_Install()
    end
	else
		ataxiaNDB = {}
		table.load(ndb_loc, ataxiaNDB)
		-- Migrate array tables to hash tables (one-time)
		local function migrateArrayToHash(tbl)
			if not tbl or not tbl[1] then return tbl or {} end
			local hash = {}
			for _, v in ipairs(tbl) do hash[v] = true end
			return hash
		end
		ataxiaNDB.notPlayers = migrateArrayToHash(ataxiaNDB.notPlayers)
		ataxiaNDB.divine = migrateArrayToHash(ataxiaNDB.divine)
		ataxiaEcho("Name database loaded in.")
	end

  -- Load Legend Deck Manager state
  if ldm and ldm.load then
    ldm.load()
  end

  -- Load SLC config
  local slc_loc = getMudletHomeDir() .. separator .. "slcconfig"
  if io.exists(slc_loc) then
    local saved = {}
    table.load(slc_loc, saved)
    selfLimbDamage = selfLimbDamage or {}
    selfLimbDamage.config = selfLimbDamage.config or {}
    for k, v in pairs(saved) do
      selfLimbDamage.config[k] = v
    end
  elseif _ataxia_backup and _ataxia_backup.slcconfig then
    selfLimbDamage = selfLimbDamage or {}
    selfLimbDamage.config = selfLimbDamage.config or {}
    for k, v in pairs(_ataxia_backup.slcconfig) do
      selfLimbDamage.config[k] = v
    end
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
    avoidType = "physical",  -- Options: physical, mental, arcane, aoe
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