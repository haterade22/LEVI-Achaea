--[[mudlet
type: trigger
name: GAG2
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- MINE ALL MINE
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
- pattern: A (\w+) stream of (\w+) light emanates from a terrifying sad clown face mask
  type: 1
- pattern: You feel a momentary dizziness as your resistance to damage by poison increases.
  type: 3
- pattern: An instant feeling of excitement and edginess overcomes you.
  type: 3
- pattern: You eat a kola nut.
  type: 3
- pattern: A chill runs over your icy skin.
  type: 3
- pattern: You are now wearing a balloon prisoner's shackle with colourful links.
  type: 3
- pattern: You remove a balloon prisoner's shackle with colourful links.
  type: 3
- pattern: You eat a hawthorn berry.
  type: 3
- pattern: '(Ashtan):'
  type: 2
- pattern: '(Consortium):'
  type: 2
- pattern: You caress the tattoo and immediately you feel a cloak of protection surround you.
  type: 3
- pattern: Your body begins to feel lighter and you feel that you are floating slightly.
  type: 3
- pattern: 'The truenames of the following souls have been divulged to you:'
  type: 3
- pattern: 'Alias "kickassent" will now execute: '
  type: 2
- pattern: You may not command another entity so soon.
  type: 3
- pattern: 'Alias "keneanungki" will now execute:'
  type: 2
- pattern: ^You order (.*) to assume a passive stance.$
  type: 1
- pattern: 'With seeming reluctance, '
  type: 2
- pattern: I'm sorry, I don't know what "chaosrays" does.
  type: 3
- pattern: I'm sorry, I don't know what "command" does.
  type: 3
- pattern: I cannot fathom the meaning of "command".
  type: 3
- pattern: I cannot fathom the meaning of "chaosrays".
  type: 3
- pattern: What do you wish to invoke?
  type: 3
- pattern: I cannot fathom the meaning of "fling".
  type: 3
- pattern: I'm sorry, I don't know what "fling" does.
  type: 3
- pattern: There is no exit in that direction.
  type: 3
- pattern: I see no "gold" to take.
  type: 3
- pattern: I see no "pearl" to take.
  type: 3
- pattern: ^The crackle of snapping bone can be heard as a crystalline golem viciously twists the (.*).$
  type: 1
- pattern: ^A gust of wind strikes (\w+), throwing (her|him) to the ground.$
  type: 1
- pattern: Your golem is already at your side, sorcerer.
  type: 3
- pattern: 'You retrieve your '
  type: 2
- pattern: ^As a crystalline golem begins to pulse with a strange inner glow, (\w+) sways unsteadily.$
  type: 1
- pattern: You direct a crystalline golem to disrupt the flow of time around
  type: 2
- pattern: You start to wield an elemental staff in your
  type: 2
- pattern: You cease to wield an elemental staff.
  type: 2
- pattern: ^The element of earth shakes you to the core, breaking your (.*).$
  type: 1
- pattern: 'Alias "quasharc" will now execute: '
  type: 2
- pattern: 'You are already oriented in an upright position: you have no need to flex your powers of magnetism.'
  type: 3
- pattern: You may not assess someone again so soon after doing so previously.
  type: 3
- pattern: You aren't wielding anything.
  type: 3
- pattern: You step down off of Impastus, the last of the diffamo.
  type: 3
- pattern: You must dissolve your current lock before attempting another.
  type: 3
- pattern: You are too stunned to be able to do anything.
  type: 3
- pattern: I see no "body" to take.
  type: 3
- pattern: Paralysed as you are, your body is not able to pick up anything.
  type: 3
- pattern: You are paralysed and unable to do that.
  type: 3
- pattern: You may not focus on contemplating the mental state of someone again quite yet.
  type: 3
- pattern: The shadow of (\w+) has already been attuned to that.
  type: 1
]]--

deleteFull()