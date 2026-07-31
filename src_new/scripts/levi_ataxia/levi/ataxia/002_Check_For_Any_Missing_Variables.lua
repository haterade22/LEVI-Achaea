--[[mudlet
type: script
name: Check For Any Missing Variables
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

function ataxiaCheckForMissing()
	checkedMissingVariables = true
  local sp
	if ataxia then
    if not ataxia.settings.separator or ataxia.settings.separator == "" then
      ataxia.settings.separator = ";"
    end
    sp = ataxia.settings.separator
  end

  -- Older basher saves predate noShieldBreak; ataxiaBasher_canShield() indexes
  -- `.noShieldBreak.mobs` directly, so a missing field spams index errors every prompt.
  if ataxiaBasher and not ataxiaBasher.noShieldBreak then
    ataxiaBasher.noShieldBreak = { mobs = {}, threshold = 0 }
  end

  -- crushbash was only ever written by the `aconfig monk` toggle, so saves from before it
  -- was defaulted have no key at all. `== nil` and not `not ...` — false is a real value here.
  if ataxia.settings.crushbash == nil then
    ataxia.settings.crushbash = false
  end

  -- Monk gap-filler transmute thresholds: fire at/below transmuteat% while sip balance is down,
  -- top back up to transmuteto%. Backfill when absent AND migrate the v4.7.70 defaults --
  -- transmuteat 50 -> 70 (start covering earlier) and transmuteto 70 -> 90 (somewhere worth
  -- going: firing at 70 and topping up to 70 would heal essentially nothing).
  -- Rewriting rather than only backfilling is safe here: `ataxia setup sipping <key> <value>`
  -- is advertised by the wizard but has no setter (the panel is display-only), so a stored
  -- 50/70 can only be the old shipped default — it cannot be a deliberate choice.
  -- Migrate every default this key has shipped with, not just the newest: v4.7.70 shipped
  -- transmuteto = 70 and v4.7.82 migrated it to 90, so a save can legitimately hold either.
  local sip = ataxia.settings.sipping
  if sip then
    if sip.transmuteat == nil or sip.transmuteat == 50 then sip.transmuteat = 70 end
    if sip.transmuteto == nil or sip.transmuteto == 70 or sip.transmuteto == 90 then
      sip.transmuteto = 99
    end
  end

  if not ataxia.settings.defences then
    ataxia.settings.defences = { current = "", defup = {}, keepup = {} }
    ataxiaEcho("Defence profiles not found. Initialised empty profiles.")
    ataxiaEcho("<green>aconfig profile create <name> <NavajoWhite>to create one.")
  end

  if ataxia.settings.highlighting == nil then
    ataxia.settings.highlighting = {}
    ataxiaEcho("Highlight settings not found. Changed to default.")
    ataxiaEcho("See 'item highlighting' alias for more info.")
  end
  
  if ataxia.usegui == nil then
    ataxia.usegui = false
    ataxiaEcho("GUI disabled by default. Only chat, map, and limb counter load.")
  end
  
  if ataxia.settings.goldcommand == nil then
    ataxia.settings.goldcommand = "get gold"..sp.."put gold in pack"
    ataxiaEcho("Gold grabbing command defaulted to: <green>"..ataxia.settings.goldcommand)
    ataxiaEcho("<green>aconfig goldgrab (command)<NavajoWhite> to set it.")
  end
  
	if ataxia.settings.lustlist == nil then
		ataxia.settings.lustlist = {}
		ataxiaEcho("Lust settings not found. Changed to default.")
		ataxiaEcho("<green>lustallow <name><NavajoWhite> to use.")
		ataxiaEcho("Will also remove if they're already on the list.")
		ataxiaEcho("For queueing purposes you can also call ataxia_needReject() to check if you need to reject.")
		ataxiaEcho("If it returns true, ataxiaTemp.reject will be set to the person.")
		ataxiaEcho("<green>lustallow list<NavajoWhite> will show everyone on the list.")
	end
	
	if ataxia.settings.relayingto == nil then
		ataxia.settings.relayingto = false
		ataxiaEcho("Channel relay setting not found, adding it in. Default is faulse.")
		ataxiaEcho("<green>aconfig relay <channel> <NavajoWhite>to change.")
		ataxiaEcho("<green>aconfig relay clt2 <NavajoWhite>for example.")
		ataxiaEcho("'false' or 'off' will disable callouts again.")
	end
	
	if ataxiaBasher.rageraze == nil then
		ataxiaBasher.rageraze = false
		ataxiaEcho("Battlerage razing option not found; defaulting to false.")
		ataxiaEcho("<green>bash rageraze on/off <NavajoWhite>to change.")
	end

	-- Auto-feed from the horn of plenty when a starvation state is seen. Starvation
	-- knocks you UNCONSCIOUS, which disables every other safety in the system, so this
	-- defaults ON; `horn off` to disable.
	if ataxia.settings.hornAuto == nil then ataxia.settings.hornAuto = true end

	-- Depthswalker PvE options (v4.7.142). Boinad spends 32 rage AND the shared word
	-- balance for a 5s charm, so it is opt-in; cull-vs-reap is unmeasured (see the class
	-- doc A/B note), so the fast swing stays default; the Terminus buff keepers are on.
	if ataxiaBasher.dwBoinad == nil then ataxiaBasher.dwBoinad = false end
	if ataxiaBasher.dwCull == nil then ataxiaBasher.dwCull = false end
	if ataxiaBasher.dwKeepers == nil then ataxiaBasher.dwKeepers = true end
	-- Age ceiling for chrono re-ups paid in age (Flashforward's chrono blur). 400 is the
	-- yellow/orange boundary in getAgeColour -- bashing must not price out the PvP kit.
	if ataxiaBasher.dwAgeCap == nil then ataxiaBasher.dwAgeCap = 400 end

	if ataxiaBasher.dragonBlast == nil then
		ataxiaBasher.dragonBlast = true
		ataxiaEcho("Dragon blast-weave option not found; defaulting to on.")
		ataxiaEcho("<green>bash blast on/off <NavajoWhite>to change.")
	end

	if ataxiaBasher.autoLearn == nil then
		ataxiaBasher.autoLearn = true
		ataxiaEcho("Auto-learn denizens option not found; defaulting to on.")
		ataxiaEcho("<green>ataxia setup basher autolearn on/off <NavajoWhite>to change.")
	end

	-- No-flee flag for the Mnemosyne tower climb (set/cleared by its SURVEY trigger
	-- and ataxia_Room_Update). Default off; nil is already falsy but init for hygiene.
	if ataxiaBasher.inMnemosyne == nil then
		ataxiaBasher.inMnemosyne = false
	end

	-- "Our" denizens: pet/ally/summon name keywords (case-insensitive substrings) that
	-- are never auto-learned or targeted by the basher. Manage with 'bash mine'.
	-- Denizens worth spending an Inhibit on (name substrings). Inhibit stops a denizen healing,
	-- so it is dead rage against anything that never heals -- the Mnemosyne "Sanguine
	-- Restoration" affix is handled separately and needs no list. Empty by default; add with
	-- Lua until there is an alias. Read by ataxiaBasher_monkBattlerage.
	if ataxiaBasher.healerDenizens == nil then
		ataxiaBasher.healerDenizens = {}
	end

	if ataxiaBasher.ownDenizens == nil then
		ataxiaBasher.ownDenizens = {"falcon", "baalzadeen", "ashbeast", "hyena"}
		ataxiaEcho("Own-denizen ignore list not found; seeded with <white>falcon<NavajoWhite>, <white>baalzadeen<NavajoWhite>, <white>ashbeast<NavajoWhite>, <white>hyena<NavajoWhite>.")
		ataxiaEcho("<green>bash mine <NavajoWhite>to view/add/remove your own denizens.")
	end

	-- Backfill pets that appear in "Denizens Here" and must never be attacked or
	-- auto-learned. New entries land here because existing saves keep the old default:
	--   ashbeast -- the Magi Artificing summon ("a blazing ashbeast")
	--   hyena    -- the Infernal pet ("a daemonic hyena"). It was being TARGETED (seen
	--              live at 4% health on the mob bar), and a mauled pet turns on its
	--              owner: "A daemonic hyena snarls as she hurls herself at you...".
	for _, pet in ipairs({"ashbeast", "hyena"}) do
		if ataxiaBasher.ownDenizens and not table.contains(ataxiaBasher.ownDenizens, pet) then
			table.insert(ataxiaBasher.ownDenizens, pet)
		end
	end

	-- MOUNTS (user's own, 2026-07-31). Mounts share the room's creature list exactly like
	-- pets do, so the basher would happily target one.
	--
	-- Keywords are the FULL descriptive name, never the bare creature noun -- deliberately.
	-- The match is a case-insensitive SUBSTRING, so "bear"/"wolf"/"worm"/"elephant" would
	-- shadow half the bestiary and (per the slope-backed-hyena lesson below) the sweep would
	-- silently walk out of rooms holding them. "lean grizzly bear" is narrow enough that only
	-- a denizen sharing the whole phrase collides.
	--
	-- If a real denizen ever does match one of these, exempt it with `bash notmine add <name>`
	-- rather than loosening the keyword.
	for _, mount in ipairs({
		"black dardanic stallion",
		"lean grizzly bear",
		"war elephant",
		"massive dire wolf",
		"withered crypt worm",
	}) do
		if ataxiaBasher.ownDenizens and not table.contains(ataxiaBasher.ownDenizens, mount) then
			table.insert(ataxiaBasher.ownDenizens, mount)
			ataxiaEcho("Mount <white>" .. mount .. "<NavajoWhite> added to your own denizens -- never targeted.")
		end
	end

	-- ...and the INVERSE list. The own-denizen match is a case-insensitive SUBSTRING,
	-- which is what makes "falcon" cover "a razor-beaked falcon" -- but it also means a
	-- real denizen sharing a word with a pet is silently shielded. "a slope-backed
	-- hyena" (user report 2026-07-30) is a genuine, killable mob that the "hyena"
	-- keyword protected from targeting AND purged from the learned target list. In the
	-- Mnemosyne the sweep then WALKS OUT of the room -- _roomHasDenizens filters own
	-- denizens, so a room holding only the shadowed mob reads as clear -- leaving a live
	-- aggressive denizen following us. (v4.7.169 called this a stall; corrected v4.7.170.)
	-- Entries here WIN over the pet
	-- keywords; manage with `bash notmine`. Backfilled (not just defaulted) because
	-- existing saves already carry the bare "hyena" keyword.
	ataxiaBasher.notOwnDenizens = ataxiaBasher.notOwnDenizens or {}
	for _, real in ipairs({"a slope-backed hyena"}) do
		if not table.contains(ataxiaBasher.notOwnDenizens, real) then
			table.insert(ataxiaBasher.notOwnDenizens, real)
			ataxiaEcho("<white>" .. real .. "<NavajoWhite> is a REAL denizen -- exempted from your pet keywords "
				.. "(<green>bash notmine<NavajoWhite> to manage).")
		end
	end

	if ataxia.prioritySwaps and ataxia.prioritySwaps.ravaged == nil then
		ataxia.prioritySwaps.ravaged = {active = false, desc = "Automatically prio mana sipping while ravagedmind is active."}
		ataxiaEcho("Ravagedmind priority swap not found. Added it to swaps; default is off.")
	end
	
  if ataxia.prioritySwaps and ataxia.prioritySwaps.psionBleed == nil then
		ataxia.prioritySwaps.psionBleed = {active = false, desc = "Automatic prio on haemophilia once bleed is stacked."}
		ataxiaEcho("Psionbleed priority swap not found. Added it to swaps; default is off.")  
  end
  
  if ataxia.prioritySwaps and ataxia.prioritySwaps.parshield == nil then
    ataxia.prioritySwaps.parshield = {active = false, desc = "Temporarily ignore paralysis on shielding."}
    ataxiaEcho("Parshield priority swap not found. Added it to swaps; default is off.")
  end
  
	if ataxia.prioritySwaps and ataxia.prioritySwaps.magi == nil then
		ataxia.prioritySwaps.magi = {active = false, desc = "Automatic handling for burns and frozen status."}
		ataxiaEcho("Magi priority swap not found. Added it to swaps; default is off.")
	end
	
	if not ataxia.settings.roomshorten then
		ataxiaEcho("Room condense setting not found. Defaulting to normal; see changelog for information.")
		ataxia.settings.roomshorten = "normal"
	end
	
	if ataxiaBasher.treeblackout == nil then
		ataxiaBasher.treeblackout = true
		ataxiaEcho("Bashing Tree Setting not found: Reverting to default; won't use tree when blacked out while bashing.")
		cecho("\n     <NavajoWhite>aconfig treeblackout <NavajoWhite> to toggle.")
	end
	
	if ataxia.settings.autogallop == nil then
		ataxia.settings.autogallop = false
		ataxiaEcho("Auto Gallop Setting not found: Reverting to default; won't toggle gallop when mounted.")
		cecho("\n     <NavajoWhite>aconfig gallop <on/off> to toggle.")
	end
	
	if not ataxia.sylvanStuff then
		ataxia.sylvanStuff = {propagateList = {arms = false, legs = false, head = false, body = false}}
		ataxiaEcho("Sylvan stuff defaulted to normal values. Check <red>aconfig sylvan help<Navajowhite> for info.")
		ataxiaEcho("If you're not a Sylvan then ignore this.")
	end

	-- Initialise user config (weapons, mount, artefacts, earrings)
	if ataxia_initUserConfig then
		ataxia_initUserConfig()
	end
	end
