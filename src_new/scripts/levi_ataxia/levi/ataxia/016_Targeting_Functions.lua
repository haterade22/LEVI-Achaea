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

-- Puts the target's cure balances back to "all up". Five sites replaced tBals by hand. The old
-- timers kept running, and their code writes to the global tBals, so the old target's 13 s tree
-- timer (trigger 389) marked the NEW target's tree up early and cleared its timer id. Two sites
-- also dropped salve and passive, so "not tBals.salve" read true. One helper, one shape.
function ataxia_resetTargetBals()
	if tBals and tBals.timers then
		for _, id in pairs(tBals.timers) do killTimer(id) end
	end
	tBals = {tree = true, focus = true, plant = true, salve = true, timers = {}, passive = true}
end

function switchTarget(who)
	local tName = who
	possible_targets = ataxiaTemp.enemies or {}

	local found_target = false
  if who ~= target and lb and lb.resetAll then lb.resetAll(target) end
  -- A round in the queue still names the old target (ataxia/003).
  if who ~= target and ataxia_roundTargetChanged then ataxia_roundTargetChanged() end
	if ataxia.playersHere and type(ataxia.playersHere) == "table" then
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

  -- Skip PvP combat state resets when bashing
  if not (ataxiaBasher and ataxiaBasher.enabled) then
    -- The new target's presence. The old target's chase stops here: while it ran, its 1.4 s
    -- TargetOutOfRoom ticks erased what we landed on the new target (paralysis first), then reset
    -- the tracker, the assumed rebounding with it. Nothing else sets targetIshere for a new target
    -- until one of its cure lines. Here if GMCP lists the name, case ignored, or a name it starts
    -- (`t sai` with Saibel listed). An absent target is re-armed by the next RemovePlayer,
    -- Room.Players or leave line.
    disableTimer("TargetOutOfRoom")
    targetIshere = false
    if type(target) == "string" and target ~= "" and type(ataxia.playersHere) == "table" then
      local want = target:lower()
      for _, v in pairs(ataxia.playersHere) do
        if type(v) == "string" and v:lower():sub(1, #want) == want then
          targetIshere = true
          break
        end
      end
    end
    resetStatesV3()
    setafflictionstackslevi()
    php = 100
    targetHealth = 100
    pm = 100
    tburns = 0
    tAffs.burns = 0
    if magi and magi.offense and magi.offense.state then magi.offense.state.burns = 0 end
    tarpreapply = false
    tAffs.rebounding = false
    tAffs.shield = false
    tAffs.curseward = false
    falconattack = false
    preventriftlock = false
    tdeliverance = false
    tBals.passive = true
    if pariah then pariah.state.burrow = false end
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
    ataxia_resetTargetBals()
    ataxiaTemp.bleeding = 0
    if lb and lb.resetAll then lb.resetAll(target) end
    readAuraAffs = { count = 0, list = {} }
    if ataxia_isClass("sentinel") then sAnimals = sAnimals or {} end
    if ataxia_isClass("serpent") then
      ataxiaTemp.suggestions = nil
      if serpent and serpent.state then
        serpent.state.dispelSent = false
        serpent.state.attackInFlight = false
        serpent.state.impatienceDelivered = false
        serpent.state.stupidityImpulseSent = false
        serpent.state.relapsePhase = false
        serpent.state.voyriaSent = false
        serpent.state.geckoStripAttempted = false
      end
      if serpent then
        serpent.impulseSuccess = false
        serpent.impulseRelapsing = false
      end
      if serpent and serpent.hypnosis and serpent.hypnosis.reset then
        serpent.hypnosis.reset()
      end
      if serpent and serpent.resetCureTracking then
        serpent.resetCureTracking()
      end
      hSuggActive = ""
    end
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
    disableTimer("Battlefury Perceive")
    raiseEvent("changed target")


    if zgui and zgui.showTarAffs then
      zgui.showTarAffs()
    end
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


-- True when GMCP lists exactly this name, case ignored: in ataxia.playersHere (update_stuff/001)
-- or in gmcp.Room.Players. 001 rebuilds the first from the second one name at a time and calls
-- isTargeted as it goes, so with Kaiden listed before Kai, Kai was not in the first yet and the
-- target Kai was renamed Kaiden. gmcp.Room.Players is not updated when someone enters or leaves,
-- so it can name a player who has gone. That name is still a full name, and this only stops a
-- completion.
local function listedHere(name)
  local want = name:lower()
  local list = ataxia and ataxia.playersHere
  if type(list) == "table" then
    for _, v in pairs(list) do
      if type(v) == "string" and v:lower() == want then return true end
    end
  end
  local room = type(gmcp) == "table" and gmcp.Room
  local players = type(room) == "table" and room.Players
  if type(players) == "table" then
    for _, p in pairs(players) do
      if type(p) == "table" and type(p.name) == "string" and p.name:lower() == want then return true end
    end
  end
  return false
end

-- The target name (lower case) a line has already named in full: an exact match, or a part name
-- completed. A full name is never completed again (see isTargeted).
local fullTargetName = nil

--type(target) == "number"
-- A line's name is our target when it is the target's name, case ignored. It is also our target
-- when the target is still a PART of a name (`t sai`) and the line's name starts with it: then
-- the name is completed (updateTarget). It was "either name starts the other", which renamed a
-- full-name target to a bystander: target Kaiden, and "Kai eats a magnesium chip." charged Kai's
-- eat to Kaiden and made Kai the target; target Kai, and Kaiden's lines did the same the other
-- way. So no completion once the target is a full name: one GMCP lists in the room, or one a line
-- has named or completed. A shorter name on a line is someone else (lines arrive whole since
-- v4.7.441, and their captures are whole names), so it never matches.
function isTargeted(who)
if not target then return false end
if type(target) ~= "number" then
  if type(who) ~= "string" then return false end
  local x,y = who:lower(), target:lower()
  if x == y then
    fullTargetName = y
    return true
  end
  if string.starts(x,y) and fullTargetName ~= y and not listedHere(target) then
    updateTarget(x)
    fullTargetName = x
    return true
  end
  return false
end

end

function updateTarget(name)
if type(target) ~= "number" then
  -- Trigger 265 records whose mount the flag is as `target` when its line printed
  -- (ataxiaTemp.mountedWho, v4.7.420), so after `t aga` it can hold part of a name. This is the
  -- same person's name, completed, so the owner is completed with it. TK6 matches the owner with
  -- either name starting the other (ownsMount, tekura6.isMounted), so a part left behind would
  -- also match the next target whose name starts the same way (Agatha after Agathon).
  local who = ataxiaTemp and ataxiaTemp.mountedWho
  if type(who) == "string" and type(target) == "string" and who:lower() == target:lower() then
    ataxiaTemp.mountedWho = name:title()
  end
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
-- Not assumed up (they were true). Only a coating line ever cleared the belief, and a target with
-- no coating prints none, so the Serpent believed a fangbarrier all fight and never impulsed. The
-- opening FLAY of the assumed rebounding strips a coating either way, and that strip prints a
-- line when there was one (kb/sim/rules.md attack.flay.coating 23 of 23, attack.flay.missing).
-- A coating we have not stripped is learned from its lines: the shell forming (442) or a bite it
-- stops (707).
sileris = false,
fangbarrier = false,
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
  if resetStatesV3 then resetStatesV3() end
  -- Reset kelp disambiguation on target change
  lastKelpAffs = nil
  lastKelp = nil
  if kelpDisambiguateTimer then killTimer(kelpDisambiguateTimer); kelpDisambiguateTimer = nil end

end