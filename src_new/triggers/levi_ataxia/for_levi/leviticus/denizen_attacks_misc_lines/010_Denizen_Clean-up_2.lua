--[[mudlet
type: trigger
name: Denizen Clean-up 2
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
- pattern: A cunning black wolf narrows his eyes before thrusting his head back and unleashing a blood-curdling howl.
  type: 3
- pattern: Throwing back his head, a swamp dweller screams agonisingly.
  type: 3
- pattern: Pain and confusion consumes you as Balorr, Chieftain of the Fomori opens his eye, his focused stare making your
    mind reel.
  type: 3
- pattern: A Fomori of Unsidhe sinks his rotting teeth into your arm, poisoning you as blood drips from his mouth.
  type: 3
- pattern: A Fomori of Unsidhe balls a meaty fist up and slams it into your jaw, making your head spin.
  type: 3
- pattern: Rhuzios, the Mummy Lord batters you with the jerking movements of his linen-clad arms.
  type: 3
- pattern: Your balance is upset as the horrific gaze of Rhuzios, the Mummy Lord startles you.
  type: 3
- pattern: Your equilibrium is upset as the horrific gaze of Rhuzios, the Mummy Lord startles you.
  type: 3
- pattern: A look of anger vibrates Rhoswen, a fairy merchant's wings as she digs her knees into the flanks of her gryphon.
  type: 3
- pattern: ^A cunning black wolf narrows his eyes before thrusting his head back and unleashing a blood-curdling howl\.$
  type: 1
- pattern: Throwing back his head, a slick-looking selkie screams agonisingly.
  type: 3
- pattern: Throwing back his head, a swamp dweller screams agonisingly.
  type: 3
- pattern: A cunning black wolf narrows
  type: 2
- pattern: The torso of a greater water elemental bursts open to reveal several vicious piranhas, flying at you with jaws
    open to bite and tear with vicious abandon.
  type: 3
- pattern: A greater water elemental rears back and slams into you with its massive frozen fists.
  type: 3
- pattern: Raising its arm towards you, a greater water elemental sends a torrent of freezing water to batter your body.
  type: 3
- pattern: A greater water elemental rears back and slams into you with its massive frozen fists.
  type: 3
- pattern: A greater earth elemental extends one arm towards you as a mass of writhing vines surge forward, slicing into you
    with thorns dripping with violet toxins.
  type: 3
- pattern: A greater earth elemental breaks a large chunk away from its rocky form and hurls it at you, the projectile connecting
    with stunning force.
  type: 3
- pattern: A lesser earth elemental sweeps at you in a low, heavy arc, dealing a damaging blow to your legs.
  type: 3
- pattern: As a greater earth elemental wraps a massive hand around your torso and squeezes you tightly, you feel it draining
    away your will to live.
  type: 3
- pattern: As a lesser fire elemental flares brightly, the area is blanketed with a thick cloud of ash andsmoke, making it
    hard to breathe and causing your eyes to water.
  type: 3
- pattern: Maw agape, a lesser fire elemental lets out a fierce roar, sending a scorching gout of fire andmagma to sear your
    flesh.
  type: 3
- pattern: A lesser fire elemental swipes at you viciously, burning and cutting deep gashes across your torso.
  type: 3
- pattern: A greater fire elemental flares brightly as it emits a pulse of flame, scorching everything withinreach.
  type: 3
- pattern: A greater fire elemental reaches up and removes its mask, the pure brightness and heat causing yourface to burn
    and your vision to fade.
  type: 3
- pattern: A greater fire elemental claws at you with its spindly arms, burning wounds deep into your torso.
  type: 3
]]--

	if not ataxiaBasher.manual then
		deleteFull()
	end
