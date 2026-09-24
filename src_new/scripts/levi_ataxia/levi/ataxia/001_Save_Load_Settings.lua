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

	-- Rotate backups: copy current disk file to .bak before overwriting
	local function rotateBackup(path)
		if io.exists(path) then
			local src = io.open(path, "r")
			if src then
				local data = src:read("*a")
				src:close()
				if data and #data > 10 then
					local dst = io.open(path .. ".bak", "w")
					if dst then dst:write(data); dst:close() end
				end
			end
		end
	end

	-- Strip live GUI objects (Geyser/Adjustable windows, labels, ...) from the data
	-- before serializing. Some live in the saved `ataxia` namespace
	-- (ataxia.mnemosyne.map.window, ataxia.data.hunter.window, vital bars, chat); they
	-- carry circular refs and, if reloaded, deserialize into methodless tables that
	-- crash Geyser (container:hide/show, label:hide). Detected reliably here because
	-- these are LIVE objects whose hide/show are functions.
	local function sanitizeForSave(v, seen)
		if type(v) ~= "table" then
			return (type(v) == "function") and nil or v
		end
		-- getmetatable/rawget ONLY -- never index v.hide/v.show: for a Mudlet `db`
		-- proxy stored under ataxia that fires __index -> "access sheet 'hide'".
		-- Live GUI/db/runtime objects carry metatables; methodless GUI snapshots are
		-- caught by their raw windowList/nestedLabels fields.
		if getmetatable(v) ~= nil
			or rawget(v, "windowList") ~= nil or rawget(v, "nestedLabels") ~= nil then
			return nil
		end
		seen = seen or {}
		if seen[v] then return nil end
		seen[v] = true
		local out = {}
		for k, val in pairs(v) do
			local tk = type(k)
			if tk == "string" or tk == "number" or tk == "boolean" then
				local cleaned = sanitizeForSave(val, seen)
				if cleaned ~= nil then out[k] = cleaned end
			end
		end
		return out
	end

	rotateBackup(file_loc)
	table.save(file_loc, sanitizeForSave(ataxia))

	if ataxiaBasher then
		rotateBackup(bash_loc)
		table.save(bash_loc, ataxiaBasher)
		if ataxiaBasherPaths then
			rotateBackup(paths_loc)
			table.save(paths_loc, ataxiaBasherPaths)
		end
	end

	if ataxiaNDB then
		rotateBackup(ndb_loc)
		table.save(ndb_loc, ataxiaNDB)
	end

  if ataxiaExtraction then
    rotateBackup(ext_loc)
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

  -- Save Item Catalog state
  if itemCatalog and itemCatalog.save then
    itemCatalog.save()
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

	-- Merge-load helper: loads saved data into target table without wiping
	-- existing keys. This preserves runtime functions and state that were
	-- set up by scripts before sysLoadEvent (e.g. ataxia.data.movement,
	-- ataxia.data.db.addChar). table.save can't serialize functions, so
	-- a plain table.load would replace sub-tables with function-less copies.
	-- Recursive merge: preserves functions at all nesting levels.
	-- table.save can't serialize functions or GUI objects, so we only
	-- recurse into sub-tables that ALREADY exist in the destination.
	-- Saved table values with no dst counterpart are skipped (stale
	-- serialized GUI objects like ataxia.data.hunter.window).
	local function mergeLoad(path, target)
		local loaded = {}
		table.load(path, loaded)
		-- A live Geyser/Adjustable GUI object (window, container, label, etc.) carries
		-- methods and a metatable; a serialized snapshot from table.save never does.
		-- GUI objects get serialized because some live in the saved `ataxia` namespace
		-- (e.g. ataxia.mnemosyne.map.window, ataxia.data.hunter.window). We must NOT
		-- merge a stale snapshot into the live object: recursing pollutes its internal
		-- state -- notably adding plain-table children to a container's windowList, so
		-- a later container:hide() (on gmcp.Room) crashes with "attempt to call method
		-- 'hide' (a nil value)". Leave any such live object entirely as-is.
		-- Detect via getmetatable ONLY -- never index t.hide/t.show. Live Geyser
		-- objects have metatables, and so do other runtime objects like Mudlet `db`
		-- proxies; indexing `.hide` on a db proxy fires its __index and errors with
		-- "access sheet 'hide' that does not exist". getmetatable has no side effects.
		local function isRuntimeObject(t)
			return getmetatable(t) ~= nil
		end
		-- A *serialized* Geyser snapshot (functions stripped by table.save, so
		-- isRuntimeObject can't catch it) restored into a fresh/empty key would
		-- become a methodless table that later crashes container:hide()/show() or
		-- label:move(). Recognise the GUI-internal fields Geyser objects carry.
		local function looksLikeSerializedGui(t)
			local ty = rawget(t, "type")
			return rawget(t, "windowList") ~= nil or rawget(t, "nestedLabels") ~= nil
				or rawget(t, "windowname") ~= nil
				or (type(ty) == "string" and (rawget(t, "container") ~= nil or rawget(t, "stylesheet") ~= nil))
		end
		-- Recursively drop serialized GUI snapshots from the loaded data BEFORE merging.
		-- Per-key checks in deepMerge miss GUI objects nested inside a subtree that gets
		-- assigned wholesale (e.g. ataxia.bars = { name = { window = <snapshot> } } when
		-- ataxia.bars doesn't exist yet). Stripping the whole loaded tree first guarantees
		-- no methodless GUI table is ever merged/assigned, at any depth.
		local function stripGui(t, seen)
			seen = seen or {}
			if seen[t] then return end
			seen[t] = true
			for k, v in pairs(t) do
				if type(v) == "table" then
					if looksLikeSerializedGui(v) then
						t[k] = nil
					else
						stripGui(v, seen)
					end
				end
			end
		end
		-- `seen` guards against cyclic/self-referential tables in the saved data
		-- (e.g. a stray back-reference stored into `ataxia`). Without it, a cycle
		-- makes deepMerge recurse forever -> stack overflow, which aborts the whole
		-- loader before the NDB/basher blocks and leaves ataxiaNDB nil.
		local function deepMerge(src, dst, seen)
			seen = seen or {}
			if seen[src] then return end
			seen[src] = true
			for k, v in pairs(src) do
				if type(v) == "table" then
					if type(dst[k]) == "table" then
						if not isRuntimeObject(dst[k]) then
							deepMerge(v, dst[k], seen)
						end
						-- else: keep the live GUI/runtime object untouched
					elseif dst[k] == nil and not looksLikeSerializedGui(v) then
						dst[k] = v  -- plain data with no runtime object to protect
					end
					-- skip if dst[k] is a non-table (function, userdata, etc.)
				else
					dst[k] = v
				end
			end
		end
		stripGui(loaded)
		deepMerge(loaded, target)
	end

	-- Try primary file, then .bak, then profile backup
	local function findFile(path)
		if io.exists(path) then return path end
		if io.exists(path .. ".bak") then
			ataxia_Echo("Primary save missing, using backup: " .. path .. ".bak")
			return path .. ".bak"
		end
		return nil
	end

	-- Isolate the main-settings load: a failure here (e.g. a stack overflow from a
	-- cyclic save merged by deepMerge) must NOT abort the whole loader, or every
	-- later block -- basher, paths, extraction, and critically the NDB block that
	-- assigns ataxiaNDB -- never runs. On failure we warn and fall through to the
	-- self-healing defaults below and the remaining sub-loads.
	local ok_main, err_main = pcall(function()
		local ataxia_file = findFile(file_loc)
		if not ataxia_file then
			if _ataxia_backup and _ataxia_backup.ataxia then
				ataxia_Echo("Disk save not found -- restoring from profile backup.")
				-- KNOWN DEFECT, FOUND 2026-09-09, DELIBERATELY NOT FIXED HERE.
				--
				-- This is a RAW WHOLESALE REPLACE, and it bypasses every protection `mergeLoad`
				-- has: the cycle-safe deepMerge, `stripGui`, and the live-runtime-object guard
				-- whose reasoning is spelled out at length directly above `mergeLoad`.
				--
				-- `sanitizeForSave` strips FUNCTIONS, so `_ataxia_backup.ataxia.<ns>` is a
				-- data-only snapshot. Assigning it over a live namespace therefore DELETES that
				-- namespace's functions: `ataxia.mnemosyne` (the whole run tracker, map, explorer
				-- and swarm API), `ataxia.armour`, `ataxia.updater`, `ataxia.bars`, `ataxia.defense`
				-- -- all replaced by their own saved data with no methods. It also re-introduces
				-- exactly the live-GUI-object corruption the comment above `mergeLoad` exists to
				-- prevent, since a serialized snapshot is written straight over the live object.
				--
				-- The fix is to give this branch the same merge semantics as the file branch
				-- (hoist deepMerge/stripGui out of `mergeLoad` and call them here). That changes
				-- how disaster recovery behaves for EVERY namespace under `ataxia`, so it wants
				-- its own change and its own testing rather than riding along with an unrelated
				-- one. Until then: a profile-backup restore is expected to need a reload.
				for k, v in pairs(_ataxia_backup.ataxia) do ataxia[k] = v end
			else
				ataxia_Echo("I don't believe I recognise you. If you want my abilities, fix that.")
			end
		else
			mergeLoad(ataxia_file, ataxia)
		end
	end)
	if not ok_main then
		ataxia_Echo("Warning: main settings failed to load ("..tostring(err_main).."). Continuing with defaults; other systems will still load.")
	end

	-- Self-healing: ensure critical settings sub-tables exist after load
	-- (protects against corrupted save files missing these keys)
	ataxia.settings = ataxia.settings or {}
	if not ataxia.settings.defences then
		ataxia.settings.defences = { current = "", defup = {}, keepup = {} }
	end
	ataxia.settings.have = ataxia.settings.have or {}
	ataxia.settings.use = ataxia.settings.use or {}
	ataxia.settings.sipping = ataxia.settings.sipping or {}
	ataxia.settings.precache = ataxia.settings.precache or {}
	ataxia.settings.highlighting = ataxia.settings.highlighting or {}
	ataxia.settings.prompt = ataxia.settings.prompt or {}
	ataxia.settings.raid = ataxia.settings.raid or {}
	ataxia.settings.fishing = ataxia.settings.fishing or {}
	ataxia.settings.weapons = ataxia.settings.weapons or {}
	ataxia.settings.user = ataxia.settings.user or {}
	ataxia.settings.reporting = ataxia.settings.reporting or { enabled = false, contemplate = true, url = "http://104.128.56.238:8000" }
	ataxia.curingprio = ataxia.curingprio or {}

  -- MNEMOSYNE RUN STATE IS TRANSIENT, BUT IT IS STORED UNDER `ataxia` (v4.7.299).
  -- `sanitizeForSave` keeps plain scalar tables, and `deepMerge` above ends in an unconditional
  -- `dst[k] = v`, so a previous session's `run.active` / `ripple` / `publicId` / `lastOffered`
  -- come back from disk and win. That is not only a telemetry concern: `run.boss` steers the
  -- Bard's dance choice and makes the legend deck withhold Xylthus, and `run.ripple` feeds the
  -- swarm's depth-scaled thresholds -- none of which is gated on reporting being enabled, while
  -- the only thing that CLEARS the state (`_resetRun`, via startRun/endRun) is.
  -- Placed after the whole main-load pcall so it covers the `_ataxia_backup` restore branch too,
  -- which copies the same keys in wholesale. Same shape as the Berserker's Edge revert below.
  if ataxia.mnemosyne and ataxia.mnemosyne._clearStaleRun then
    pcall(ataxia.mnemosyne._clearStaleRun)
  end
  -- ...AND ITS HTTP QUEUE CAME BACK TOO (v4.7.336). `ataxia.mnemosyne._busy`/`_queue` are merged
  -- back by the same deepMerge. A save that caught a POST in flight restored `_busy = true` with
  -- no request and no watchdog behind it, so `_pump` returned early forever and every report after
  -- it queued silently (711 of them, about nine runs, in the live save). `_resumeQueue` clears the
  -- flag and sends the restored requests in order. It has to run HERE, after the merge: the script
  -- body's own call ran first, on an empty queue. This is also the path an XML reimport takes on a
  -- fresh start (sysInstallPackage -> ataxia_updateApplied -> ataxia_loadSettings).
  if ataxia.mnemosyne and ataxia.mnemosyne._resumeQueue then
    pcall(ataxia.mnemosyne._resumeQueue, "restored from disk")
  end

	ataxia_Echo("I suppose I can lend you my aid. Go and annihilate our foes.")

	local ok_bash, err_bash = pcall(function()
	local bash_file = findFile(bash_loc)
	if not bash_file then
    if _ataxia_backup and _ataxia_backup.basher then
      ataxiaBasher = deepcopy(_ataxia_backup.basher)
      ataxia_Echo("Bashing systems restored from profile backup.")
    else
      ataxia_Echo("Bashing systems not yet enabled.")
    end
	else
		if ataxiaBasher then
			mergeLoad(bash_file, ataxiaBasher)
		else
			ataxiaBasher = {}
			table.load(bash_file, ataxiaBasher)
		end
		ataxia_Echo("Bashing systems enabled, go and lay waste.")
	end
	end)
	if not ok_bash then
		ataxia_Echo("Warning: bashing systems failed to load ("..tostring(err_bash)..").")
	end
  -- Initialize hyena maul cooldown for Infernal PVE (30s cooldown, starts ready)
  if ataxiaBasher and ataxiaBasher.hyenaMaulReady == nil then
    ataxiaBasher.hyenaMaulReady = true
  end
  -- Initialize falcon rake cooldown for Runewarden PVE (30s cooldown, starts ready)
  if ataxiaBasher and ataxiaBasher.falconRakeReady == nil then
    ataxiaBasher.falconRakeReady = true
  end

  -- BERSERKER'S EDGE DEFENSIVE REVERT, ON LOAD (review CRITICAL, 2026-09-03).
  -- `ataxiaBasher_berserkersEdgeApply/Revert` (basher/001) pin `ataxiaBasher.rageFloor` to 100
  -- for the boon's duration -- and that field, plus the two bookkeeping keys it saves the prior
  -- floor under, all live on `ataxiaBasher`, which is SERIALIZED wholesale. The only revert call
  -- sites were the confirmed Mnemosyne run-end and the wade-entry defensive reset in
  -- `mnemosyne/001_Run_Start.lua` -- neither of which fires on a plain disconnect/reconnect or a
  -- SYSUPDATE reload mid-run. A player holding the boon who drops connection before the run ends
  -- keeps rageFloor pinned at 100 on disk, silently starving every one of the 37 rotation
  -- affordability checks `ataxiaBasher_rageAfford` gates -- in and out of Mnemosyne, PvE or PvP --
  -- until the next wade's defensive reset or a manual `bash floor`. Reverting here is safe even
  -- for a run still genuinely in progress: it costs at most a few seconds at the pre-boon floor
  -- until the next wade re-applies it, against leaving a normal bashing session silently capped.
  if ataxiaBasher_berserkersEdgeRevert then
    pcall(ataxiaBasher_berserkersEdgeRevert)
  end

  if ataxiaBasher then
    local ok_paths, err_paths = pcall(function()
    local paths_file = findFile(paths_loc)
    if not paths_file then
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
      table.load(paths_file, ataxiaBasherPaths)
    end
    end)
    if not ok_paths then
      ataxia_Echo("Warning: bashing paths failed to load ("..tostring(err_paths)..").")
    end
  end

  local ok_ext, err_ext = pcall(function()
  local ext_file = findFile(ext_loc)
  if ext_file then
    ataxiaExtraction = {}
    table.load(ext_file, ataxiaExtraction)
    ataxiaEcho("Loaded extraction database.")
  elseif _ataxia_backup and _ataxia_backup.extraction then
    ataxiaExtraction = deepcopy(_ataxia_backup.extraction)
    ataxiaEcho("Extraction database restored from profile backup.")
  end
  end)
  if not ok_ext then
    ataxia_Echo("Warning: extraction database failed to load ("..tostring(err_ext)..").")
  end

	local ok_ndb, err_ndb = pcall(function()
		local ndb_file = findFile(ndb_loc)
		if not ndb_file then
			if _ataxia_backup and _ataxia_backup.ndb then
				ataxiaNDB = deepcopy(_ataxia_backup.ndb)
				ataxiaEcho("Name database restored from profile backup.")
			else
				ataxiaEcho("Name database not initialised. Loading default settings.")
				ataxiaNDB_Install()
			end
		else
			-- Load into a temp table first; only commit to ataxiaNDB once the load AND
			-- migration have succeeded. If table.load throws on a corrupt/locked file,
			-- ataxiaNDB is left untouched (nil) rather than a half-populated {} that a
			-- later save would write back over the still-good on-disk file.
			local loaded = {}
			table.load(ndb_file, loaded)
			-- Migrate array tables to hash tables (one-time)
			local function migrateArrayToHash(tbl)
				if not tbl or not tbl[1] then return tbl or {} end
				local hash = {}
				for _, v in ipairs(tbl) do hash[v] = true end
				return hash
			end
			loaded.notPlayers = migrateArrayToHash(loaded.notPlayers)
			loaded.divine = migrateArrayToHash(loaded.divine)
			ataxiaNDB = loaded
			ataxiaEcho("Name database loaded in.")
		end
	end)
	if not ok_ndb then
		-- Do NOT ataxiaNDB_Install() on a load throw: that calls ataxia_saveSettings()
		-- and would overwrite a present-but-unreadable `andb` with an empty DB,
		-- destroying the user's data. Prefer the in-memory profile backup; otherwise
		-- leave ataxiaNDB nil so the on-disk file survives for manual recovery.
		ataxiaEcho("Warning: name database failed to load ("..tostring(err_ndb)..").")
		if not ataxiaNDB and _ataxia_backup and _ataxia_backup.ndb then
			ataxiaNDB = deepcopy(_ataxia_backup.ndb)
			ataxiaEcho("Name database restored from profile backup instead.")
		end
	end

  -- Load Legend Deck Manager state
  if ldm and ldm.load then
    local ok_ldm, err_ldm = pcall(ldm.load)
    if not ok_ldm then
      ataxia_Echo("Warning: legend deck failed to load ("..tostring(err_ldm)..").")
    end
  end

  -- Load SLC config
  local ok_slc, err_slc = pcall(function()
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
  end)
  if not ok_slc then
    ataxia_Echo("Warning: SLC config failed to load ("..tostring(err_slc)..").")
  end

  -- Load Item Catalog state
  if itemCatalog and itemCatalog.load then
    local ok_cat, err_cat = pcall(itemCatalog.load)
    if not ok_cat then
      ataxia_Echo("Warning: item catalog failed to load ("..tostring(err_cat)..").")
    end
  end

  -- Mark fully loaded only after every subsystem above has been attempted, so an
  -- interrupted load is retried on the next sysLoadEvent instead of being
  -- permanently short-circuited by the `if ataxia.loaded then return` guard at the
  -- top of this function. (ataxiaNDB and the other globals are only assigned inside
  -- the pcall-isolated blocks above; committing this flag too early is what left
  -- ataxiaNDB nil, which is what made qwp wrongly report the NDB as not loaded.)
  ataxia.loaded = true

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
			-- Monk transmute (Kaido) is a gap-filler for when sip balance is DOWN: fire only at
			-- or below transmuteat% health, top back up to transmuteto%, never spending mana
			-- past the manause% floor. See ataxiaBasher_monkBashing2.
			transmuteat = 70,
			transmuteto = 99,
			usemoss = true,
		},
		--Precaching herbs.
		precache = {
		},
		-- PvE bashing curing profile (ataxia/008_Bash_Curing_Profile.lua). A server-side
		-- curingset holding the PvE priority table -- limbs first, mental spray parked --
		-- switched on "basher enabled" and back on "basher disabled". `installed` flips only
		-- after the one-time `aconfig bashcuring install` finishes writing the set.
		bashcuring = {
			enabled = true,
			installed = false,
			setname = "bash",
			restoreTo = "normal",
		},
		--Other stuff that doesn't fall into above categories.
		aeoncommandblock = true,
		-- Monk bashing: false = Shikudo staff combos / Tekura, true = mind crush + DRS.
		-- Must be a real boolean, never nil: ataxiaBasher_monkBashing2 branches on it.
		crushbash = false,
		gagclot = true,
    highlighting = {guards = true, sigils = true, totems = true, runes = true, bals = true, limbs = true},
		class = "Unknown",
		looting = true,
		paused = false,
		prompt = {timestamp = true, afflictions = true},
		separator = ";",
		resetonlogin = true,
		customprompt = "#grey@timestamp #white[#hcolour@health#white] #white[#mcolour@percentmana#white] #gold|@targetinfo#gold|[@affs] @paused",
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
	ataxia.bardStuff = {symphony = false, harmsList = {}, ariaBash = false, bashHarms = false, instrument = "lyre", bashTempo = "vivace", bashCompose = "paean prelude scherzo sonata maqam", bashPunctuate = false}
	ataxia.sylvanStuff = {propagateList = {arms = false, legs = false, head = false, body = false}}

	-- User-configurable weapons, mount, artefacts (populated via Setup Wizard)
	ataxia.settings.weapons = {}
	ataxia.settings.user = {
		mount = nil,
		artefacts = {
			pendant = nil,
			bracelet = nil,
			belt = nil,
			ring = nil,
			earrings = {},
		},
	}

	-- Mnemosyne Run Tracker reporting (token entered in-game via `mnem token`)
	ataxia.settings.reporting = {
		enabled = false,
		contemplate = true,
		token = nil,
		url = "http://104.128.56.238:8000",
	}

	--ataxia_resetPrios()
	ataxia_Echo("Default systems have been enabled. Enjoy.")
	ataxia_saveSettings(false)
end


registerAnonymousEventHandler("sysDisconnectionEvent", "ataxia_saveSettings", true)
registerAnonymousEventHandler("sysLoadEvent", "ataxia_loadSettings")

-- Guarantee ataxia.bardStuff exists with all fields at package load. Many scripts, triggers,
-- and aliases index ataxia.bardStuff.* directly (instrument, symphony, ariaBash, tunesmith,
-- bashTempo, bashCompose, bashPunctuate); if a save predates a field -- or the loader hasn't
-- populated it yet -- those would nil-error (e.g. Queue Scanning, bashpunctuate). This backfills
-- missing fields WITHOUT clobbering saved values, and runs before sysLoadEvent merges the save.
ataxia = ataxia or {}
ataxia.bardStuff = ataxia.bardStuff or {}
for k, v in pairs({
	symphony = false, harmsList = {}, ariaBash = false, bashHarms = false,
	instrument = "lyre", bashTempo = "vivace",
	bashCompose = "paean prelude scherzo sonata maqam", bashPunctuate = false,
	footworkFlourish = true,
}) do
	if ataxia.bardStuff[k] == nil then ataxia.bardStuff[k] = v end
end
-- FOOTWORK FLOURISH DEFAULTS ON (v4.7.312, user: "We should flourish from the front to get to the
-- back"). v4.7.311 shipped it opt-in and its backfill wrote `false` into every existing save, so
-- flipping the default above reaches nobody -- migrate ONCE behind a persisted marker, the same
-- shape as the tempo migration below; a later `bashflourish off` is respected thereafter.
if not ataxia.bardStuff.footworkFlourishDefaulted then
	ataxia.bardStuff.footworkFlourishDefaulted = true
	if ataxia.bardStuff.footworkFlourish == false then ataxia.bardStuff.footworkFlourish = true end
end
-- VIVACE REPLACES MODERATO AS THE DEFAULT (v4.7.311). The 2026-09-16 tempo analysis (see
-- .claude/classes/bard.md, "Tempo: the numbers") puts Vivace (1/6/5) first in every regime: 5 of
-- every 12 hits from the back against Moderato's 2 of 7, and with a flourish at each return to
-- front, 5 of every 6. Migrated ONCE behind a persisted marker (the `panicAt35` shape): the old
-- default is moved off, but a user who later types `bashtempo moderato` is not dragged back on
-- every load.
if not ataxia.bardStuff.tempoVivaceMigrated then
	ataxia.bardStuff.tempoVivaceMigrated = true
	if ataxia.bardStuff.bashTempo == "moderato" then ataxia.bardStuff.bashTempo = "vivace" end
end