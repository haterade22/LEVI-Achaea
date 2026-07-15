--[[mudlet
type: script
name: Class Bashing
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Basher
- Bashing
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

--[[mudlet
type: script
name: Class Bashing
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Basher
- Bashing
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

function ataxiaBasher_dragonBashing()
  local command, sp = "", ataxia.settings.separator
  local brage = ataxiaBasher_assembleBattlerage()
  local colour = string.match(gmcp.Char.Status.class, "%w+")
  local raze = ataxiaBasher.battlerage[colour.." Dragon"].raze
  -- Breath element is derived from the dragon's colour (Blue = ice, Silver = lightning,
  -- Red = dragonfire, Green = venom, Black = acid, Golden = psi). No hardcoded default.
  local ele = getDragonBreath()

  -- The bal primary only (no breath weave): jab / whip / incantation / gut
  local function balAttack()
    if ataxiaBasher.jabBash then
      return "jab " ..target
    elseif ataxiaBasher.wotBash then
      return "whip " ..target
    elseif ataxiaBasher.dragonIncant then
      return "incantation " ..target
    else
      return "gut " ..target
    end
  end

  -- Normal-rotation primary. When the blast weave is enabled (bash blast on) and we're using a
  -- real primary (incantation/gut, not the low-wp jab or wotBash whip), fold in a breath blast:
  --   breath up   -> blast (eq, damage + breaks shields/lyres) ; re-summon ; bal attack
  --   breath down -> summon so it's ready next hit ; bal attack
  local function primary()
    local weaveable = not ataxiaBasher.jabBash and not ataxiaBasher.wotBash
    if ataxiaBasher.dragonBlast and weaveable and ele then
      if ataxia.defences.dragonbreath then
        return "blast " ..target.. ";summon " ..ele.. ";" ..balAttack()
      else
        return "summon " ..ele.. ";" ..balAttack()
      end
    end
    return balAttack()
  end

  if ataxiaBasher.shielded then
    if ataxiaBasher.rageraze and ataxia.vitals.rage >= 17 then
      command = command..raze..sp..primary()
    else
      -- Shield MUST be broken: blast unconditionally, re-summon the colour's breath, add bal damage.
      local reblast = ele and ("blast " ..target.. ";summon " ..ele.. ";") or ("blast " ..target.. ";")
      command = command..sp..reblast..balAttack()..sp..brage
    end
  else
    command = command..sp..brage..sp..primary()
  end
  return command
end

function ataxiaBasher_fEleBashing()
	local command, sp = "", ataxia.settings.separator
	local brage = ataxiaBasher_assembleBattlerage()
	local raze = ataxiaBasher.battlerage["Fire Elemental"].raze
	
	if ataxiaBasher.shielded then
		if ataxiaBasher.rageraze and ataxia.vitals.rage >= 17 then
			command = command..raze..sp.."ignite flamewhip "..target
		else
			command = command..sp.."manifest superheat "..target..sp..brage
		end
	else
		command = command..brage..sp.."ignite flamewhip "..target	
	end
	return command  

end

function ataxiaBasher_eEleBashing()
	local command, sp = "", ataxia.settings.separator
	local brage = ataxiaBasher_assembleBattlerage()
	local raze = ataxiaBasher.battlerage["Earth Elemental"].raze
	
	if ataxiaBasher.shielded then
		if ataxiaBasher.rageraze and ataxia.vitals.rage >= 17 then
			command = command..raze..sp.."terran pulverise "..target
		else
			command = command..sp.."terran crunch "..target..sp..brage
		end
	else
		command = command..brage..sp.."terran pulverise "..target	
	end
	return command  

end


function ataxiaBasher_aEleBashing()
   local command = ""   
   if ataxiaBasher.shielded then
      command = command.."manifest gale "..target..ataxia.settings.separator
   end
   
   command = command..ataxiaBasher_assembleBattlerage()
   
   if not ataxiaBasher.shielded then   
      command = command.."manifest buffet "..target
   end
   
   return command   
end

function ataxiaBasher_alchemistBashing()
	local command, sp = "", ataxia.settings.separator
	local brage = ataxiaBasher_assembleBattlerage()
	local raze = ataxiaBasher.battlerage.Alchemist.raze
	
	if ataxiaBasher.shielded then
		if ataxiaBasher.rageraze and ataxia.vitals.rage >= 17 then
			command = raze..sp.."educe iron "..target
		else
			command = "educe copper "..target..sp..brage
		end
	else
		command = brage..sp.."educe iron "..target
	end
	    
	return command  
end

function ataxiaBasher_apostateBashing()
	local command, sp = "", ataxia.settings.separator 
	local brage = ataxiaBasher_assembleBattlerage()
	local raze = ataxiaBasher.battlerage.Apostate.raze
	
	if ataxiaBasher.shielded then
		if ataxiaBasher.rageraze and ataxia.vitals.rage >= 17 then
			command = raze..sp.."deadeyes "..target.." bleed bleed; "
		else
			command = "deadeyes "..target.." bleed bleed; "
		end
	else
		command = brage..sp.."deadeyes "..target.." bleed bleed; "
	end
	    
	return command	
end

-- Wield the lyre and (re)compose the bash performance, then (re)start the 15-min
-- "Bard Performance" timer. Needs the instrument in hand, so it wields the lyre first
-- (the next blade attack re-wields the left shield; the rapier stays in the right hand).
-- Called once at bash start (basher_engaged) and again when the 15-min timer expires.
function ataxiaBasher_bardCompose()
   -- Debounce: rapid "not performing" lines (repeated battlerage 'play' commands fire before the
   -- compose lands) can call this several times; the extras are just redundant. Allow one per 2s.
   if bardComposePending then return end
   bardComposePending = true
   tempTimer(2, [[bardComposePending = false]])
   local c = (ataxia.bardStuff and ataxia.bardStuff.bashCompose) or "paean prelude scherzo sonata maqam"
   send("remove lyre;wield left lyre;compose "..c)
   enableTimer("Bard Performance")
   ataxiaEcho("<green>Bard bash:<reset> composed <cyan>"..c)
end

function ataxiaBasher_bardBashing()
   local command = ""
   if bardNeedRapierWield then
      bardNeedRapierWield = false
      command = command.."wield right rapier;wield left shield"..ataxia.settings.separator
   end
   if ataxiaBasher.shielded then
      command = command.."wield right rapier;wield left shield;blade punctuate "..target.. " paean;"
   end
    command = command..ataxiaBasher_assembleBattlerage()

    -- Attack: flick (psychic) by default; punctuate for psychic-resistant denizens
    -- (manual 'bashpunctuate' toggle). Compose/tempo are handled at bash start + timer.
    local atk
    if ataxia.bardStuff and ataxia.bardStuff.bashPunctuate then
       atk = "blade punctuate "..target.." nomos"
    elseif bardWarmarch then
       atk = "blade flick "..target.." paean"  -- Warmarch boon: paean refrain now hits denizens (+100% psychic)
    else
       atk = "blade flick "..target.. " nomos"
    end
    command = command.."wield right rapier;wield left shield;"..atk

   return command
end

function ataxiaBasher_blademasterBashing()
	local command, sp = "", ataxia.settings.separator
	local brage = ataxiaBasher_assembleBattlerage()
	local raze = ataxiaBasher.battlerage.Blademaster.raze

	-- White Heaven's Shattered Star boon (Mnemosyne): multislash strikes 3 EXTRA times
	-- (6 total), so it out-damages the single drawslash -- swap to it while the boon is up.
	-- Straight verb swap (same "sternum" target part): bmShatteredStar is set by the BOONS-list
	-- trigger / boon-claim alias and reset each run (mirrors bardWarmarch); nil/false -> drawslash.
	local slash = bmShatteredStar and ("multislash "..target.." sternum") or ("drawslash "..target.." sternum")

	if ataxiaBasher.shielded then
		if ataxiaBasher.rageraze and ataxia.vitals.rage >= 17 then
			command = raze..sp.."infuse fire "..sp.." "..slash
		else
			command = "raze "..target..sp..brage
		end
	else
		command = brage..sp.."infuse fire "..sp.." "..slash
	end

	return command
end

function ataxiaBasher_depthswalkerBashing()
	local command, sp = "", ataxia.settings.separator
	local brage = ataxiaBasher_assembleBattlerage()
	local raze = ataxiaBasher.battlerage.Depthswalker.raze
	
	if ataxiaBasher.shielded then
		if ataxiaBasher.rageraze and ataxia.vitals.rage >= 17 then
			command = raze..sp.."shadow reap "..target
		else
			command = "shadow reap "..target..sp..brage
		end
	else
		command = brage..sp.."shadow reap "..target
	end
	    
	return command  
end

function ataxiaBasher_infernalBashing()
	local command, sp = "", ataxia.settings.separator
	local raze, bash, spec = "", "", ataxia.vitals.knight
	local brage = ataxiaBasher_assembleBattlerage()
	local braze = ataxiaBasher.battlerage.Infernal.raze

	if spec == "Dual Cutting" then
		raze = "rsl "..target
		if ataxiaBasher.hyenaMaulReady then
			bash = "hyena maul "..target..sp.."dsl "..target..sp
		else
			bash = "dsl "..target..sp
		end
	elseif spec == "Two Handed" then
		raze = "battlefury focus speed"..sp.."splinter "..target
		-- Add hyena maul before slaughter if ready (30s cooldown)
		if ataxiaBasher.hyenaMaulReady then
			bash = "battlefury focus speed"..sp.."hyena maul "..target..sp.."slaughter "..target..sp
		else
			bash = "battlefury focus speed"..sp.."slaughter "..target..sp
		end
	elseif spec == "Dual Blunt" then
		raze = "fracture "..target
		bash = "doublewhirl "..target
	else
		raze = "combination "..target.." raze smash"
		if ataxiaBasher.hyenaMaulReady then
			bash = "hyena maul "..target..sp.."combination "..target.." slice smash"
		else
			bash = "combination "..target.." slice smash"
		end

	end
	
	if ataxiaBasher.shielded then
		if ataxiaBasher.rageraze and ataxia.vitals.rage >= 17 then
			command = braze..sp..bash
		else
			command = raze..sp..brage
		end
	else
		command = brage..sp..bash
	end
	    
	return command 
end

function ataxiaBasher_jesterBashing()
	local command, sp = "", ataxia.settings.separator
	local brage = ataxiaBasher_assembleBattlerage()
	local raze = ataxiaBasher.battlerage.Jester.raze
	local wield = "wield blackjack;wield shield"..sp
	local rawhp = (gmcp.IRE.Target.Info.hpperc or "100"):gsub("%%", "")
	local mobhp = tonumber(rawhp) or 100
	local attack = (mobhp < 50) and "gallowshumour " or "bop "

	if ataxiaBasher.shielded then
		if ataxiaBasher.rageraze and ataxia.vitals.rage >= 17 then
			command = wield..raze..sp..attack..target
		else
			command = wield.."badjoke "..target..sp..brage
		end
	else
		command = wield..brage..sp..attack..target
	end

	return command
end

function ataxiaBasher_magiBashing()

   local command, sp = "", ataxia.settings.separator
	 local brage = ataxiaBasher_assembleBattlerage()
	 local raze = ataxiaBasher.battlerage.Magi.raze
    -- GUI updates only when room contents have changed (dirty flag set by stormhammer invalidation)
    if ataxiaBasher_stormhammerDirty then
      ataxia_Update_RoomContents()
      if zgui then zgui.showRoomInfo() end
    end
    ataxiaBasher_stormhammer()
   if ataxiaBasher.shielded then
      command = command.."cast erode at "..target..ataxia.settings.separator
   end
   
   command = command..ataxiaBasher_assembleBattlerage()

   if not ataxiaBasher.shielded then
    if ataxiaBasher.stormhammer and ataxiaBasher_validTargets() > 2 and #stormhammerTargets >= 3 then
      command = brage..sp.."cast stormhammer at "..stormhammerTargets[1].. " and " ..stormhammerTargets[2].. " and " ..stormhammerTargets[3]
    else
      command = brage..sp.."staff cast horripilation at "..target
    end
   end
   return command   
end


function ataxiaBasher_monkBashing2()
	local command, sp = "", ataxia.settings.separator
	local brage = ataxiaBasher_assembleBattlerage()
	local raze = ataxiaBasher.battlerage.Monk.raze
  local tekura = gmcp.Char.Vitals.charstats[4]:find("Stance") == 1
  local shikudo = gmcp.Char.Vitals.charstats[4]:find("Form") == 1

   --Transmute logic; transmute to 75%, keep mana above 45%.
	local xmute = math.ceil(ataxia.vitals.maxhp * 0.90)
	local mpl = (ataxia.vitals.mp - (ataxia.vitals.maxmp * 0.15))
	local hpl = (xmute - ataxia.vitals.hp)
	local tomute = 0

	if hpl > 1 then
		tomute = (hpl < mpl and hpl or mpl)
		if tomute > 100 then
			command = command.."transmute "..tomute..ataxia.settings.separator
		end
	end

	if ataxiaBasher.shielded then
		if ataxiaBasher.rageraze and ataxia.vitals.rage >= 17 then
			command = command..raze..sp
      if ataxia.settings.crushbash then
        command = command.." mind crush " ..target.. ";"
      elseif tekura then
          command = command.."unwield all"..sp.."combo "..target.. " sdk ucp ucp; "
      elseif shikudo then
        if ataxia.vitals.form == "Rain" and ataxia.vitals.kata >= 20 then
          command = command.."combo "..target.. " ruku torso kuro left frontkick left;transition to the oak form; "
        elseif ataxia.vitals.form == "Rain" and ataxia.vitals.kata < 20 then
          command = command.."combo "..target.. " ruku torso kuro left frontkick left; "
        elseif ataxia.vitals.form == "Oak" and ataxia.vitals.kata >= 8 then
          command = command.."combo "..target.. " livestrike nervestrike risingkick head;transition to the willow form; "
        elseif ataxia.vitals.form == "Oak" and ataxia.vitals.kata < 8 then
          command = command.."combo "..target.. " livestrike nervestrike risingkick head; "
        elseif ataxia.vitals.form == "Willow" and ataxia.vitals.kata >= 6 then
          command = command.."combo "..target.. " hiru hiraku flashheel left;transition to the rain form; "
        elseif ataxia.vitals.form == "Willow" and ataxia.vitals.kata < 6 then
          command = command.."combo "..target.. " hiru hiraku flashheel left; "
        elseif ataxia.vitals.form == "Tykonos" and ataxia.vitals.kata < 5 then
          command = command.."combo "..target.. " thrust head thrust head risingkick head; "
        elseif ataxia.vitals.form == "Tykonos" and ataxia.vitals.kata >= 5 then
          command = command.."combo "..target.. " thrust head thrust head risingkick head;transition to the willow form; "
        end
      end
    elseif not ataxiaBasher.rageraze then
      if ataxia.settings.crushbash then
        command = command.." mind crush " ..target..";"
      elseif tekura then
        command = command.."unwield all"..sp.."combo "..target.. " rhk ucp ucp; "
      elseif shikudo and ataxia.settings.crushbash == false then
        if ataxia.vitals.form == "Rain" and ataxia.vitals.kata >= 19 then
          command = command.."combo "..target.. " shatter hiru frontkick left;transition to the oak form; "
        elseif ataxia.vitals.form == "Rain" and ataxia.vitals.kata < 19 then
          command = command.."combo "..target.. " shatter hiru frontkick left; "
        elseif ataxia.vitals.form == "Oak" and ataxia.vitals.kata >= 7 then
          command = command.."combo "..target.. " shatter livestrike risingkick head;transition to the willow form; "
        elseif ataxia.vitals.form == "Oak" and ataxia.vitals.kata < 7 then
          command = command.."combo "..target.. " shatter livestrike risingkick head; "
        elseif ataxia.vitals.form == "Willow" and ataxia.vitals.kata >= 6 then
          command = command.."combo "..target.. " shatter hiru flashheel left;transition to the rain form; "
        elseif ataxia.vitals.form == "Willow" and ataxia.vitals.kata < 6 then
          command = command.."combo "..target.. " shatter hiru flashheel left; "
        elseif ataxia.vitals.form == "Tykonos" and ataxia.vitals.kata < 5 then
          command = command.."combo "..target.. " shatter thrust head risingkick head; "
        elseif ataxia.vitals.form == "Tykonos" and ataxia.vitals.kata >= 5 then
          command = command.."combo "..target.. " shatter thrust head risingkick head;transition to the willow form; "
        end
       end
      end
 else
		command = command..brage..sp
     if ataxia.settings.crushbash then
       command = command.."mind crush " ..target..";"
     elseif tekura then
       command = command.."unwield all"..sp.."combo "..target.. " sdk ucp ucp; "
     elseif shikudo and ataxia.settings.crushbash == false then
        if ataxia.vitals.form == "Rain" and ataxia.vitals.kata >= 20 then
          command = command.."combo "..target.. " ruku torso kuro left frontkick left;transition to the oak form; "
        elseif ataxia.vitals.form == "Rain" and ataxia.vitals.kata < 20 then
          command = command.."combo "..target.. " ruku torso kuro left frontkick left; "
        elseif ataxia.vitals.form == "Oak" and ataxia.vitals.kata >= 8 then
          command = command.."combo "..target.. " livestrike nervestrike risingkick head;transition to the willow form; "
        elseif ataxia.vitals.form == "Oak" and ataxia.vitals.kata < 8 then
          command = command.."combo "..target.. " livestrike nervestrike risingkick head; "
        elseif ataxia.vitals.form == "Willow" and ataxia.vitals.kata >= 6 then
          command = command.."combo "..target.. " hiru hiraku flashheel left;transition to the rain form; "
        elseif ataxia.vitals.form == "Willow" and ataxia.vitals.kata < 6 then
          command = command.."combo "..target.. " hiru hiraku flashheel left; "
        elseif ataxia.vitals.form == "Tykonos" and ataxia.vitals.kata < 5 then
          command = command.."combo "..target.. " thrust head thrust head risingkick head; "
        elseif ataxia.vitals.form == "Tykonos" and ataxia.vitals.kata >= 5 then
          command = command.."combo "..target.. " thrust head thrust head risingkick head;transition to the willow form; "
        end
       end    
	end
  
	return command   
end









function ataxiaBasher_occultistBashing()
   local command = ""   
   
   command = command..ataxiaBasher_assembleBattlerage()
   command = command.."warp "..target

   return command   
end

function ataxiaBasher_pariahBashing()
	local command, sp = "", ataxia.settings.separator
	local brage = ataxiaBasher_assembleBattlerage()
	local raze = ataxiaBasher.battlerage.Pariah.raze

	if ataxiaBasher.shielded then
		-- Target is shielded, use raze to break it
		command = "trace fissure "..target
	elseif ataxiaBasher.swarmDevourReady then
		-- Swarm devour ready - unwield shield, devour, then epitaph advance
		command = "unwield shield"..sp.."swarm devour flushings "..target..sp..brage.."epitaph advance "..target
	else
		-- Swarm devour on cooldown - wield shield and epitaph advance
		command = "wield shield"..sp..brage.."epitaph advance "..target
	end

	return command
end

function ataxiaBasher_paladinBashing()
	local command, sp = "", ataxia.settings.separator
	local raze, bash, spec = "", "", ataxia.vitals.knight
	local brage = ataxiaBasher_assembleBattlerage()
	local braze = ataxiaBasher.battlerage.Paladin.raze

	if spec == "Dual Cutting" then
		raze = "rsl "..target
		bash = "dsl "..target
	elseif spec == "Two Handed" then
		raze = "battlefury focus speed"..sp.."carve "..target
		bash = "battlefury focus speed"..sp.."slaughter "..target
	elseif spec == "Dual Blunt" then
		raze = "fracture "..target
		bash = "doublewhirl "..target
	else
		raze = "combination "..target.." raze smash"
		bash = "combination "..target.." slice smash"
	end

	if ataxiaBasher.shielded then
		if ataxiaBasher.rageraze and ataxia.vitals.rage >= 17 then
			command = braze..sp..bash
		else
			command = raze..sp..brage
		end
	else
		command = brage..sp..bash
	end

	return command
end

function ataxiaBasher_psionBashing()
  local command, sp = "", ataxia.settings.separator
  local brage = ataxiaBasher_assembleBattlerage()
  local raze = ataxiaBasher.battlerage.Psion.raze

  if ataxiaBasher.shielded then
    if ataxiaBasher.rageraze and ataxia.vitals.rage >= 17 then
      command = command..raze..sp
      command = command.."weave cleave "..target
    end
  elseif ataxiaTemp.transcendence and ataxiaTemp.transcendence == 100 then
  command = command..sp..brage..sp
    command = command.."psi shatter "..target..sp.."weave deathblow "..target
  else
    command = command..sp..brage..sp
    command = command.."weave deathblow "..target
    --Deathblow does 3 percent to elite mhun keeper
  end
  return command
end

function ataxiaBasher_priestBashing()
	local command, sp = "", ataxia.settings.separator
	local brage = ataxiaBasher_assembleBattlerage()
	local raze = ataxiaBasher.battlerage.Priest.raze
	
	if ataxiaBasher.shielded then
		if ataxiaBasher.rageraze and ataxia.vitals.rage >= 17 then
			command = raze..sp.."smite "..target
		else
			command = "smite "..target
		end
	else
		command = brage..sp.."smite "..target
	end
	if empathyTick and empathyTick >= 2 then
		command = command..sp.."angel power"
	end   
	return command 
end

function ataxiaBasher_knightBashing()
	local command, sp = "", ataxia.settings.separator
	local raze, bash, spec = "", "", ataxia.vitals.knight
	local brage = ataxiaBasher_assembleBattlerage()
	local braze = ataxiaBasher.battlerage[ataxiaTemp.class].raze

	if spec == "Dual Cutting" then
		raze = "rsl "..target
		bash = "dsl "..target
	elseif spec == "Two Handed" then
		raze = "battlefury focus speed"..sp.."carve "..target
		bash = "battlefury focus speed"..sp.."slaughter "..target
	elseif spec == "Dual Blunt" then
		raze = "fracture "..target
		bash = "doublewhirl "..target
	else
		raze = "combination "..target.." raze smash"
		bash = "combination "..target.." slice smash"
	end

	if ataxiaBasher.shielded then
		if ataxiaBasher.rageraze and ataxia.vitals.rage >= 17 then
			command = braze..sp..bash
		else
			command = raze..sp..brage
		end
	else
		command = brage..sp..bash
	end

	return command
end

function ataxiaBasher_runewardenBashing()
	local command, sp = "", ataxia.settings.separator
	local raze, bash, spec = "", "", ataxia.vitals.knight
	local brage = ataxiaBasher_assembleBattlerage()
	local braze = ataxiaBasher.battlerage.Runewarden.raze

	-- Falcon rake: free pet attack on a 30s cooldown (mirrors the Infernal hyena maul).
	-- Prepended to the bash when ready; cooldown tracked in 005_Falcon_Cooldowns.lua.
	local falcon = (ataxiaBasher.falconRakeReady and ("falcon rake "..target..sp)) or ""

	if spec == "Dual Cutting" then
		raze = "rsl "..target
		bash = falcon.."dsl "..target
	elseif spec == "Two Handed" then
		raze = "battlefury focus speed"..sp.."carve "..target
		bash = "battlefury focus speed"..sp..falcon.."slaughter "..target
	elseif spec == "Dual Blunt" then
		raze = "fracture "..target
		bash = falcon.."doublewhirl "..target
	else
		raze = "combination "..target.." raze smash"
		bash = falcon.."combination "..target.." slice smash"
	end

	if ataxiaBasher.shielded then
		if ataxiaBasher.rageraze and ataxia.vitals.rage >= 17 then
			command = braze..sp..bash
		else
			command = raze..sp..brage
		end
	else
		command = brage..sp..bash
	end

	return command
end

function ataxiaBasher_sentinelBashing()
   local command = ""
   if ataxiaBasher.shielded then
      command = command.."rivestrike "..target..ataxia.settings.separator
   end
   
   command = command..ataxiaBasher_assembleBattlerage()
      
   if not ataxiaBasher.shielded then 
      command = command.."thrust "..target
   end
 
   return command 
end

function ataxiaBasher_serpentBashing()
   local command = ""
	 local brage = ataxiaBasher_assembleBattlerage()

   if ataxiaBasher.shielded then
      command = command.."flay "..target.." shield"..ataxia.settings.separator
   end

   command = command..brage

   if not ataxiaBasher.shielded then
      command = command.."garrote "..target
   end

   return command
end

function ataxiaBasher_shamanBashing()	
local healhealth = tonumber(math.floor((ataxia.vitals.hp/ataxia.vitals.maxhp)*100))


	local command, sp = "", ataxia.settings.separator
	local brage = ataxiaBasher_assembleBattlerage()
	local raze = ataxiaBasher.battlerage.Shaman.raze
  
  if not shaman.spiritlore.bashType then shaman.spiritlore.bashType = "swiftcure" end
	local bash_type = shaman.spiritlore.bashType
  
  
 if healhealth < 60 then
          atk = "stand;wield shield;invoke regeneration"
  elseif bash_type == "arius" and shaman.spiritisbound("arius") then
    atk = "invoke roar "..target
  elseif bash_type == "swiftcurse" and shaman.spiritisbound("aelkesh") then
    if curseCharge <= 1 then
      atk = "stand;wield shield;swiftcurse"
    else
      atk = "stand;wield shield;swiftcurse "..target.." bleed"
    end
  else
    if ataxiaTemp.canJinx then
      atk = "jinx bleed bleed "..target
    else
      atk = "curse "..target.." bleed"
    end
  end
  
	
  if brage == "" then
  		command = atk

  else
		command = brage..sp..atk
	end
	return command   
end



function ataxiaBasher_sylvanBashing()
   local command = ""
         
   command = command..ataxiaBasher_assembleBattlerage()
   command = command.."synchronise shear windwhip "..target

   return command 
end

function ataxiaBasher_wEleBashing()
   local command = ""   
   if ataxiaBasher.shielded then
      command = command.."manifest blade "..target..ataxia.settings.separator
   end
   
   command = command..ataxiaBasher_assembleBattlerage()
   
   if not ataxiaBasher.shielded then   
      command = command.."manifest blade "..target
   end
   
   return command   
end