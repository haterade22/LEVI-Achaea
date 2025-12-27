--[[mudlet
type: trigger
name: Harmonic Was Summoned
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Class Stuff
- Bard
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
- pattern: Your feelings rise with a Continuo's opening movement.
  type: 3
- pattern: An Anthem fills the air with its mighty fortress of protective influences as you take up its stately music.
  type: 3
- pattern: With a powerful fanfare, you begin a resounding Hallelujah.
  type: 3
- pattern: You dash off a few bars, launching into the detailed patterns of a Gigue.
  type: 3
- pattern: You enter into the realms of the divine as you play the opening strains of a sacred Canticle.
  type: 3
- pattern: The Wassail's first notes stir and strengthen you.
  type: 3
- pattern: Slowly you take up the dark and sombre tones of a Lament.
  type: 3
- pattern: You set feet tapping and rodents scrambling with a rousing Rondo.
  type: 3
- pattern: An elaborate Contradanse melody begins to pervade the room.
  type: 3
- pattern: Through a series of musical twists and turns you begin the Bagatelle.
  type: 3
- pattern: Delicate and precise, you take up a Partita.
  type: 3
- pattern: You begin a delicate Berceuse, playing with great tenderness.
  type: 3
- pattern: With a hop you enter into the complex, up-tempo dance melody of a Reel.
  type: 3
- pattern: You find yourself unable to play the harmonic here at this time.
  type: 3
]]--

bardHarmsInRoom = true
if ataxiaTemp.summoningHarms then
	table.remove(ataxiaTemp.harms, 1)
	ataxia_nextHarmonic()
end
