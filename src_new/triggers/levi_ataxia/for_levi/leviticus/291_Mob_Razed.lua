--[[mudlet
type: trigger
name: Mob Razed
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
- pattern: ^Bracing your feet, you drive .+ towards (.+).$
  type: 1
- pattern: The end of your staff smashes the magical shield surrounding
  type: 2
- pattern: ^Your cantata shatters the magical shield surrounding (.+).$
  type: 1
- pattern: ^You cast a spell of erosion at (.+).$
  type: 1
- pattern: ^(\w+) shield defence is eroded away.$
  type: 1
- pattern: ^(.+) has no more defences.$
  type: 1
- pattern: ^You raze .+'s magical shield with .+.$
  type: 1
- pattern: ^You whip .+ through the air in front of .+, to no effect.$
  type: 1
- pattern: ^You flick your tail at .+, dismissively brushing aside the paltry shield protecting \w+.$
  type: 1
- pattern: ^Opening your massive maw, you throw your head forward and blast wave after wave of deadly, all-consuming cold
    at (.+).$
  type: 1
- pattern: ^You prepare yourself to flick your tail at .+ before realising that doing so would not actually do anything.$
  type: 1
- pattern: ^You try to flay a non-existent shield from (.+).$
  type: 1
- pattern: ^You conjure a blade of ice and drive it straight through the magical shield surrounding (.+), causing it to explode
    in a shower of prismatic shards.$
  type: 1
- pattern: ^You flay away (.+)'s shield defence.$
  type: 1
- pattern: ^Directing the energy of copper, you send myriad russet streams towards .+, shattering \w+ shield.$
  type: 1
- pattern: ^Directing the energy of copper, you send myriad russet streams towards .+, which whip around \w+ ineffectually.$
  type: 1
- pattern: ^Opening your great maw, you unleash an overpowering blast of flesh\-searing lightning at (.+), whose body goes
    rigid as \w+ screams in agony.$
  type: 1
- pattern: ^Opening your maw, you force out a tremendous stream of acid, blasting the flesh from the very bones of (.+).$
  type: 1
- pattern: You weave a translucent battleaxe into being, its ethereal form firming to corporiality in your hands.
  type: 3
- pattern: 'You whip up a gale, '
  type: 2
- pattern: ^(.+) slaps you on the cheek.$
  type: 1
- pattern: ^You lunge toward (.+) with .+, but finding no resistance, you stumble hopelessly off balance.$
  type: 1
- pattern: ^Lunging forward, you bring .+ down in a savage diagonal blow, carving through (.+).$
  type: 1
- pattern: ^Your rage is wasted as (.+) is not protected by a shield.$
  type: 1
- pattern: ^Your blow cleaves through the magical shield surrounding (.+), continuing on to drive \w+ from \w+ feet.$
  type: 1
- pattern: ^Your blow scythes through the air in front of (.+), missing entirely.$
  type: 1
- pattern: ^You bring a translucent battleaxe in a powerful overhead blow down upon (.+).$
  type: 1
- pattern: ^The protective shield surrounding (.+) is blown away by the gale-force winds.$
  type: 1
- pattern: ^You strike at .+'s translucent shield with .+, drawing the outline of a rough rune that detonates, consuming the
    shield.$
  type: 1
- pattern: ^Raising a hand, you send forth thin wires of flame, their searing filaments tearing through the magical shield
    surrounding (.+).$
  type: 1
- pattern: ^You superheat the air surrounding (.+), \w+  magical shield shattering under the onslaught and \w+ skin catching
    aflame.
  type: 1
- pattern: ^You focus your rage in a single powerful sidekick, shattering (.+)'s translucent shield.$
  type: 1
- pattern: ^There is a sharp cracking sound from the air directly in front of (.+)\, but nothing else seems to happen.$
  type: 1
- pattern: ^You weave a great warhammer into being and with an overhand swing obliterate the magical shield surrounding (.+)\.$
  type: 1
- pattern: ^You bring a magma-wreathed fist around, pulverising the magical shield surrounding (.+) with a single blow.$
  type: 1
- pattern: ^You deliver a single, powerful blow against the magical shield surrounding (.+), fracturing it\.$
  type: 1
- pattern: ^You lurch forward at (.+), swinging .+ in a wildly innacurate blow\.$
  type: 1
- pattern: ^Planting your feet, you whirl .+ over your head before bringing it down with terrible force upon (.+), shattering
    \w+ magical shield\.$
  type: 1
- pattern: ^Continuing your onslaught, you bring (.+) back around to deliver a brutal two-handed blow against (.+)\.$
  type: 1
- pattern: ^You try to flay a non-existent shield from (.+)\.$
  type: 1
- pattern: ^You flay away (.+)'s shield defence.
  type: 1
- pattern: ^Your erode spell fails to strip (.+) of anything\.$
  type: 1
- pattern: Your kick scythes through nothing, hitting only empty air.
  type: 3
- pattern: ^As your kick strikes the magical shield surrounding (.+), it bursts into shimmering fragments\.$
  type: 1
- pattern: ^Your nomos wails discordantly as it finds nothing surrounding (.+) to destroy\.$
  type: 1
- pattern: ^Your nomos sings out as it shatters the magical shield surrounding (.+)\.$
  type: 1
- pattern: ^You wreathe your hand in black lightning, unleashing a savage, backhanded blow that shatters the magical shield
    around (.+)\.$
  type: 1
- pattern: ^The magical shield surrounding (.+) fades away\.$
  type: 1
]]--

ataxiaBasher.shielded = false
ataxiaTemp.ignoreCrits = true

if type(target) == "number" and ataxiaBasher.enabled then
	if not bashRazeSub then
		--ataxiaBasher_attack()
    basher_needAction = true 
		bashConsoleEcho("attack", "Razed that dirty bitch!")		
		bashRazeSub = tempTimer(1, [[ bashRazeSub = nil ]])
	else
		if not ataxiaBasher.manual then
			deleteFull()
		end
	end
else
	erAff("rebounding")
	if removeAffV3 then removeAffV3("rebounding") end
	erAff("shield")
	if removeAffV3 then removeAffV3("shield") end
end




                                                
