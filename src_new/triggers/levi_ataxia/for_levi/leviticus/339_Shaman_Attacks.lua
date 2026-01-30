--[[mudlet
type: trigger
name: Shaman Attacks
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Basher
- Bashing
- Basher Lines
attributes:
  isActive: 'yes'
  isFolder: 'no'
  isTempTrigger: 'no'
  isMultiline: 'no'
  isPerlSlashGOption: 'no'
  isColorizerTrigger: 'no'
  isFilterTrigger: 'no'
  isSoundTrigger: 'no'
  isColorTrigger: 'no'
  isColorTriggerFg: 'no'
  isColorTriggerBg: 'no'
triggerType: 0
conditonLineDelta: 0
mStayOpen: 0
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ^Summoning your malign power, you direct a twin assault of the curses bleed and bleed at (.+).$
  type: 1
- pattern: ^You point an imperious finger at (.+) and blood begins to flow from (\w+) pores.$
  type: 1
]]--

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

