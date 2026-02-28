--[[mudlet
type: script
name: Prompt Running
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

function ataxia_promptCommands()
	if not gmcp then return end
	if not gmcp.Char then return end
	if not checkedMissingVariables then
		ataxiaCheckForMissing()
	end
	ataxiaTemp.lokiCheck = false
	if not noPromptEcho then
		ataxiaPromptSub()
		
		--defunct function, keeping it for review purposes only
		--ataxia_promptEcho()
	end
	noPromptEcho = false
  if ataxiaTemp.alertness then
    alertnessDisplay()
  end
	if ataxia_isClass("monk") then
		disableTrigger("Tekura Limbs")
	end

	if ataxia.settings.use.parry and ataxia.parrying and ataxia.parry ~= "manual" then
		ataxia_parryCheck()
		if canParry() and ataxia.parrying.shouldparry ~= ataxia.parrying.limb and not parryAttempted then
      if ataxia_isClass("monk") and gmcp.Char.Vitals.charstats[3] == "Tekura" then
        send("guard "..ataxia.parrying.shouldparry)
      else
			 send("parry "..ataxia.parrying.shouldparry)
      end
			parryAttempted = true
			tempTimer(3, [[parryAttempted = false]])
		end
	end

	if ataxia_isClass("bard") and ataxiaTemp.needSymphony and ataxia.bardStuff.symphony and canBals() and bardHarmsInRoom and not ataxiaTemp.symphAttempted then
		ataxiaTemp.symphAttempted = true
		tempTimer(2, [[ataxiaTemp.symphAttempted = nil]])
		send("queue addclear freestand wield "..ataxia.bardStuff.instrument.." shield"..ataxia.settings.separator.."play symphony")
	end

if ataxiaBasher.enabled then

    -- Room scan on room change
    if need_roomCheck then
      ataxiaBasher_scanRoom()
    end

    -- Re-evaluate targets every prompt. GMCP fires before text, so
    -- ataxia.denizensHere is already up-to-date by the time we get here.
    -- Without this, killing the last mob leaves found_target stale (true)
    -- because the debounced "targets updated" event fires NEXT cycle.
    search_targets()

    -- Flee recovery check (percentage-based, replaces buggy operator-precedence line)
    ataxiaBasher_checkFleeRecovery()

    -- Willpower-based dragon incant toggle
    if ataxia.vitals.wpp and ataxia.vitals.wpp <= 5 then
      if ataxiaBasher.dragonIncant == true then
        ataxiaBasher.jabBash = true
        ataxiaBasher.dragonIncant = false
      end
    end

    -- SINGLE attack dispatch — no basher_needAction, no atk flag reset
    disableTrigger("Denizen Attack Find")
    ataxiaBasher_patterns()
  end
	ataxia_precacheQueue()
end


function ataxia_promptEcho()

	if not ataxia.settings.prompt then return end

	if ataxia.settings.prompt.xp then
		cecho(" <green>(<a_cyan>"..gmcp.Char.Vitals.nl.."%<green>)")
	end

	if ataxia.settings.prompt.timestamps then
		local timestamp = tostring(getTime(true,"hh:mm:ss:zzz"))
		cecho(" <dim_grey>" ..timestamp)
	end
	
	if ataxia.fishing and ataxia.fishing.enabled then
		cecho(" <orange>[<NavajoWhite>"..linelength.." ft<orange>]")
	end
	
	if ataxia_isClass("magi") or ataxia_isClass("bard") then
		limbCounter_promptAddon()
	end
	
	if ataxia.settings.prompt.affs then		
		ataxia_promptAffs()
	end
end