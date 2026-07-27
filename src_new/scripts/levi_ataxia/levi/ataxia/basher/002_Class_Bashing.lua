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
  -- Golden Dragon owns its battlerage (aeon/amnesia control rotation below); the other
  -- colours still go through the generic assembler. LAZY on purpose (review MEDIUM):
  -- the golden rotation stamps cooldowns when it picks, so it must only be called on
  -- branches that actually SEND the pick -- the shielded+rageraze round spends its
  -- rage on the raze and emits no battlerage, and an eager call there would burn a
  -- 35-41s control stamp unsent.
  local function brage()
    if gmcp.Char.Status.class == "Golden Dragon" then
      return ataxiaBasher_goldenDragonBattlerage(sp)
    end
    return ataxiaBasher_assembleBattlerage()
  end
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
      command = command..sp..reblast..balAttack()..sp..brage()
    end
  else
    command = command..sp..brage()..sp..primary()
  end
  return command
end

-- Golden Dragon OWNS its battlerage (the Psion lesson, v4.7.128): the generic
-- fallback gates small behind battleRage_Timers.small, which trigger 330 never sets
-- for Golden Dragon (no Overwhelm fire-line) -- so Overwhelm was re-sent into its own
-- 16s cooldown every swing AND, because small always won the elseif, Psiblast could
-- NEVER fire. Deaden/Psidaze weren't wired at all. Timer-free send-side epoch stamps
-- with the AB cooldowns. Priority is CONTROL first (user-directed -- denizen aeon and
-- amnesia gut incoming damage): Deaden 24r/35s (AEON: every action slowed) >
-- Psidaze 28r/41s (AMNESIA: recurring forgets) > Psiblast 36r/23s > Overwhelm
-- 14r/16s filler. When a control cast is off cooldown but rage can't cover it yet,
-- the damage fillers are SKIPPED so the rage banks toward the control cast instead
-- of Overwhelm starving it 14 rage at a time.
local GDRAGON_BR = {
  { key = "deaden",    cmd = "deaden",    rage = 24, cd = 35, control = true },
  { key = "psidaze",   cmd = "psidaze",   rage = 28, cd = 41, control = true },
  { key = "psiblast",  cmd = "psiblast",  rage = 36, cd = 23 },
  { key = "overwhelm", cmd = "overwhelm", rage = 14, cd = 16 },
}
function ataxiaBasher_goldenDragonBattlerage(sp)
  local rage = tonumber(ataxia.vitals.rage) or 0
  -- Rage conservation: same rule the generic assembler applies. Clears any in-flight
  -- pick so a stale cast can't resume on the NEXT mob.
  if ataxiaBasher.rageConserveThreshold then
    local mobhp = tonumber(((gmcp.IRE.Target.Info.hpperc or "100"):gsub("%%", ""))) or 100
    if mobhp > 0 and mobhp <= ataxiaBasher.rageConserveThreshold then
      ataxiaTemp.gdragonBrPending = nil
      return ""
    end
  end
  local nowT = (getEpoch and getEpoch()) or os.time()
  -- In-flight pick REPLAY (review HIGH): the basher REBUILDS this command every
  -- prompt/vitals event (0.3s addclearfull re-queue loop) while a swing's balance is
  -- down, and each rebuild wipes the previously queued line. Stamping a fresh pick
  -- per rebuild burned the whole rotation phantom-style -- the top-priority controls
  -- got stamped-then-wiped and only the LAST rebuild's filler ever fired (priority
  -- inversion). So a pick stays PENDING for ~one balance round and is replayed
  -- verbatim (the bloodboil stability rule: the returned command must stay stable
  -- across the re-queue loop); the rotation only advances once the hold expires.
  local pend = ataxiaTemp.gdragonBrPending
  if pend and pend.verb and (nowT - (tonumber(pend.at) or 0)) < 3 then
    return pend.verb.." "..target..sp
  end
  ataxiaTemp.gdragonBrPending = nil
  if ataxiaBasher.cullingBlade and not ataxiaTemp.bladeCooldown and rage >= 36
     and gmcp.Room.Info.area ~= "the Fathomless Expanse of the World Tree" then
    return "reap "..target..sp
  end
  ataxiaTemp.gdragonBrAt = ataxiaTemp.gdragonBrAt or {}
  for _, ab in ipairs(GDRAGON_BR) do
    if (nowT - (tonumber(ataxiaTemp.gdragonBrAt[ab.key]) or 0)) >= ab.cd then
      if rage >= ab.rage then
        ataxiaTemp.gdragonBrAt[ab.key] = nowT
        ataxiaTemp.gdragonBrPending = { verb = ab.cmd, at = nowT }
        return ab.cmd.." "..target..sp
      elseif ab.control then
        return "" -- bank rage for the pending aeon/amnesia cast
      end
    end
  end
  return ""
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

	-- Bladed Reflexes boon (Mnemosyne): 20% reduced damage while the Shindo AUGMENT state is
	-- up. SHIN AUGMENT <ALL|amount> channels shin into the reflex augment (tracked as the
	-- bodyaugment defence); spend the MINIMUM (1) -- augment with 0 shin just fails, and
	-- infuse fire competes for the same resource. Gated on the GMCP-tracked defence (expiry
	-- arrives via Char.Defences.Remove, no duration guessing) plus a short attempt-hold so
	-- the channel wind-up ("beginning the process...") isn't respammed every swing. Flag
	-- mirrors bmShatteredStar (claim alias + BOONS row trigger 019, reset each run).
	if bmBladedReflexes and not (ataxia.defences and ataxia.defences.bodyaugment)
		 and not ataxiaTemp.bmAugmentAttempted then
		local shin = (blademaster and blademaster.getShin and blademaster.getShin())
			or (ataxia.vitals and tonumber(ataxia.vitals.class)) or 0
		-- Live log 2026-07-26: "shin augment 1" channeled and DISSIPATED 12ms later, twice --
		-- one shin buys ~zero duration, so the boon's 20% DR was never actually up. Spend a
		-- real chunk (duration appears to scale with the amount); tune via bmAugmentAmount.
		local amt = tonumber(ataxiaBasher.bmAugmentAmount) or 3
		if shin >= amt then
			ataxiaTemp.bmAugmentAttempted = true
			tempTimer(5, [[ataxiaTemp.bmAugmentAttempted = nil]])
			command = "shin augment "..amt..sp
		end
	end

	if ataxiaBasher.shielded then
		if ataxiaBasher.rageraze and ataxia.vitals.rage >= 17 then
			command = command..raze..sp.."infuse fire "..sp.." "..slash
		else
			command = command.."raze "..target..sp..brage
		end
	else
		command = command..brage..sp.."infuse fire "..sp.." "..slash
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

-- Stormhammer/GUI prep, split out of magiBashing. The autobash loop pre-calls this once BEFORE
-- the attack (genrunning/004) so stormhammerTargets/GUI are current. It must NOT run the
-- battlerage: magiBashing is invoked twice per cycle (that pre-call + the real assembleAttack
-- call), and now that magiBattlerage ARMS its cooldowns on fire, a full pre-call would arm them
-- and the real call would then return "" -- Magi would send no battlerage at all. So the pre-call
-- does prep only; the send-path magiBashing does prep + battlerage. Cache-gated, so running the
-- prep in both is cheap.
function ataxiaBasher_magiStormPrep()
   -- GUI updates only when room contents have changed (dirty flag set by stormhammer invalidation)
   if ataxiaBasher_stormhammerDirty then
      ataxia_Update_RoomContents()
      if zgui then zgui.showRoomInfo() end
   end
   ataxiaBasher_stormhammer()
end

function ataxiaBasher_magiBashing()
   local command, sp = "", ataxia.settings.separator
   local brage = ataxiaBasher_assembleBattlerage()
   ataxiaBasher_magiStormPrep()

   -- Active self-cure (Bloodboil) takes the equilibrium slot when afflictions have piled up (3+)
   -- and the Tree of Life tattoo -- the passive cure -- is on balance. It is a main skill, not a
   -- battlerage, so it replaces the eq staff-bash for this cycle; battlerage (rage) still fires
   -- alongside. addclearfull-queued, so it self-dedups and just waits for eq. See
   -- ataxiaBasher_magiShouldBloodboil (basher/001).
   if ataxiaBasher_magiShouldBloodboil() then
      return brage..sp.."cast bloodboil"
   end

   if ataxiaBasher.shielded then
      -- erode is Magi's free shield strip (why Disintegrate is never fired -- see magiBattlerage).
      -- Strip FIRST, then battlerage -- a still-up denizen shield absorbs the BR otherwise
      -- (matches blademasterBashing's raze..sp..brage order).
      command = "cast erode at "..target..sp..brage
   elseif magiKkractle then
      -- Aspect of Kkractle boon (Mnemosyne): ELEMENTAL SURGE deals fire to ALL denizens in the
      -- room (AoE, no target), out-clearing single-target horripilation and stormhammer's 3-cap.
      -- Set by the BOONS-list trigger / boon-claim alias, reset each run (mirrors bmShatteredStar).
      -- Same eq-cast slot horripilation used, so no extra spam vs the old unconditional attack.
      -- Needs a summoned ashbeast up (kept off the target list via ownDenizens = ...ashbeast).
      command = brage..sp.."elemental surge"
   elseif ataxiaBasher.stormhammer and ataxiaBasher_validTargets() > 2 and #stormhammerTargets >= 3 then
      command = brage..sp.."cast stormhammer at "..stormhammerTargets[1].. " and " ..stormhammerTargets[2].. " and " ..stormhammerTargets[3]
   else
      command = brage..sp.."staff cast horripilation at "..target
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

-- Kai Unleashed boon (Mnemosyne, legendary): "Kai choking a denizen deals a burst of
-- magic damage to all denizens in its location, including itself. This effect has a
-- 30 seconds cooldown before it can trigger again." User doctrine: RAIN form only,
-- off cooldown, priority when 2+ denizens share the room (the burst hits them all).
-- AB Kaichoke (ID 896) facts: KAI CHOKE <target>, 4.00s of EQUILIBRIUM, 10 kai +
-- 50 mana -- but **against a denizen it requires and consumes NO kai** (same-room
-- only, which bashing always is), so there is no kai gate here, just a small mana
-- floor. Because it rides EQ -- idle while Shikudo combos spend balance -- the choke
-- PREPENDS to the round's combo rather than replacing it: burst and swing land
-- together. The rotation re-visits Rain every cycle, so no form-forcing. Cooldown
-- (the BOON's 30s burst, not the ability's 4s eq) stamped at send into ataxiaTemp
-- (survives a SYSUPDATE reload; cleared on run end).
local KAI_UNLEASHED_CD = 30 -- the boon burst's cooldown, from the CONFIRMED burst line
local KAI_CHOKE_RETRY = 6   -- unconfirmed choke (eaten/wiped/no proc): retry this often
function ataxiaBasher_kaiUnleashedChoke(useShieldbreak)
  if not mnemKaiUnleashed then return nil end
  if useShieldbreak then return nil end -- shielded target: let shatter land first
  if ataxia.vitals.form ~= "Rain" then return nil end
  if (tonumber(ataxia.vitals.mp) or 9999) < 250 then return nil end -- 50-mana cost; never scrape a dry pool
  local M = ataxia.mnemosyne
  local n = (M and M._denizenCount and M._denizenCount()) or 0
  if n < 2 then return nil end
  local nowT = (getEpoch and getEpoch()) or os.time()
  ataxiaTemp = ataxiaTemp or {}
  if (nowT - (tonumber(ataxiaTemp.kaiUnleashedAt) or 0)) < KAI_UNLEASHED_CD then return nil end
  if (nowT - (tonumber(ataxiaTemp.kaiChokePendingAt) or 0)) < KAI_CHOKE_RETRY then return nil end
  ataxiaTemp.kaiChokePendingAt = nowT
  return "kai choke "..target.."; "
end

-- Burst CONFIRMED (trigger 031, live-captured 2026-07-27): "Your surroundings ripple
-- like a lake's surface struck as a transparent wave of kai energy surges outwards
-- from <mob>, wracking mind and body." (8472 magical in the capture). The line only
-- prints with the boon up (self-proving, like the Reaper tithe), so it also sets the
-- flag. The REAL 30s cooldown starts HERE, not at send -- an eaten/wiped choke must
-- not lock the burst out; it just retries after KAI_CHOKE_RETRY.
function ataxiaBasher_kaiUnleashedBurst()
  mnemKaiUnleashed = true
  ataxiaTemp = ataxiaTemp or {}
  ataxiaTemp.kaiUnleashedAt = (getEpoch and getEpoch()) or os.time()
  ataxiaTemp.kaiChokePendingAt = nil
end

-- Senseless Flurry boon (Mnemosyne): "Your balance recovers 30% faster while you
-- have the numbness defence." AB Numbness (ID 894): NUMB, self-only, 3.00s of
-- EQUILIBRIUM -- the same idle-during-combos channel Kai Choke rides -- and it
-- DEFERS incoming damage (delivered later in one blow at -40%: strictly good while
-- bashing, and the swarm module's per-prompt vitals watchdog already covers the
-- deferred hit landing). User doctrine: keep numbness up in RAIN form. Gated on
-- the GMCP-tracked defence (expiry arrives via Char.Defences.Remove -- no duration
-- guessing; fire line "You grit your teeth and will your pain out of existence."
-- live-captured 2026-07-27) + the bmAugment-style 5s attempt-hold against respam.
-- Kai Choke OUTRANKS it for a round's eq (see the call site): the 30s AoE burst
-- is worth more than a numb refresh. Self-targeted, so shielded rounds still numb.
function ataxiaBasher_senselessFlurryNumb()
  if not mnemSenselessFlurry then return nil end
  if ataxia.vitals.form ~= "Rain" then return nil end
  if ataxia.defences and ataxia.defences.numbness then return nil end
  -- CROWD GATE (review HIGH): while numb is up HP does not move, so EVERY HP-based
  -- safety goes blind -- the damage-rate watchdog records nothing, danger levels
  -- never trip, and the swarm escape ladder (HP-gated) stays silent -- then the
  -- deferred lump lands as ONE blow (-40%) that in a deep-ripple crowd can exceed
  -- max HP: death from "full HP" with every alarm quiet. Numb only in THIN rooms,
  -- where the lump is survivable and the next prompt's huge hp-delta trips the
  -- rate-shield normally; in swarm-threshold crowds (or mid-tactic) live HP data
  -- is worth more than 30% balance.
  local M = ataxia.mnemosyne
  local n = (M and M._denizenCount and M._denizenCount()) or 0
  local thr = (M and M.swarm and M.swarm.threshold and M.swarm.threshold()) or 3
  if n >= thr then return nil end
  if M and M.swarm and M.swarm.state and M.swarm.state ~= "idle" then return nil end
  ataxiaTemp = ataxiaTemp or {}
  if ataxiaTemp.numbAttempted then return nil end
  ataxiaTemp.numbAttempted = true
  tempTimer(5, [[ataxiaTemp.numbAttempted = nil]])
  return "numb; "
end

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
    -- EQ riders alongside the balance combo (both land the same round). One eq
    -- spender per round: Kai Unleashed's 30s AoE burst outranks the Senseless
    -- Flurry numb refresh when both are eligible.
    local choke = ataxiaBasher_kaiUnleashedChoke(useShieldbreak)
    command = command..(choke or ataxiaBasher_senselessFlurryNumb() or "")
    command = command..shikudoBashCombo(target, useShieldbreak)
  elseif not monkWarnedNoSpec then
    monkWarnedNoSpec = true
    ataxiaEcho("Monk: no Stance or Form in charstats -- can't tell Tekura from Shikudo, not bashing.")
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

-- Psion OWNS its battlerage (the Blademaster/Magi pattern): the generic assembler's
-- old Psion branch gated Barbedblade/Whirlwind behind `battleRage_Timers.special`,
-- but triggers 330-332 have NO Psion fire-lines -- the timers were never set, so the
-- rotation was Regrowth-only forever. This is timer-FREE: send-side epoch stamps with
-- the wiki cooldowns (Devastate/Whirlwind 23s, Barbedblade 16s, Regrowth 35s), so it
-- depends on nothing unwired. Priority: reap (culling) > Devastate (the 36-rage nuke
-- the old table lacked) > Whirlwind > Barbedblade filler. Regrowth (anti-heal vines)
-- only pays vs self-healing denizens ("tending his wounds"), so it is OPT-IN via
-- `ataxiaBasher.psionRegrowth` and takes priority when enabled.
local PSION_BR = {
  { key = "regrowth",   cmd = "enact regrowth",   rage = 24, cd = 35, optIn = true },
  { key = "devastate",  cmd = "psi devastate",    rage = 36, cd = 23 },
  { key = "whirlwind",  cmd = "weave whirlwind",  rage = 25, cd = 23 },
  { key = "barbedblade", cmd = "weave barbedblade", rage = 14, cd = 16 },
}
function ataxiaBasher_psionBattlerage(sp)
  local rage = tonumber(ataxia.vitals.rage) or 0
  -- Rage conservation: same rule the generic assembler applies. Clears any in-flight
  -- pick so a stale cast can't resume on the NEXT mob.
  if ataxiaBasher.rageConserveThreshold then
    local mobhp = tonumber(((gmcp.IRE.Target.Info.hpperc or "100"):gsub("%%", ""))) or 100
    if mobhp > 0 and mobhp <= ataxiaBasher.rageConserveThreshold then
      ataxiaTemp.psionBrPending = nil
      return ""
    end
  end
  local nowT = (getEpoch and getEpoch()) or os.time()
  -- In-flight pick REPLAY (v4.7.129 review HIGH, found on the Golden Dragon copy of
  -- this pattern): the basher rebuilds this command every prompt/vitals event while
  -- balance is down, and each rebuild's addclearfull wipes the previously queued
  -- line -- stamping per rebuild burned the rotation phantom-style. A pick stays
  -- pending ~one balance round and is replayed verbatim (command stability across
  -- the 0.3s re-queue loop); the rotation advances only after the hold expires.
  local pend = ataxiaTemp.psionBrPending
  if pend and pend.verb and (nowT - (tonumber(pend.at) or 0)) < 3 then
    return pend.verb.." "..target..sp
  end
  ataxiaTemp.psionBrPending = nil
  if ataxiaBasher.cullingBlade and not ataxiaTemp.bladeCooldown and rage >= 36
     and gmcp.Room.Info.area ~= "the Fathomless Expanse of the World Tree" then
    return "reap "..target..sp
  end
  ataxiaTemp.psionBrAt = ataxiaTemp.psionBrAt or {}
  for _, ab in ipairs(PSION_BR) do
    if (not ab.optIn or ataxiaBasher.psionRegrowth) and rage >= ab.rage
       and (nowT - (tonumber(ataxiaTemp.psionBrAt[ab.key]) or 0)) >= ab.cd then
      ataxiaTemp.psionBrAt[ab.key] = nowT
      ataxiaTemp.psionBrPending = { verb = ab.cmd, at = nowT }
      return ab.cmd.." "..target..sp
    end
  end
  return ""
end

function ataxiaBasher_psionBashing()
  local command, sp = "", ataxia.settings.separator
  -- NOTE: the battlerage is computed LAZILY below, after the shielded early-return
  -- (v4.7.129 review): psionBattlerage stamps cooldowns when it picks, and the
  -- shielded branch emits no battlerage -- an eager call there burned the pick's
  -- cooldown stamp unsent every shielded round.

  -- Panoply boon (Mnemosyne, legendary): "The damage dealt by your weaving flurry
  -- ability scales directly to the number of strikes landed, randomly dealing 60% to
  -- 200% of its damage with each attack." AB Flurry (ID 2704): WEAVE FLURRY <target>,
  -- works on denizens, 2.60s of balance. With the boon up it out-damages the deathblow
  -- bash, so it becomes the primary (user-directed). Straight verb swap mirroring
  -- bmShatteredStar; psi shatter keeps its transcendence slot.
  local weave = psionPanoply and ("weave flurry "..target) or ("weave deathblow "..target)

  -- EQ riders (equilibrium is idle while weaves spend balance -- the Kai Choke lesson):
  -- Roth is the sub-50% emergency heal (AB: 1.30s eq, 3-min cooldown, grants clarity +
  -- rupture free) -- it belongs BEFORE any shield/flee response fires.
  ataxiaTemp.psionRothAt = ataxiaTemp.psionRothAt or 0
  local nowT = (getEpoch and getEpoch()) or os.time()
  if (tonumber(ataxia.vitals.hpp) or 100) < 50
     and (nowT - (tonumber(ataxiaTemp.psionRothAt) or 0)) >= 185 then
    ataxiaTemp.psionRothAt = nowT
    command = command.."enact roth"..sp
  end
  -- Transcendence keeper: the shatter loop assumes PSI TRANSCEND is active, but
  -- nothing ever re-upped it after a drop/death. The psitranscend defence is
  -- GMCP-tracked; re-up on eq (rides the swing) with a 10s attempt-hold.
  if not (ataxia.defences and ataxia.defences.psitranscend)
     and not ataxiaTemp.psionTranscendAttempted then
    ataxiaTemp.psionTranscendAttempted = true
    tempTimer(10, [[ataxiaTemp.psionTranscendAttempted = nil]])
    command = command.."psi transcend"..sp
  end

  if ataxiaBasher.shielded then
    -- Review fix: this branch could build an EMPTY command (no cleave fallback
    -- without rageraze) or DOUBLE-break (pulverise + cleave, wasting the balance).
    -- Pulverise breaks on RAGE -- no balance -- so pair it with the damage weave in
    -- the same round; otherwise cleave (balance) is the always-available breaker.
    if ataxiaBasher.rageraze and (tonumber(ataxia.vitals.rage) or 0) >= 17 then
      command = command.."weave pulverise "..target..sp..weave
    else
      command = command.."weave cleave "..target
    end
    return command
  end

  -- Battlerage only from here down -- every remaining branch sends it, so the pick's
  -- cooldown stamp can no longer burn unsent.
  local brage = ataxiaBasher_psionBattlerage(sp)

  -- Secondskin keeper: resistance to ALL damage types; it drops rarely, so spending
  -- one round's balance re-weaving it (3.00s bal -- it REPLACES the swing) is cheap
  -- insurance. Skipped on shielded rounds above (break the shield first).
  if not (ataxia.defences and ataxia.defences.secondskin)
     and not ataxiaTemp.psionSecondskinAttempted then
    ataxiaTemp.psionSecondskinAttempted = true
    tempTimer(10, [[ataxiaTemp.psionSecondskinAttempted = nil]])
    return command..brage.."weave secondskin"
  end

  if ataxiaTemp.transcendence and ataxiaTemp.transcendence == 100 then
    command = command..brage.."psi shatter "..target..sp..weave
  else
    command = command..brage..weave
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
  
  -- Default was "swiftcure" -- a typo. It never equalled the "swiftcurse" branch below, so the
  -- default bashType silently fell through to jinx/curse and swiftcurse was never actually the
  -- default. Set via `aconfig bashtype <type>` (shaman_system/005).
  if not shaman.spiritlore.bashType then shaman.spiritlore.bashType = "swiftcurse" end
	local bash_type = shaman.spiritlore.bashType

  local atk
  if healhealth < 60 then
    atk = "stand;wield shield;invoke regeneration"
  elseif bash_type == "arius" and shaman.spiritisbound("arius") then
    atk = "invoke roar "..target
  elseif bash_type == "swiftcurse" then
    -- No spirit-binding check: swiftcurse is used regardless of whether aelkesh is bound.
    --
    -- `curseCharge or 0`: it is a plain global with three writers -- shaman/011 (the real
    -- "You weave your fingers together..." line -> 14), shaman/012 (the authoritative "empowered
    -- with another N curses" -> N), and the ataxiaBasher_detectSwiftcurseCharge heuristic
    -- (genrunning/004). None run before the first charge of a session, so it is nil until then,
    -- and a bare `curseCharge <= 1` throws "attempt to compare nil with number", killing the
    -- whole attack. 004:61 already guards it the same way.
    if (curseCharge or 0) <= 1 then
      -- Recharge -- and only ONE at a time. `swiftcursing` is an in-flight guard: shaman/011
      -- ("You weave your fingers together...") and shaman/012 ("empowered with another N
      -- curses") both clear it, but NOTHING ever set it and nothing ever read it, so the guard
      -- was dead. The recharge therefore re-fired on the next prompt before the confirm-line
      -- landed -- weaving twice and paying a balance for each. Set it here (the missing half)
      -- and skip while a weave is outstanding.
      -- Paired with a TIMESTAMP so a swallowed/gagged confirm-line cannot strand the shaman
      -- unable to ever recharge again: after 3s we assume the weave was lost and retry.
      if swiftcursing and getEpoch() < (ataxiaTemp.swiftcurseSentAt or 0) + 3 then
        atk = "" -- weave already in flight; don't buy a second one
      else
        swiftcursing = true
        ataxiaTemp.swiftcurseSentAt = getEpoch()
        atk = "stand;wield shield;swiftcurse"
      end
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
  
	
  -- atk is "" while a swiftcurse weave is in flight -- send the battlerage alone rather than
  -- `brage..sp..""`, which would trail a bare separator onto the queued command.
  if brage == "" or atk == "" then
  		command = (brage ~= "" and brage or atk)

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