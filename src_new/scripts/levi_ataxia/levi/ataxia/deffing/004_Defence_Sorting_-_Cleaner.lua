--[[mudlet
type: script
name: Defence Sorting - Cleaner
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Ataxia
- System-related
- Deffing
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Ataxia-DownloadThis > Ataxia > System-related > Deffing > Defence Sorting - Cleaner

-- Returns false if defName belongs to a class-specific table that isn't the
-- player's current class. Universal categories (curatives, shared, tattoos,
-- endgame) and defenses not listed in any class table are always allowed.
function isDefenceForCurrentClass(defName)
  if not ataxiaTables.classDefences then sortedDefenceShow() end

  local myClass = (gmcp.Char.Status.class or ""):lower()
  local universal = { curatives = true, shared = true, tattoos = true, endgame = true }

  local foundInOtherClass = false
  for className, defTable in pairs(ataxiaTables.classDefences) do
    if defTable[defName] then
      if universal[className] or className == myClass then
        return true
      end
      foundInOtherClass = true
    end
  end
  if foundInOtherClass then return false end
  return true
end

function sortedDefenceShow()
   ataxiaTables.classDefences = {
   curatives = {
      airpocket = "airpocket",
      blindness = "blindness",
      caloric = "insulation",
      deafness = "deafness",
      deathsight = "deathsight",
			fangbarrier = "fangbarrier",
      frost = "temperance",
      insomnia = "insomnia",
      kola = "kola",
      levitation = "levitating",
      mass = "density",
      parrying = "parrying",
      rebounding = "rebounding",
      speed = "speed",
      shield = "shield",
      thirdeye = "thirdeye",
      venom = "poisonresist",
   },

		alchemist = {
			astronomy = "astronomy",
			mercury = "mercury",
			sulphur = "sulphur",
			tin = "tin",
      compoundmask = "compoundmask",
		},
	 
		apostate = {
			deathaura = "deathaura",
			demonarmour = "demonarmour",
			lifevision = "lifevision",
			putrefaction = "putrefaction",
			soulcage = "soulcage",	 
			truestare = "truestare",
			vengeance = "vengeance",
      shroud = "shroud",		
	 },
	   
   bard = {
      aria = "aria",
      lay = "lay",
      songbird = "songbird",
      tune = "blade tune",
			heartsfury = "heartsfury",
      acrobatics = "acrobatics on",
      harrying = "dance harrying",
   },

	blademaster = {
		consciousness = "consciousness",
		shinclarity = "shinclarity",
		shinbinding = "shinbinding",
		shintrance = "shintrance",
		retaliation = "retaliation",
		toughness = "toughness",
		mindnet = "mindnet",
		weathering = "weathering",
	},
	
	 depthswalker = {
			blur = "blur",
			bodyaugment = "bodyaugment",
			disperse = "disperse",
			durability = "durability",
			precision = "precision",
			shadowveil = "shadowveil",
      antiforce = "antiforce",
	 },
	 -- NOTE: the keys above are the GMCP/SSC defence names and must never be renamed --
	 -- `defadd`, `keepadd` and `curing priority defence <def> 25` all key off them. The
	 -- HUMAN-FACING label is separate: see ataxiaTables.defenceWords below.
	 
	 infernal = {
			deathaura = "deathaura",
			lifevision = "lifevision",
			putrefaction = "putrefaction",
			soulcage = "soulcage",	 
			vengeance = "vengeance",	
      blademastery = "blademastery",	 
	 },
	 
	 jester = {
			slippery = "slippery",
			balancing = "balancing",
			acrobatics = "acrobatics",	 
	 },
	 
   endgame = {
      cohesion = "cohesion",
      dragonbreath = "dragonbreath",
      dragonarmour = "dragonarmour",
			tempest = "tempest",
			susurrating = "susurrating",
      fireshroud = "fireshroud",
      extrusion = "extrusion",
      strata = "strata",      
   },
	 
   magi = {
      chargeshield = "chargeshield",
      diamondskin = "diamondskin",
      stoneskin = "stoneskin",
      simultaneity = "simultaneity",
   },
   
   monk = {
      boostedregeneration = "boosting",
      kaitrance = "kaitrance",
      hyperfocus = "hyperfocus",
      regeneration = "regeneration",
      shikudoform = "shikudoform",
      splitmind = "splitmind",
			mindnet = "mindnet",
      bodyblock = "bodyblock",
      evadeblock = "evadeblock",
      pinchblock = "pinchblock",
      hypersense = "hypersense",
      mindcloak = "mindcloak",
      toughness = "toughness",
      kaiboost = "kaiboost",
   },
   
   occultist = {
	 		arctar = "arctar",
      devilmark = "devilmark",
      tentacles = "tentacles",
			distortedaura = "distortedaura",
   },

    pariah = {
      shieldlogograph = "shieldlogograph",
      accursedresolve = "accursedresolve",
      leechlogograph = "leechlogograph",
  },

	priest = {
			willpowerblessing = "willpowerblessing",
			enduranceblessing = "enduranceblessing",
			thermalshield = "thermalshield",
			frostshield = "frostshield",
			earthshield = "earthshield",
	},

	 psion = {
	 		guidedstrike = "guidedstrike",
	 		psitranscend = "psitranscend",
	 		secondskin = "secondskin",
			rupturesight = "rupturesight",
      psicomprehend = "psicomprehend",
      psibreakthrough = "psibreakthrough",
	},	

	 sentinel = {
	 		affinity = "affinity",
			barkskin = "barkskin",
			firstaid = "firstaid",
			stealth = "stealth",
	 },	
   
   serpent = {
      ghost = "ghost",
      lipreading = "lipreading",
      pacing = "pacing",
      scales = "scales",
      shroud = "shroud",
      weaving = "weaving",
   },
   
   shaman = {
      swiftcurse = "swiftcurse",
   },
   
   sylvan = {
      spinningstaff = "spinningstaff",
      barkskin = "barkskin",
      viridian = "viridian",
   },
   
    unnamable = {
      bulk = "bulk",
      mouths = "mouths",
      joints = "joints",
      eyes = "eyes",
      unnamablepresence = "unnamablepresence",
      blademastery = "blademastery",
    },
   
   shared = {
      avoid = "avoid " .. (ataxia.settings.avoidType or "physical"),
      constitution = "constitution",
      consciousness = "consciousness",
			curseward = "curseward",
      gripping = "gripping",
      lifevision = "lifevision",
      nightsight = "nightsight",
      resistance = "resistance",
      weathering = "weathering",
      vitality = "vitality",
			hypersight = "hypersight",
			alertness = "alertness",
			vigilance = "vigilance",
			skywatch = "skywatch",
			treewatch = "treewatch",
			groundwatch = "groundwatch",			
			coldresist = "coldresist",
			electricresist = "electricresist",
			fireresist = "fireresist",
			magicresist = "magicresist",			
      selfishness = "selfishness",
      grookbubble = "grookbubble",
      heldbreath = "heldbreath",
      shroud = "shroud",
      lifevision = "lifevision",
      deflect = "deflect",
      blademastery = "blademastery",
      
   },
   tattoos = {
      boartattoo = "boartattoo",
      cloak = "cloak",
      megalithtattoo = "megalithtattoo",
      mindseye = "mindseye",
      moontattoo = "moontattoo",
      mosstattoo = "mosstattoo",
   }
	}
end
-- Human-facing labels for defences whose GMCP/SSC name says nothing about the command
-- that raises them (v4.7.144). The KEYS above are protocol names and can never change --
-- `defadd`, `keepadd` and `curing priority defence <def> 25` all key off them -- so this
-- is display only: `defs valid` renders "Precision (trusad)" for a Depthswalker.
--
-- Depthswalker is the motivating case: nothing about "precision" or "bodyaugment" tells
-- you to INTONE TRUSAD or INTONE MAINAAS. Mappings marked (?) are INFERRED from the AB
-- text, not yet confirmed against a live DEF -- correct them here if a def turns out to
-- belong to a different word.
ataxiaTables.defenceWords = {
  depthswalker = {
    precision   = "trusad",    -- AB: "Your precision is without compare" (crit vs denizens)
    durability  = "tsuura",    -- (?) AB: defence reducing damage from denizens
    bodyaugment = "mainaas",   -- AB: augment own skin vs cutting/blunt
    antiforce   = "gaiartha",  -- (?) AB: blocks the next forced action (Dominion tree)
    -- blur / disperse / shadowveil are Shadowmancy, not intoned words.
    disperse    = "shadow disperse",
    shadowveil  = "shadow veil",
  },
}

-- The command/word that raises `defName` for the current class, or nil.
function ataxia_defenceWord(defName)
  if not (gmcp.Char and gmcp.Char.Status and gmcp.Char.Status.class) then return nil end
  local byClass = ataxiaTables.defenceWords[gmcp.Char.Status.class:lower()]
  return byClass and byClass[defName] or nil
end
