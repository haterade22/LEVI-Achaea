--[[mudlet
type: trigger
name: GAG
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
- pattern: You may drink another health or mana elixir.
  type: 3
- pattern: 'You take a drink '
  type: 2
- pattern: You may apply another salve
  type: 2
- pattern: You take out some salve and quickly
  type: 2
- pattern: There is nothing to fear but fear itself.
  type: 3
- pattern: Your rage fades away.
  type: 3
- pattern: 'Your system is able to absorb antidotes once again. '
  type: 3
- pattern: You can use Chaosgate again.
  type: 3
- pattern: Your Chaosgate ability could
  type: 2
- pattern: '[Rage]:'
  type: 2
- pattern: You stand up.
  type: 3
- pattern: You must regain equilibrium first.
  type: 3
- pattern: You must regain balance first.
  type: 3
- pattern: The raging fire about your skin goes out.
  type: 3
- pattern: The bones in your (.*) mend.
  type: 1
- pattern: You can use another Battlerage
  type: 2
- pattern: You cup your hands together and fling them outwards,
  type: 2
- pattern: You begin feeling slightly flushed.
  type: 3
- pattern: Mercifully, the voyria venom has been cleansed from your body.
  type: 3
- pattern: The elixir burns through your veins, destroying the deadly poisons
  type: 2
- pattern: Your system is able to absorb antidotes once again.
  type: 3
- pattern: Your queues are already empty.
  type: 3
- pattern: You take a long drag of
  type: 2
- pattern: You have writhed free
  type: 2
- pattern: 'Alias "kickass" will now execute: '
  type: 2
- pattern: You feel an aura of rebounding surround you.
  type: 3
- pattern: Your class balance queue is already empty.
  type: 3
- pattern: Illuminated by the light of the moon.
  type: 3
- pattern: The vitality of the boar is energising (him|her).
  type: 1
- pattern: You may read another's aura once more.
  type: 3
- pattern: Cleared your queues.
  type: 3
- pattern: You are not yet able to read another's aura again.
  type: 3
- pattern: ^readaura (\w+) was added to your equilibrium queue.$
  type: 1
- pattern: ^Instill (\w+) with (\w+) was added to your equilibrium queue.$
  type: 1
- pattern: You clench your fists, grit your teeth, and banish all possibility of sleep.
  type: 3
- pattern: You have scored a
  type: 2
- pattern: 'You will now attempt to parry '
  type: 2
- pattern: You touch the bell tattoo.
  type: 3
- pattern: You will now attempt to detect attempts to spy on your person.
  type: 3
- pattern: The aural world fades to silence.
  type: 3
- pattern: You shut your eyes and concentrate on the Soulrealms. A moment later, you feel inextricably linked with the realm
    of Death.
  type: 3
- pattern: The sileris berry juice hardens into a supple purple shell.
  type: 3
- pattern: Calling on your dark power, you draw a thick shroud of concealment about yourself to cover your every action.
  type: 3
- pattern: Tiny tremours spread through your body as the world seems to slow down.
  type: 3
- pattern: You eat some bayberry bark.
  type: 3
- pattern: Your eyes dim as you lose your sight.
  type: 3
- pattern: You now possess the gift of the third eye.
  type: 3
- pattern: A feeling of comfortable warmth spreads over you.
  type: 3
- pattern: Touching the mindseye tattoo, your senses are suddenly heightened.
  type: 3
- pattern: '[System]'
  type: 2
]]--

deleteFull()