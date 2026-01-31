ataxiaBasher.shielded = false
ataxiaTemp.ignoreCrits = false

if not matches[1]:find("latent alchemical") then
	bashStats.attacks = bashStats.attacks + 1
end

if matches[1]:find("shatter the psyche") then
	ataxiaTemp.transcendence = 0
end

if type(target) == "number" and ataxiaBasher.enabled then
	if not bashAttackSub then
    if zgui then
      cecho("bashDisplay","\n<red>ATK| <NavajoWhite>We smacked "..target.."!")
    else 
		  ataxiagui.bashConsole:cecho("\n<red>ATK| <NavajoWhite>We smacked "..target.."!")
    end
		if gmcp.IRE.Target and gmcp.IRE.Target.Info and gmcp.IRE.Target.Info.hpperc ~= "-1" then
			if ataxiaTemp.mobhealth ~= 0 then
        if zgui then
          cecho("bashDisplay", " <green>(<tomato>"..gmcp.IRE.Target.Info.hpperc.."<green>)")
        else
				  ataxiagui.bashConsole:cecho(" <green>(<tomato>"..gmcp.IRE.Target.Info.hpperc.."<green>)")
        end
			end
		end			
		bashAttackSub = tempTimer(1, [[ bashAttackSub = nil ]])
	end
	if not ataxiaBasher.manual then
		deleteFull()
	end
	
	if found_target and not ataxiaBasher_atk then
		--ataxiaBasher_attack()
   
    basher_needAction = true
		ataxiaBasher_atk = true
		tempTimer(0.7, [[ataxiaBasher_atk=false]])
    
    if ataxia_isClass("Monk") then
      tempTimer(1.5, [[ if found_target and not ataxiaBasher_skipRoom then
        basher_needAction = false
        ataxiaBasher_attack()
      end
      ]])
    end
    
	end
end

