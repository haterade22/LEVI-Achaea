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
]]--

	if not ataxiaBasher.manual then
		deleteFull()
	end
