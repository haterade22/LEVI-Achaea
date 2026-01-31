--[[mudlet
type: trigger
name: Our Attacks
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
- pattern: ^Stepping forward, you drive the end of (.+) into the (.+) of (.+).$
  type: 1
- pattern: ^You drive your foot up in a rising kick at the head of (.+).$
  type: 1
- pattern: ^Continuing your kata, you spin (.+) in your hands and drive it in a sharp thrust towards the head of (.+).$
  type: 1
- pattern: ^You reach out and clench a fist before (.+), who screams and doubles over in agony as \w+ skin suddenly bubbles
    with gangrenous growths.$
  type: 1
- pattern: ^You rip into (.+) with your massive, deadly claws.$
  type: 1
- pattern: ^Lightning-quick, you jab (.+) with (.+).$
  type: 1
- pattern: ^You viciously jab (.+) into (.+).$
  type: 1
- pattern: The songblessing upon the rapier sings out with a piercing high note.
  type: 3
- pattern: ^You unleash a vicious reaping blow at (.+) with (.+).$
  type: 1
- pattern: ^You point (.+) at (.+) and \w+ screams in pain as \w+ skin begins to freeze and crack.$
  type: 1
- pattern: ^You swing .+ at .+ with all your might.$
  type: 1
- pattern: ^You slash into .+ with .+.$
  type: 1
- pattern: ^You brutally smash your shield into (.+).$
  type: 1
- pattern: ^You slice into (.+).$
  type: 1
- pattern: ^A terrible cold fills your chest, constricting your lungs. Your mouth falls open and an unearthly, terrible roar
    emanates forth at (.+).$
  type: 1
- pattern: ^You conjure a blade of ice and send it to lacerate the flesh of (.+).$
  type: 1
- pattern: ^You slip behind (.+) and garrote \w+ with your whip.$
  type: 1
- pattern: ^Directing the energy of iron, you engulf .+'s body with ashen flames, which burn \w+ skin with their frigid touch.$
  type: 1
- pattern: Drawing upon the latent alchemical energies,
  type: 2
- pattern: You deftly thrust
  type: 2
- pattern: Stepping forward, you continue the motion of your initial thrust, performing a second quick jab
  type: 2
- pattern: ^With expert precision, you draw .+ from its scabbard and unleash a vicious slash towards (.+).$
  type: 1
- pattern: ^Charging forward, you drive a translucent spear into (.+).$
  type: 1
- pattern: 'You violently buffet '
  type: 2
- pattern: The wind rises again
  type: 2
- pattern: ^With a curt gesture you summon a whip of condensed air to lash the flesh of (.+).$
  type: 1
- pattern: ^You (.+) with your blackjack.$
  type: 1
- pattern: ^Drawing back .+, you unleash a flesh-mincing blow at (.+).$
  type: 1
- pattern: ^Continuing your assault, you whip .+ in a vicious rising slash at (.+).$
  type: 1
- pattern: ^You utter a prayer and smite (.+) with (.+).$
  type: 1
- pattern: ^Striking like coiled lightning, your hand flashes out and lays open the throat of (.+) with a translucent dagger
    in a spray of crimson.$
  type: 1
- pattern: ^You reach out with grim intent, seeking to shatter the psyche of (.+).$
  type: 1
- pattern: ^You stare at .+, giving \w+ the evil eye. Blood begins to flow from \w+ pores.$
  type: 1
- pattern: ^You whip .+ towards? (.+).$
  type: 1
- pattern: ^A whip of liquid flame coalesces in your hand, and with a savage lash you send it to scourge the flesh of (.+).$
  type: 1
- pattern: ^You snap your wrist, sending the tip of .+ to scourge (.+).$
  type: 1
- pattern: ^You lash out at (.+) with .+\, flaying \w+ flesh.$
  type: 1
- pattern: ^You reach out with your mind, tightening its grip around (.+) to crush the life out of \w+.$
  type: 1
- pattern: ^You pump out at (.+) with a powerful side kick.$
  type: 1
- pattern: ^You launch a powerful uppercut at (.+).$
  type: 1
- pattern: Your knife moves in perfect harmony with your mind
  type: 2
- pattern: ^A violent cracking sound from the air in front of (.+) heralds \w+ magical shield exploding into a shower of translucent
    shards.$
  type: 1
- pattern: ^You rain a flurry of blows down upon (.+) with your stone fists.$
  type: 1
- pattern: ^Drawing from the well of your puissance, you invoke a dramatic chant in the dragon tongue. Your voice resonates
    with each word, culminating in a wave of magical energy that you bend to your will and thrust towards (.+), bombarding
    \w+ with the ancient power.$
  type: 1
- pattern: ^As you point a primordial staff at (.+), a scintilla of bright, burning light shoots out, striking \w+ with focused
    elemental power\.$
  type: 1
- pattern: ^You form a lash of fire, and send it to scorch the flesh of (.+)\.$
  type: 1
- pattern: ^Whirling .+ in a tight arc, you bring the weapon around to crash into the side of the head of (.+)\.$
  type: 1
- pattern: ^You lash out with a straight kick at the \w+ shoulder of (.+)\.$
  type: 1
- pattern: ^Lunging forward, you drive the end of .+ viciously into the solar plexus of (.+)\.$
  type: 1
- pattern: ^Snapping your leg out to its full extent, you drive a heel into the \w+ knee of (.+)\.$
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

