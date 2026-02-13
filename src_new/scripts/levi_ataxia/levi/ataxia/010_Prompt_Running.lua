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
	if ataxiaBasher and ataxiaBasher.enabled and bashStats and bashStats.lastBalanceDamage and bashStats.lastBalanceDamage > 0 then
		local sDPS, bDPS = bashStats_getDPS()
		cecho("\n <DimGrey>[<cyan>DPS<DimGrey>] <white>"..bDPS.."/s <DimGrey>bal <white>| <yellow>"..sDPS.."/s <DimGrey>avg <white>| <green>"..bashStats.totalDamage.." <DimGrey>total")
	end
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
    
    if need_roomCheck then
      ataxiaBasher_scanRoom()
    end
  
if ataxia.vitals.hp >= ataxia.vitals.maxhp and ataxiaTemp.bashFlee == true or ataxiaBasher.paused == true and guardianofmogcunts == false then
			  ataxiaTemp.bashFlee = false
        ataxiaBasher.paused = false
			  search_targets()
end
  
  if ataxia.vitals.wpp <= 5 then
    if ataxiaBasher.dragonIncant == true then
      ataxiaBasher.jabBash = true
      ataxiaBasher.dragonIncant = false
    end
  end
  
    if basher_needAction and found_target and not ataxiaBasher_skipRoom then
      basher_needAction = false
      if gmcp.Char.Status.class == "Magi" then
        ataxiaBasher_magiBashing()
        ataxiaBasher_attack()
      else
      ataxiaBasher_attack()
      end
      
    end
    
		disableTrigger("Denizen Attack Find")
		ataxiaBasher_atk = false
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