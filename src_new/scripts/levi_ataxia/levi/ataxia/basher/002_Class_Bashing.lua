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


-- Willow is the damage form (speed is king), and Willow -> Rain -> Oak -> Willow is the
-- shortest legal cycle back to it (see shikudo.transitions), so ride Willow to its 12-kata
-- cap and leave Rain/Oak as soon as a transition is LEGAL.
--
-- leaveAt is the kata the chain must ALREADY be at, read *before* this combo is sent.
-- A TRANSITION needs a chain of at least 5 ("A kata of at least 5 must be performed in order
-- to flow from the Live Oak to another") and a REJECTED transition RESETS the chain to 0.
-- That reset is why leaveAt must be >= 5 and not 2: the old value bet on the queued combo's
-- 3 actions landing first (2+3=5), but in game the transition was evaluated while the chain
-- was still 3, got rejected, reset the chain, and the next pass repeated it -- an infinite
-- fail loop that never transitioned at all. Gate on a chain that is legal on its own and the
-- loop cannot form, whatever the combo contributes.
--
-- Combos are 3 actions, so the chain steps 0,3,6,9,12 and first satisfies >= 5 at 6.
-- That gives 4 combos in Willow (0,3,6,9) and 3 in each of Rain/Oak (0,3,6) -- ~40% Willow.
-- Tykonos is where a stumble dumps you, and it transitions straight back to Willow.
local SHIKUDO_BASH_ROTATION = {
  Willow    = {nextForm = "Rain",   leaveAt = 9},
  Rain      = {nextForm = "Oak",    leaveAt = 5},
  Oak       = {nextForm = "Willow", leaveAt = 5},
  Tykonos   = {nextForm = "Willow", leaveAt = 5},
  Gaital    = {nextForm = "Rain",   leaveAt = 5},
  Maelstrom = {nextForm = "Oak",    leaveAt = 5},
}

-- shieldbreak variants swap a hit for shatter. Gaital/Maelstrom combos are built from
-- shikudo.formAttacks rather than copied from known-good code — verify in game.
local SHIKUDO_BASH_COMBOS = {
  Willow    = {normal = "hiru hiraku flashheel left",             shieldbreak = "shatter hiru flashheel left"},
  Rain      = {normal = "ruku torso kuro left frontkick left",    shieldbreak = "shatter hiru frontkick left"},
  Oak       = {normal = "livestrike nervestrike risingkick head", shieldbreak = "shatter livestrike risingkick head"},
  Tykonos   = {normal = "thrust head thrust head risingkick head", shieldbreak = "shatter thrust head risingkick head"},
  Gaital    = {normal = "ruku torso kuro left dawnkick left",     shieldbreak = "shatter ruku dawnkick left"},
  Maelstrom = {normal = "ruku torso livestrike risingkick head",  shieldbreak = "shatter ruku risingkick head"},
}

-- These fire from the attack path, which runs on every prompt — latch them so an
-- unrecognised form or spec warns once rather than flooding the screen.
local shikudoWarnedForm = nil
local monkWarnedNoSpec = false

local function shikudoBashCombo(tar, useShieldbreak)
  local form = ataxia.vitals.form
  local combos, rot = SHIKUDO_BASH_COMBOS[form], SHIKUDO_BASH_ROTATION[form]
  if not combos or not rot then
    if shikudoWarnedForm ~= form then
      shikudoWarnedForm = form
      ataxiaEcho("Shikudo: don't know how to bash in '"..tostring(form).."' form.")
    end
    return ""
  end
  shikudoWarnedForm = nil

  local cmd = "combo "..tar.." "..(useShieldbreak and combos.shieldbreak or combos.normal)
  -- COMBO takes an inline TRANSITION suffix -- per AB SHIKUDO COMBO:
  --   COMBO <target> <attack1> [limb] [attack2] [limb] [attack3] [limb] [TRANSITION <form>]
  -- Use that rather than a separate `transition to the <form> form` command: the inline form
  -- resolves inside the combo's own flow instead of racing the three attacks that build the
  -- chain it depends on. kata is absent from charstats until a chain starts, hence `or 0`.
  if (ataxia.vitals.kata or 0) >= rot.leaveAt then
    cmd = cmd.." transition "..rot.nextForm:lower()
    -- A successful TRANSITION resets the chain to 0, but charstats keeps reporting the OLD
    -- kata for a tick. Without zeroing it here the very next prompt still reads the pre-
    -- transition kata (e.g. 6), re-appends a transition, and that one resolves against a
    -- chain of only 3 -> "A kata of at least 5 must be performed..." -> a wasted attempt after
    -- every single form change. Zero it optimistically; charstats re-reports the true value on
    -- its next tick, and 002_Reset_Failsafe also zeroes it if the transition is rejected, so a
    -- wrong guess here self-corrects within one tick either way.
    ataxia.vitals.kata = 0
  end
  return cmd.."; "
end

function ataxiaBasher_monkBashing2()
	local command, sp = "", ataxia.settings.separator
	local brage = ataxiaBasher_assembleBattlerage()
  -- Resolve the spec by charstats *key* via the vitals parser, not by the positional
  -- index charstats[4]: a shifted index silently made both flags false (= no attack).
  -- ataxia.vitals.stance is reset to false every vitals tick, so it is a safe discriminator.
  local tekura = ataxia.vitals.stance and true or false
  local shikudo = not tekura and ataxia.vitals.form ~= nil

  -- Transmute is a GAP-FILLER, not a top-up. Health sipping is server-side (CURING SIPHEALTH,
  -- default 80), so while sip balance is UP the server is already healing us -- transmuting back
  -- to 90% on every single balance (the old behaviour) just burned the mana that Regeneration
  -- converts into health anyway, plus everything else that needs mana. Only fire in the window
  -- sipping cannot cover: sip balance DOWN and actually low on health.
  --   transmuteat : hp% at/below which transmute may fire  (default 70)
  --   transmuteto : hp% to top back up to                  (default 99)
  --   manause     : mp% floor we never spend past          (default 30)
  -- `sipbal == false` and NOT `not sipbal`: ataxia.vitals is reset to {} on login and only the
  -- sip triggers (balances/002,003) ever set it, so it is nil until the first sip of a session
  -- -- nil must not read as "off balance" or we would transmute with sip balance in hand.
  local sip = ataxia.settings.sipping or {}
  local maxhp, maxmp = ataxia.vitals.maxhp or 0, ataxia.vitals.maxmp or 0
  if ataxia.vitals.sipbal == false and maxhp > 0
     and (ataxia.vitals.hp / maxhp * 100) <= (sip.transmuteat or 70) then
    local xmute = math.ceil(maxhp * ((sip.transmuteto or 99) / 100))
    local mpl = ataxia.vitals.mp - (maxmp * ((sip.manause or 30) / 100))
    local hpl = xmute - ataxia.vitals.hp
    if hpl > 1 then
      -- floor(): the mana floor is fractional, so the min can be too, and `transmute 1234.5`
      -- is not a valid command.
      local tomute = math.floor(hpl < mpl and hpl or mpl)
      if tomute > 100 then
        command = command.."transmute "..tomute..ataxia.settings.separator
      end
    end
  end

  -- Monk NEVER spends rage to break a denizen shield: both specs carry a free shield breaker
  -- (Shikudo `shatter` -- uniquely usable in the flow of ANY form -- and Tekura `rhk`), so the
  -- 17-rage Splinterkick raze (battlerage.Monk.raze = "spk") is always the worse trade; that
  -- rage is worth more on damage/afflictions. `ataxiaBasher.rageraze` is deliberately ignored
  -- here -- it still governs every other class. Shielded => skip battlerage and let the combo
  -- break the shield itself.
  -- CAVEAT: the crushbash branch below ignores useShieldbreak -- `mind crush` neither breaks a
  -- shield nor spends rage, so a shielded mob in crushbash mode is only handled if mind crush
  -- (being mental) bypasses shielding. Pre-existing; unconfirmed in game.
  local useShieldbreak = ataxiaBasher.shielded and true or false
  if not useShieldbreak then
    command = command..brage..sp
  end

  if ataxia.settings.crushbash then
    command = command.."mind crush "..target.."; "
  elseif tekura then
    monkWarnedNoSpec = false
    command = command.."unwield all"..sp.."combo "..target..(useShieldbreak and " rhk ucp ucp; " or " sdk ucp ucp; ")
  elseif shikudo then
    monkWarnedNoSpec = false
    command = command..shikudoBashCombo(target, useShieldbreak)
  elseif not monkWarnedNoSpec then
    monkWarnedNoSpec = true
    ataxiaEcho("Monk: no Stance or Form in charstats — can't tell Tekura from Shikudo, not bashing.")
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