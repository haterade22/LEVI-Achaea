-- Needs its own specific line.
ataxiaTemp.ignoreCrits = false

if not matches[1]:find("malign power") then
	bashStats.attacks = bashStats.attacks + 1
end

if type(target) == "number" and ataxiaBasher.enabled then
	if not bashAttackSub then
    if zgui then
      cecho("bashDisplay", "\n<red>ATK| <NavajoWhite>We smacked "..target.."!")
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
	
	if found_target then
		--ataxiaBasher_attack()
    basher_needAction = true
	end
end

