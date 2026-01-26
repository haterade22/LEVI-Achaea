--[[mudlet
type: script
name: Targeting Functions
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Ataxia
- Combat
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

function switchTarget(who)
	local tName = who
	possible_targets = ataxiaTemp.enemies

	local found_target = false
  if who ~= target then ataxia_resetLimbTable() end
	if ataxia.playersHere then
		for i,v in pairs(ataxia.playersHere) do
			if string.find(v, tName) then
				target = v
				found_target = true
				break
			end
		end				
	end

	for i,v in pairs(possible_targets) do
		if v == tName and not found_target then
			target = v
			found_target = true				
			break									
		end
	end

	if not found_target then						
		for i,v in pairs(possible_targets) do 	
			if string.find(v, tName) and not found_target then
				target = v
				found_target = true					
				break									
			end
		end
	end

	if not found_target then							
		target = tName
	end
	target = matches[2]
  if type(target) ~= "number" then
  target = matches[2]:lower():title()
  --target = matches[2]
  end
	ataxiaEcho("Target acquired. Focusing fire on <white>"..target.."!")
	send("unally "..target..ataxia.settings.separator.."enemy "..target..ataxia.settings.separator.."st "..target)
  send("settarget " ..target)
  --expandAlias("t " ..target)
  setafflictionstackslevi()
  php = 100
  pm = 100
  tburns = 0
  tAffs.burns = 0
  tarpreapply = false
  tAffs.rebounding = false
  tAffs.shield = false
  tAffs.curseward = false
  falconattack = false
  preventriftlock = false
  tdeliverance = false
  tBals.passive = true
  pariah.burrow = false
  taccelerates = 0
  tAffs.criticalspirit = false
  tAffs.criticalmind = false
  tAffs.criticalbody = false
  pdeconstruct = false
  mindinvert = false
  bodyinvert = false
  spiritinvert = false
  inverted = false
  lightbind = false
  
  
	if target_calling then send("pt Target: "..target) end

  targetresetafflictionslevi()
  -- Reset V3 affliction tracking on target change
  if affConfigV3 and affConfigV3.enabled and resetStatesV3 then
    resetStatesV3()
  end
  tBals = {tree = true, focus = true, plant = true, salve = true, timers = {}, passive = true}
	ataxiaTemp.bleeding = 0
	if ataxia_isClass("magi") then
		magi_resetLimbs()
	else
		tLimbs = {H=0, T=0, RL=0, LL=0, RA=0, LA=0}
	end
	readAuraAffs = { count = 0, list = {} }
	if ataxia_isClass("sentinel") then sAnimals = sAnimals or {} end
	if ataxia_isClass("serpent") then ataxiaTemp.suggestions = nil end
	if ataxia_isClass("priest") then ataxiaTemp.prayerList = nil end
  if ataxia_isClass("pariah") then
    ataxia_resetPariah() 
  end
  if string.find(ataxiaTemp.class, "fire") then ataxiaTemp.firelord = {} end
  twohanded_resetFractures()
  twohanded_resetFractures()
  
if gmcp.Char.Status.class == "Infernal" then
  send("order hyena passive")
end
if gmcp.Char.Status.class == "Runewarden" then
  send("order falcon passive")
end
  ataxiaTemp.lastLimbHit = "none"
  ataxiaTemp.parriedLimb = "none"
  affTimers = {}
	tLimbs.BP = tLimbs.BP or 100
  disableTimer("Battlefury Perceive") 
	raiseEvent("changed target")
  
  
  if zgui and zgui.showTarAffs then
    zgui.showTarAffs()
  end
end

function ataxia_needReject()
	if not ataxia.settings.lustlist then return false end
	if not ataxia.lustedto then return false end
	
	local need = false
	ataxia.reject = nil
	for i=1, #ataxia.lustedto do
		if not table.contains(ataxia.settings.lustlist, ataxia.lustedto[i]) then
			ataxiaTemp.reject = ataxia.lustedto[i]
			need = true
			break
		end
	end
	return need
end


--type(target) == "number"
function isTargeted(who)
if type(target) ~= "number" then
  local x,y = who:lower(), target:lower()
  if string.starts(x,y) or string.starts(y,x) or x == y then
    if x ~= y then
      updateTarget(x)
    end
    return true
  else
    return false
  end
end

end

function updateTarget(name)
if type(target) ~= "number" then
  target = name:title()
  ataxiaEcho("Updated target full name to: "..target..".")
  if tar_upper then killTrigger(tar_upper) end
  tar_upper = tempTrigger(target, [[ local c = 1
      while selectString("]] .. target .. [[",c) > -1 do
      fg("DarkOrchid")
      c = c + 1
    end
    resetFormat()
  ]])

  if tar_lower then killTrigger(tar_lower) end
  tar_lower = tempTrigger(target:lower(), [[ local c = 1
      while selectString("]] .. target:lower() .. [[",c) > -1 do
      fg("DarkOrchid")
      c = c + 1
    end
    resetFormat()
  ]])
end
end

function switchtargetnext()



	possible_targets = table.n_intersection(ataxiaTemp.enemies, ataxia.playersHere)
  possible_targets[1] = possible_targets[1] or target
	

	local found_target = false
	if ataxia.playersHere then
  if table.contains(ataxia.playersHere, target) then
  found_target = true

  end
  end

  if not found_target then
	if possible_targets then
  expandAlias("t "..possible_targets[1])
  found_target = true
    if partyrelay and not ataxia.afflictions.aeon then
      send("pt TARGET LEFT ROOM, now switching to "..target)
    end
  end
  end
  
	if not found_target then							
		target = target
	end
end

function switchtarget()

	possible_targets = table.n_intersection(ataxiaTemp.enemies, ataxia.playersHere)
  --possible_targets[1] = possible_targets[1] or target
	

	local found_target = false
	if ataxia.playersHere then
  send("ql")
  if table.contains(ataxia.playersHere, possible_targets[1]) then
  found_target = true

  end
  end

  if found_target then
	
  expandAlias("t "..possible_targets[1])
  found_target = true
      send("pt SWITCHING TARGET to "..target)
  end
  
  
	if not found_target then							
		target = target
	end
end

function targetresetafflictionslevi()
tAffs = {
blindness = true,
deafness = true,
shield = false,
rebounding = true,  -- Assume rebounding up, raze first to be safe
curseward = false,
addiction = false,
aeon = false,
agoraphobia = false,
airfisted = false,
amnesia = false,
anorexia = false,
asphyxiating = false,
asthma = false,
blackout = false,
blistered = false,
bloodfire = false,
bound = false,
brokenleftarm = false,
brokenleftleg = false,
brokenrightarm = false,
brokenrightleg = false,
bruisedribs = false,
burning = false,
cadmuscurse = false,
calcifiedskull = false,
calcifiedtorso = false,
claustrophobia = false,
clumsiness = false,
coldfate = false,
concussion = false,
condemned = false,
conflagration = false,
confusion = false,
constricted = false,
convergence = false,
corruption = false,
crackedribs = false,
cremated = false,
crescendo = false,
crushedthroat = false,
daeggerimpale = false,
damagedhead = false,
damagedleftarm = false,
damagedleftleg = false,
damagedrightarm = false,
damagedrightleg = false,
darkshade = false,
dazed = false,
dazzled = false,
deadening = false,
deathsickness = false,
deepsleep = false,
degenerate = false,
dehydrated = false,
dementia = false,
demonstain = false,
depression = false,
deteriorate = false,
diminished = false,
disloyalty = false,
disrupted = false,
dissonance = false,
dizziness = false,
earworm = false,
empoweredloshre = false,
empoweredmannaz = false,
enlightenment = false,
enmesh = false,
ensorcelled = false,
entangled = false,
epilepsy = false,
fear = false,
flamefisted = false,
flushings = false,
frostbite = false,
frozen = false,
fulminated = false,
generosity = false,
grievouswounds = false,
guilt = false,
haemophilia = false,
hallucinations = false,
hamstrung = false,
hatred = false,
healthleech = false,
heartseed = false,
hecatecurse = false,
hellsight = false,
hindered = false,
homunculusmercury = false,
horror = false,
hypersomnia = false,
hypochondria = false,
hypothermia = false,
icefisted = false,
impaled = false,
impatience = false,
indifference = false,
inquisition = false,
insomnia = false,
internalbleeding = false,
isolation = false,
itching = false,
justice = false,
kaisurge = false,
kkractlebrand = false,
laceratedthroat = false,
lapsingconsciousness = false,
latched = false,
lethargy = false,
lightbind = false,
loneliness = false,
lovers = false,
manaleech = false,
mangledhead = false,
mangledleftarm = false,
mangledleftleg = false,
mangledrightarm = false,
mangledrightleg = false,
masochism = false,
mildtrauma = false,
mindclamp = false,
mindravaged = false,
muddled = false, 
mycalium = false, 
nausea = false, 
numbedleftarm = false, 
numbedrightarm = false, 
pacified = false,
palpatarfeed = false, 
paralysis = false, 
paranoia = false,
parasite = false,
peace = false,
penitence = false,
petrified = false,
phlogisticated = false,
pinshot = false,
pressure = false,
prone = false,
pyramides = false,
pyre = false,
rebbies = false,
recklessness = false,
retribution = false,
revealed = false,
sandfever = false,
scalded = false,
scrambledbrains = false,
scytherus = false,
selarnia = false,
sensitivity = false,
serioustrauma = false,
shadowmadness = false,
shivering = false,
shyness = false,
silenced = false,
silver = false,
skullfractures = false,
slashedthroat = false,
sleeping = false,
slickness = false,
sileris = true,
fangbarrier = true,
slimeobscure = false,
snared = false,
solarburn = false,
spiritburn = false,
stridulating = false,
stupidity = false,
stuttering = false,
temperedcholeric = false, 
temperedmelancholic = false, 
temperedphlegmatic = false, 
temperedsanguine = false, 
tenderskin = false, 
tension = false, 
timeflux = false, 
timeloop = false, 
tonguetied = false, 
torntendons = false, 
transfixation = false, 
trueblind = false, 
unconsciousness = false, 
unweavingbody = false, 
unweavingmind = false, 
unweavingspirit = false, 
vertigo = false, 
vinewreathed = false,
vitiated = false, 
vitrified = false, 
voidfisted = false, 
voyria = false, 
waterbonds = false, 
weakenedmind = false, 
weariness = false, 
webbed = false,
whisperingmadness = false, 
wristfractures = false,
}
  -- Reset kelp disambiguation on target change
  lastKelpAffs = nil
  lastKelp = nil
  if kelpDisambiguateTimer then killTimer(kelpDisambiguateTimer); kelpDisambiguateTimer = nil end

  -- V2 Affliction Tracking reset
  if ataxia and ataxia.settings and ataxia.settings.useAffTrackingV2 then
    if resetAffsV2 then
      resetAffsV2()
    else
      tAffsV2 = {}
      affTimersV2 = {}
    end
    -- Assume rebounding up on new target (raze first to be safe)
    tAffsV2 = tAffsV2 or {}
    tAffsV2.rebounding = 2  -- Confirmed rebounding
    randomCuresV2 = 0
    -- Reset V2 herb disambiguation
    if pendingKelpAffsV2 then pendingKelpAffsV2 = nil end
    if kelpDisambiguateTimerV2 then killTimer(kelpDisambiguateTimerV2); kelpDisambiguateTimerV2 = nil end
    if lastGuessV2 then lastGuessV2 = nil end
    -- Update V2 display
    if updateAffDisplayV2 then updateAffDisplayV2() end
  end
end