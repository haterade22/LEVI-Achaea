function populate_aff_colours()
	affs_to_colour = {
		--Ash Afflictions/DW/Misc
		depression = {"NavajoWhite", "dep"},
		hypersomnia = {"NavajoWhite", "hyp"},
		prone = {"NavajoWhite", "prone"},
		retribution = {"NavajoWhite", "ret"},
		shadowmadness = {"NavajoWhite", "shm"},
		sleeping = {"NavajoWhite", "sleep"},
		timeloop = {"NavajoWhite", "tlo"},
    crescendo = {"NavajoWhite", "cre"},

		--Bloodroot Afflictions
		paralysis = {"red", "PAR"},
		slickness = {"red", "SLI"},

		--Focusables
		agoraphobia = {"yellow", "ago"}, 
		anorexia = {"yellow", "ANO"}, 
		claustrophobia = {"yellow", "cla"}, 
		confusion = {"yellow", "con"}, 
		dementia = {"yellow", "dem"}, 
		dizziness = {"yellow", "diz"},
		epilepsy = {"yellow", "epi"},  
		hallucinations = {"yellow", "hal"}, 
		impatience = {"yellow", "IMP"},
		loneliness = {"yellow", "lon"}, 
		lovers = {"yellow", "lov"}, 
		masochism = {"yellow", "mas"}, 
		pacified = {"yellow", "pac"}, 
		paranoia = {"yellow", "par"}, 
		recklessness = {"yellow", "rec"}, 
		shyness = {"yellow", "shy"},
		stupidity = {"yellow", "stu"}, 
		stuttering = {"yellow", "stut"}, 
		vertigo = {"yellow", "ver"}, 

		--Kelp Afflictions
		asthma = {"purple", "AST"}, 
		clumsiness = {"purple", "clu"}, 
		healthleech = {"purple", "hleech"}, 
		hypochondria = {"purple", "hyp"}, 
		parasite = {"purple", "par"}, 
		sensitivity = {"purple", "sen"}, 
		weariness = {"purple", "WEA"},

		--Ginseng Afflictions
		addiction = {"green", "add"}, 
		darkshade = {"green", "dar"}, 
		haemophilia = {"green", "hae"}, 
		lethargy = {"green", "let"}, 
		nausea = {"green", "nau"}, 
		scytherus = {"green", "scy"},
    
    --Cuprum/Bellwort
    diminished = {"brown","dim"},
    generosity = {"brown","gen"},

		--Ashtan Afflictions
		weakenedmind = {"orange", "rixil"},
		slimeobscure = {"orange", "slime"},
    palpatarfeed = {"orange", "worms"},
    horror = {"magenta", "horror"},

		--Salve Afflictions
		burning = {"orange", "burns"},
		shivering = {"LightSkyBlue", "shiv"},
		frozen = {"blue", "frz"},
		hypothermia = {"red", "hypothermia"},

		crippledleftarm = {"DodgerBlue", "la1"},
		crippledrightarm = {"DodgerBlue", "ra1"},
		crippledleftleg = {"DodgerBlue", "ll1"},
		crippledrightleg = {"DodgerBlue", "rl1"},

		brokenleftarm = {"DodgerBlue", "la1"},
		brokenrightarm = {"DodgerBlue", "ra1"},
		brokenleftleg = {"DodgerBlue", "ll1"},
		brokenrightleg = {"DodgerBlue", "rl1"},

		damagedleftleg = {"DodgerBlue", "Ll2"},
		damagedleftarm = {"DodgerBlue", "La2"},
		damagedrightarm = {"DodgerBlue", "Ra2"},
		damagedrightleg = {"DodgerBlue", "Rl2"},

		mangledleftleg = {"DodgerBlue", "LL3"},
		mangledleftarm = {"DodgerBlue", "LA3"},
		mangledrightarm = {"DodgerBlue", "RA3"},
		mangledrightleg = {"DodgerBlue", "RL3"},

		mildtrauma = {"red", "TO1"},
		serioustrauma = {"firebrick", "TO2"},

		damagedhead = {"red", "H1"},
		concussion = {"firebrick", "H2"},

		--Smoke Afflictions
		aeon = {"DimGrey", "aeon"},
		deadening = {"DimGrey", "dead"},
		disloyalty = {"DimGrey", "dis"},
		hellsight = {"DimGrey", "hell"},
		manaleech = {"DimGrey", "mleech"},
		tension = {"DimGrey", "tens"},
		whisperingmadness = {"DimGrey", "whm"},
    earworm = {"DimGrey", "ear"},

		--Psion Afflictions
    lightbind = {"firebrick", "light"},
		unweavingbody = {"firebrick", "UWB"},
		unweavingmind = {"firebrick", "UWM"},
		unweavingspirit = {"firebrick", "UWS"},

		--Priest Afflictions
		guilt = {"LightSlateBlue", "GUI"},
		inquisition = {"a_darkred", "INQ"},
		spiritburn = {"LightSlateBlue", "SPB"},
		tenderskin = {"LightSlateBlue", "TSK"},
    
    --Pariah Afflictions
      --2 diff ones incase they fix the spellings
    ensorcelled = {"DarkSlateBlue", "ensc"},
    pyramides = {"DarkSlateBlue", "PYR"},
    rebbies = {"DarkSlateBlue", "REB"},
    flushings = {"DarkSlateBlue", "FLU"},
    mycalium = {"DarkSlateBlue", "MYC"},
    sandfever = {"DarkSlateBlue", "SDF"},
    deathsickness = {"white", "PLAGUE"},
    

		--Timed Affs
		airfisted = {"white", "afist"},
    unconsciousness = {"white", "UNC"},
		blackout = {"firebrick", "blackout"},
    blistered = {"tomato", "BLI"},
		calcifiedtorso = {"red", "CalTorso"},
    calcifiedskull = {"red", "CalSkull"},
		internalbleeding = {"a_darkred", "IMPSLASH"},
    numbedleftarm = {"magenta", "NLA"},
    numbedrightarm = {"magenta", "NRA"},
		scalded = {"tomato", "scald"},
		timeflux = {"tomato", "tflux"},
		vinewreathed = {"tomato", "vines"},
    
    incoming_impatience = {"a_brown", "inc_imp"},
    incoming_weariness = {"a_darkmagenta", "inc_wea"},
    incoming_clumsiness = {"a_darkmagenta", "inc_clu"},
    incoming_haemophilia = {"a_darkgreen", "inc_hae"},
    incoming_asthma = {"a_darkmagenta", "inc_ast"},
    incoming_paralysis = {"a_darkred", "inc_par"},
    incoming_epilepsy = {"a_brown", "inc_epi"},
    incoming_addiction = {"a_darkgreen", "inc_add"},

    --Writhe Affs
    transfixation = {"orange", "TFX"},
    impaled = {"magenta", "IMP"},
    bound = {"magenta", "BOU"},
    webbed = {"magenta", "WEB"},
    entangled = {"magenta", "ENT"},

		--Other Affs
		amnesia = {"violet", "amn"},
		fear = {"violet", "fear"},
		impaled = {"grey", "IMPALED"},
		revealed = {"gold", "STAR"},
		selarnia = {"tomato", "SEL"},
		webbed = {"grey", "web"},
		voyria = {"a_red", "VOY"},
		burns = {"orange", "BRN"},
		blackout = {"a_darkred", "BLK"},
		mindravaged = {"a_darkred", "RAVAGEDMIND"},
		bloodfire = {"a_darkred", "BLOODFIRE"},
	}
end