--[[mudlet
type: trigger
name: Voicecraft failed due to deafness
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Bard
- Bard
- voicecraft
- Voicecraft
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
- pattern: ^You sing a graceful maqam of el\'Jazira at (\w+)\, who seems unmoved\.$
  type: 1
- pattern: ^You sense futility as you recite an obscure Kamleikan haiku to (\w+)\.$
  type: 1
- pattern: ^In droning song you subject (\w+) to a lengthy isorhythm\, without results\.$
  type: 1
- pattern: ^Weaving a complex counterpoint between instrument and voice\, you fail to instill anything like fear in (\w+)\.$
  type: 1
- pattern: ^You invoke chaotic powers in a dark solo but fail to drain the essential magic of (\w+)\.$
  type: 1
- pattern: ^You direct a poem of gluttony and decay at (\w+)\, without success\.$
  type: 1
- pattern: ^You sing a pastorale of the fields and streams to (\w+)\, who seems not to notice\.$
  type: 1
- pattern: ^You chant \'GIMMEGIMME\' at (\w+)\, who does not react\.$
  type: 1
- pattern: ^You sing an irritating\, mind\-numbing ditty at (\w+)\, who seems curiously unaffected\.$
  type: 1
- pattern: ^With a mournful cry you begin the requiem for Seleucar to (\w+)\, who appears unmoved\.$
  type: 1
- pattern: ^Using a heavy tremolo you sing\, uselessly\, aiming at (\w+)\'s (left|right) leg\.$
  type: 1
- pattern: ^With a frustratingly irrelevant vibrato you aim at (\w+)\'s (left|right) arm\.$
  type: 1
- pattern: ^Your recitation of an epic tale of the heroism of Nicator has no effect on (\w+)\.$
  type: 1
- pattern: ^With a wink\, you recite \"Ode to Elixirs\" to (\w+)\, who looks on\, unimpressed\.$
  type: 1
- pattern: ^Starting with the characteristic Jaziran trill\, you sing a qasida of asceticism to (\w+)\, who seems undaunted\.$
  type: 1
- pattern: ^With a gravity born of respect\, you sing of the saintly Imithia\, if only for yourself\.$
  type: 1
- pattern: ^Composing a few clever lines in your head\, you quickly sing a jaunty limerick at (\w+)\, who seems to pay no
    notice\.$
  type: 1
- pattern: ^You sing a sonorous chant which fails to strip the defences of (\w+)\.$
  type: 1
]]--

cecho("\n    <white>--== TARGET IS DEAF ==--<reset>")
if matches[2] == target then
	tAffs.deaf = false
	end