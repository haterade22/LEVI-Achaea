--[[mudlet
type: trigger
name: Our Attacks 2
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
- pattern: ^Snapping back into a ready stance, you whirl .+ in a long sweep at the head of (.+)\.$
  type: 1
- pattern: ^You whip .+ at (.+) in a controlled arc, bringing its length to crack against \w+ torso\.$
  type: 1
- pattern: ^Falling back into a low crouch, you lash out with a swift strike at the left thigh of (.+)\.$
  type: 1
- pattern: ^You whip .+ at the side of (.+)'s neck\.$
  type: 1
- pattern: ^Turning with the motion, you channel the momentum of your previous strike into a thrust at the solar plexus of
    (.+) with .+\.$
  type: 1
- pattern: ^Bracing your back foot, you lunge forward with .+ at the face of (.+)\.$
  type: 1
- pattern: ^You skilfully whirl .+ toward (.+), slamming the balls of metal into \w+\.$
  type: 1
- pattern: ^You dart out .+ in a lightning-fast jab to the \w+ of (.+)\.$
  type: 1
- pattern: ^Lashing out with a clenched fist, you aim a precise strike at (.+)\.$
  type: 1
- pattern: ^Flames engulf (.+), scorching \w+ in a fiery blaze\.$
  type: 1
- pattern: ^Your gear enhances your strike with additional fire damage\.$
  type: 1
- pattern: ^Drawing from the well of your puissance, you invoke a dramatic chant in the dragon tongue. Yourvoice resonates
    with each word, culminating in a wave of magical energy that you bend to your will and thrust towards (.+), bombarding
    it with the ancient power.$
  type: 1
- pattern: ^Opening your massive maw, you throw your head forward and blast wave after wave of deadly, all-consuming cold
    at (.+)\.$
  type: 1
- pattern: ^You form small chunks of ice in your enormous maw, then spit them at (.+) in abarrage\.$
  type: 1
- pattern: ^You let loose a steady stream of cold air around (.+), who begins to shiveruncontrollably\.$
  type: 1
- pattern: ^You rear back your head, and with a keening roar unleash incandescent hell upon (.+)\.$
  type: 1
- pattern: ^(.+) writhes in agony as acidic spittle eats away at its skin\.$
  type: 1
]]--

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

