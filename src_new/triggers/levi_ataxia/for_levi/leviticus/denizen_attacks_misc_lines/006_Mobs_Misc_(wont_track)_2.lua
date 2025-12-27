--[[mudlet
type: trigger
name: Mobs Misc (wont track) 2
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Basher
- Bashing
- Basher Lines
- Denizen Attacks / Misc Lines
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
- pattern: A rotten hand comes flying towards your head as a shambling zombie rakes you with his razor sharp claws.
  type: 3
- pattern: A shambling zombie clutches his sides and howls in pain.
  type: 3
- pattern: A massive outstretched arm comes crashing towards you as a shambling zombie slams it into you, snapping your bones
    with a crunching sound.
  type: 3
- pattern: With a disgusting squelch, a flesh-eating slug unleashes a massive wave of boiling acid, searing your flesh.
  type: 3
- pattern: A decaying lich conjures a magical ball of energy and with a single motion, sends it flying into your body.
  type: 3
- pattern: A fairy Lady of Sidhe pulls a sharp crystal shard from her hair and punctures you with it.
  type: 3
- pattern: A fairy Lady of Sidhe crafts a globe of flame within her palm and throws it at you. As it explodes on you, serpentine
    ropes of fire snake from it, wrapping around you tightly.
  type: 3
- pattern: A charging Cyclops lopes towards you, ramming into you with enough force to shatter bones.
  type: 3
- pattern: An annoyed look flashes over Rhoswen, a fairy merchant's face as she throws a cloud of iridescent powder over you.
  type: 3
- pattern: With a fearsome neigh, a wild kelpie rears up and stomps two hooves into your head and torso.
  type: 3
- pattern: A wild kelpie tosses his head and opens his mouth, spraying you with a stream of acidic saliva.
  type: 3
- pattern: A lake fairy flutters her wings quickly in the water, creating a geyser which blasts you harshly.
  type: 3
- pattern: A slick-looking selkie swims towards you, ramming his snout-like nose into your stomach.
  type: 3
- pattern: The conch shell around a lake fairy's throat begins to glow, striking you with a blinding and painful light.
  type: 3
- pattern: A fairy Knight of Sidhe whirls his weapon expertly, almost slicing you in half before impaling you upon its razor-sharp
    edge.
  type: 3
- pattern: A Fomori of Unsidhe utters a guttural word, causing gangrenous sores to burst over your flesh.
  type: 3
- pattern: A Fomori of Unsidhe balls a meaty fist up and slams it into your jaw, making your head spin.
  type: 3
- pattern: A Fomori of Unsidhe sinks his rotting teeth into your arm, poisoning you as blood drips from his mouth.
  type: 3
- pattern: The ground swirls around you as Gwyllion, the Swamp Crone calls upon the sprites of the bog. Thick muddy arms wrap
    around you, crushing you tightly.
  type: 3
- pattern: ^A cunning black wolf springs at you with his claws spread, his body slams into you and sends you crashing to the
    ground in a flurry of fur and flashing fangs\.$
  type: 1
- pattern: A crazed kelpie's hooves canter in the air as he sends them crashing into you painfully.
  type: 3
- pattern: A fairy Knight of Sidhe swivels his weapon quickly and slams the edge of it into your solar plexus.
  type: 3
- pattern: A moon bear rears onto his back paws and wraps his arms around you, crushing your face against his chest.
  type: 3
- pattern: Grabbing the whip from his belt, a master mhun miner opens a cut on your arm with a quick lash.
  type: 3
- pattern: Issuing a tiny grunt, a mhun miner gouges into your arm with his mining pick.
  type: 3
- pattern: Slipping behind you deftly, a master mhun miner garrotes you quickly with his crude whip.
  type: 3
- pattern: Issuing a cry to Moghedu, an elite mhun keeper jabs you violently with his rapier.
  type: 3
- pattern: Issuing a tiny grunt, a mhun miner gouges into your arm with his mining pick.
  type: 3
- pattern: Grunting softly, a mhun labourer hacks into you with a mining pick.
  type: 3
- pattern: Wiping a strange liquid on each blade, an elite mhun keeper hacks into you, delivering the venoms.
  type: 3
- pattern: With a downward swing of his arms, a mhun miner hammers your leg with his mining pick.
  type: 3
- pattern: Moving swiftly, a mhun labourer crushes the side of your leg with the side of his pick.
  type: 3
- pattern: A mhun labourer swings into you with one of his mining picks.
  type: 3
- pattern: With a lightning-fast spin, Turan delivers a stunning blow to your temple with the hilt of his scimitar.
  type: 3
]]--

if ataxiaBasher.enabled then
	  haveBeenHit = tempTimer(1, [[ haveBeenHit = nil ]])
		bashConsoleEcho("denizen", "Denizen attacked us!")
		bashStats.mobhits = bashStats.mobhits + 1
	if not ataxiaBasher.manual then
		deleteFull()
	end
end

