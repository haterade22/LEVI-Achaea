-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Ataxia-DownloadThis > Ataxia > System-related > Curing Stuff > Priority-related > Default Curing Prios

function ataxia_resetOnLogin()
	local defaultPrios = ataxia_defaultCuringPrios()
	ataxia.curingprio = ataxia.curingprio or {}
	
--	for aff, val in pairs(defaultPrios) do
--		if ataxia.curingprio[aff] == nil or ataxia.curingprio[aff] ~= val then
--send("curing priority "..aff.." "..val)		end
--	end

send("curing priority parasite 7;curing priority hypersomnia 9;curing priority flushings 5;curing priority generosity 16;curing priority anorexia 4")
tempTimer(1.5, [[ send("curing priority transfixation 6;curing priority whisperingmadness 11;curing priority epilepsy 18;curing priority confusion 20;curing priority damagedleftleg 8") ]])
tempTimer(2.5, [[ send("curing priority vertigo 16;curing priority temperedmelancholic 14;curing priority recklessness 21;curing priority weariness 7;curing priority loneliness 16") ]])
tempTimer(3.5, [[ send("curing priority pyramides 6;curing priority pressure 17;curing priority impatience 6;curing priority paralysis 4;curing priority pacified 14") ]])
tempTimer(4.5, [[ send("curing priority serioustrauma 17;curing priority brokenrightleg 7;curing priority webbed 6;curing priority mangledrightarm 14;curing priority stuttering 19") ]])
tempTimer(5.5, [[ send("curing priority crackedribs 9;curing priority spiritburn 11;curing priority shadowmadness 6;curing priority unweavingbody 7;curing priority retribution 6") ]])
tempTimer(6.5, [[ send("curing priority guilt 8;curing priority haemophilia 11;curing priority horror 8;curing priority fear 20;curing priority sensitivity 7") ]])
tempTimer(7.5, [[ send("curing priority temperedsanguine 14;curing priority disrupted 9;curing priority prone 9;curing priority dissonance 14;curing priority timeloop 5") ]])
tempTimer(8.5, [[ send("curing priority voyria 9;curing priority sleeping 2;curing priority impaled 6;curing priority daeggerimpale 6;curing priority entangled 6") ]])
tempTimer(9.5, [[ send("curing priority addiction 11;curing priority frozen 15;curing priority bound 6;curing priority unweavingmind 8;curing priority slashedthroat 19") ]])
tempTimer(10.5, [[ send("curing priority wristfractures 11;curing priority concussion 12;curing priority sandfever 4;curing priority scalded 16;curing priority skullfractures 8") ]])
tempTimer(11.5, [[ send("curing priority tension 16;curing priority disloyalty 15;curing priority deadening 14;curing priority clumsiness 14;curing priority darkshade 9") ]])
tempTimer(12.5, [[ send("curing priority manaleech 13;curing priority hellsight 12;curing priority depression 6;curing priority lovers 14;curing priority slickness 2") ]])
tempTimer(13.5, [[ send("curing priority itching 5;curing priority peace 16;curing priority stupidity 18;curing priority mangledleftarm 14;curing priority healthleech 14") ]])
tempTimer(14.5, [[ send("curing priority aeon 1;curing priority agoraphobia 16;curing priority selarnia 20;curing priority laceratedthroat 19;curing priority burning 19") ]])
tempTimer(15.5, [[ send("curing priority deafness 26;curing priority dementia 17;curing priority paranoia 17;curing priority tenderskin 11;curing priority scytherus 3") ]])
tempTimer(16.5, [[ send("curing priority mangledleftleg 8;curing priority lethargy 11;curing priority shyness 23;curing priority shivering 15;curing priority damagedrightarm 13") ]])
tempTimer(17.5, [[ send("curing priority brokenleftarm 10;curing priority torntendons 10;curing priority damagedhead 12;curing priority damagedleftarm 11;curing priority brokenrightarm 10") ]])
tempTimer(18.5, [[ send("curing priority mangledhead 9;curing priority mangledrightleg 8;curing priority damagedrightleg 8;curing priority crushedthroat 5;curing priority rebbies 7") ]])
tempTimer(20.5, [[ send("curing priority temperedphlegmatic 14;curing priority hypothermia 1;curing priority masochism 21;curing priority blindness 26;curing priority mycalium 5") ]])
tempTimer(21.5, [[ send("curing priority mildtrauma 17;curing priority hypochondria 5;curing priority nausea 11;curing priority hallucinations 9;curing priority dizziness 23") ]])
tempTimer(22.5, [[ send("curing priority heartseed 3;curing priority temperedcholeric 14;curing priority claustrophobia 16;curing priority asthma 7;curing priority justice 16") ]])
tempTimer(23.5, [[ send("curing priority brokenleftleg 7") ]])
end

function ataxia_resetPrios()
	local defaultPrios = ataxia_defaultCuringPrios()
  
send("curing priority parasite 7;curing priority hypersomnia 9;curing priority flushings 5;curing priority generosity 16;curing priority anorexia 4")
tempTimer(1.5, [[ send("curing priority transfixation 6;curing priority whisperingmadness 11;curing priority epilepsy 18;curing priority confusion 20;curing priority damagedleftleg 8") ]])
tempTimer(2.5, [[ send("curing priority vertigo 16;curing priority temperedmelancholic 14;curing priority recklessness 21;curing priority weariness 7;curing priority loneliness 16") ]])
tempTimer(3.5, [[ send("curing priority pyramides 6;curing priority pressure 17;curing priority impatience 6;curing priority paralysis 4;curing priority pacified 14") ]])
tempTimer(4.5, [[ send("curing priority serioustrauma 17;curing priority brokenrightleg 7;curing priority webbed 6;curing priority mangledrightarm 14;curing priority stuttering 19") ]])
tempTimer(5.5, [[ send("curing priority crackedribs 9;curing priority spiritburn 11;curing priority shadowmadness 6;curing priority unweavingbody 7;curing priority retribution 6") ]])
tempTimer(6.5, [[ send("curing priority guilt 8;curing priority haemophilia 11;curing priority horror 10;curing priority fear 20;curing priority sensitivity 7") ]])
tempTimer(7.5, [[ send("curing priority temperedsanguine 14;curing priority disrupted 9;curing priority prone 9;curing priority dissonance 14;curing priority timeloop 5") ]])
tempTimer(8.5, [[ send("curing priority voyria 9;curing priority sleeping 2;curing priority impaled 6;curing priority daeggerimpale 6;curing priority entangled 6") ]])
tempTimer(9.5, [[ send("curing priority addiction 11;curing priority frozen 15;curing priority bound 6;curing priority unweavingmind 8;curing priority slashedthroat 19") ]])
tempTimer(10.5, [[ send("curing priority wristfractures 11;curing priority concussion 12;curing priority sandfever 4;curing priority scalded 16;curing priority skullfractures 8") ]])
tempTimer(11.5, [[ send("curing priority tension 16;curing priority disloyalty 15;curing priority deadening 14;curing priority clumsiness 14;curing priority darkshade 9") ]])
tempTimer(12.5, [[ send("curing priority manaleech 13;curing priority hellsight 12;curing priority depression 6;curing priority lovers 14;curing priority slickness 2") ]])
tempTimer(13.5, [[ send("curing priority itching 5;curing priority peace 16;curing priority stupidity 18;curing priority mangledleftarm 14;curing priority healthleech 14") ]])
tempTimer(14.5, [[ send("curing priority aeon 1;curing priority agoraphobia 16;curing priority selarnia 20;curing priority laceratedthroat 19;curing priority burning 19") ]])
tempTimer(15.5, [[ send("curing priority deafness 26;curing priority dementia 17;curing priority paranoia 17;curing priority tenderskin 11;curing priority scytherus 3") ]])
tempTimer(16.5, [[ send("curing priority mangledleftleg 8;curing priority lethargy 11;curing priority shyness 23;curing priority shivering 15;curing priority damagedrightarm 13") ]])
tempTimer(17.5, [[ send("curing priority brokenleftarm 10;curing priority torntendons 10;curing priority damagedhead 12;curing priority damagedleftarm 11;curing priority brokenrightarm 10") ]])
tempTimer(18.5, [[ send("curing priority mangledhead 9;curing priority mangledrightleg 8;curing priority damagedrightleg 8;curing priority crushedthroat 5;curing priority rebbies 7") ]])
tempTimer(20.5, [[ send("curing priority temperedphlegmatic 14;curing priority hypothermia 1;curing priority masochism 21;curing priority blindness 26;curing priority mycalium 5") ]])
tempTimer(21.5, [[ send("curing priority mildtrauma 17;curing priority hypochondria 5;curing priority nausea 11;curing priority hallucinations 9;curing priority dizziness 23") ]])
tempTimer(22.5, [[ send("curing priority heartseed 3;curing priority temperedcholeric 14;curing priority claustrophobia 16;curing priority asthma 7;curing priority justice 16") ]])
tempTimer(23.5, [[ send("curing priority brokenleftleg 7") ]])

--	for aff, val in pairs(defaultPrios) do
--send("curing priority "..aff.." "..val)	end
end

function ataxia_defaultCuringPrios()
  return {
    --Important afflictions here
    ["paralysis"] = 4,
    ["timeloop"] = 5,
    ["shadowmadness"] = 6,
    ["hypochondria"] = 5,
    ["depression"] = 6,
    ["retribution"] = 6,
    ["horror"] = 10,
    ["parasite"] = 7,
    ["scytherus"] = 3,
    ["impatience"] = 6,
    ["asthma"] = 7,
    ["sensitivity"] = 7,
    ["weariness"] = 7,
		["unweavingbody"] = 7,
		["unweavingmind"] = 8,
    ["guilt"] = 8,
    ["darkshade"] = 9,
    ["hypersomnia"] = 9,
    ["hallucinations"] = 9,
    --10 free for focus shifts; I swear I'll add this at some point.
    
    --Pariah specific afflictions
    ["sandfever"] = 4,
    ["mycalium"] = 5,
    ["flushings"] = 5,
    ["pyramides"] = 6,
    ["rebbies"] = 7,
		
    ["nausea"] = 11,
    ["haemophilia"] = 11,
    ["lethargy"] = 11,
    ["addiction"] = 11,
    ["tenderskin"] = 11,
    ["spiritburn"] = 11,
		
    --13 gap for other shifts.
    ["temperedmelancholic"] = 14,
    ["temperedcholeric"] = 14,
    ["temperedsanguine"] = 14,
    ["temperedphlegmatic"] = 14,
    ["lovers"] = 14, 
    ["pacified"] = 14, 
    ["healthleech"] = 14,
    ["clumsiness"] = 14,
    ["dissonance"] = 14,
    ["loneliness"] = 16,
    ["claustrophobia"] = 16,
    ["agoraphobia"] = 16,
    ["vertigo"] = 16,


    ["peace"] = 16, 
    ["justice"] = 16, 
    ["generosity"] = 16,

    ["dementia"] = 17,
    ["paranoia"] = 17,

    ["stupidity"] = 18, --move to 9 if off focus balance
    ["epilepsy"] = 18,
    ["confusion"] = 20, --move to 2 if disrupted, move to 8 if off focus balance
    ["recklessness"] = 21, --move up higher if off focus balance
    ["masochism"] = 21,

    ["dizziness"] = 23, --if off focus balance move this to 14? Seems too high honestly.
    ["shyness"] = 23, --if off focus balance move this to 14?
    
    ["blindness"] = 26,
    ["deafness"] = 26,

    --Salve afflictions
    ["heartseed"] = 3,
    ["hypothermia"] = 1,
    ["anorexia"] = 4,
    ["crushedthroat"] = 5,
    ["itching"] = 5,

    --6 GAP: For resto leg breaks and prone (will fix this too, at some point)

    ["brokenleftleg"] = 7,
    ["brokenrightleg"] = 7,

    ["damagedleftleg"] = 8, --move these up if prone so Sents can't screw me over.
    ["damagedrightleg"] = 8,
    ["mangledleftleg"] = 8,
    ["mangledrightleg"] = 8,

    ["mangledhead"] = 9,

    ["brokenleftarm"] = 10,
    ["brokenrightarm"] = 10,

    ["damagedleftarm"] = 11,

    ["damagedhead"] = 12,
    ["concussion"] = 12,

    ["damagedrightarm"] = 13,

    ["mangledleftarm"] = 14,
    ["mangledrightarm"] = 14,

    ["frozen"] = 15,
    ["shivering"] = 15, --same rank as frozen
    --CALORIC(insulation) at 15 unless it's a damn sentinel, then move up to 2 along with frozen and shivering
    ["scalded"] = 16,
    ["mildtrauma"] = 17,
    ["serioustrauma"] = 17,

    --MASS at 18

    ["burning"] = 19,
    ["stuttering"] = 19,
    ["slashedthroat"] = 19,
    ["laceratedthroat"] = 19,
    ["selarnia"] = 20,

    ---------------------------
    --PIPE
    ---------------------------
    ["aeon"] = 1,
    ["slickness"] = 2, --1 higher than para so that smoke > eat broot if para and slick.
    ["whisperingmadness"] = 11,
    ["hellsight"] = 12,

    ["manaleech"] = 13,
    ["deadening"] = 14,
    ["disloyalty"] = 15,
    ["tension"] = 16,
    ["pressure"] = 17,

    --["rebounding"] = 18, (DEFENCE QUEUE SLOT 18) IMPORTANT TO MOVE THIS DOWN BELOW PRESSURE

    ------------------------
    --HEALTH ELIXIR
    ------------------------
    ["skullfractures"] = 8,
    ["crackedribs"] = 9,
    ["torntendons"] = 10,
    ["wristfractures"] = 11,

    -------------------------
    --WRITHE
    -------------------------
    ["bound"] = 6,
    ["transfixation"] = 6,
    ["webbed"] = 6,
    ["entangled"] = 6,
    ["daeggerimpale"] = 6,
    ["impaled"] = 6,

    -----------------------
    --BAL FREE CURES
    -----------------------
    ["sleeping"] = 2,
    ["voyria"] = 9,
    ["prone"] = 9,
    ["disrupted"] = 9,
    ["fear"] = 20, --low for retardation/aeon curing

  }
end