--[[mudlet
type: trigger
name: SHAPE PLUS
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- EARTH LORD
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
- pattern: You feel the magma contained within your hallowed form begin to seethe.
  type: 3
- pattern: Magma begins to boil up from beneath your outer strata.
  type: 3
- pattern: Magma explodes from the cracks between the plates covering you, forming a cloak of molten stone to enshroud you.
  type: 3
]]--

shape = shape + 1
deleteFull()
ak.prompt.scoreup()
myminiconsole:cecho("\n<orange>HEAD<white> "..lb[target].hits["head"])
myminiconsole:cecho("\n\n<orange>TORSO<white> "..lb[target].hits["torso"])
myminiconsole:cecho("\n\n<orange>LEFT LEG<white> "..lb[target].hits["left leg"])
myminiconsole:cecho("\n<orange>RIGHT LEG<white> "..lb[target].hits["right leg"])
myminiconsole:cecho("\n\n<orange>RIGHT ARM<white> "..lb[target].hits["right arm"])
myminiconsole:cecho("\n<orange>LEFT ARM<white> "..lb[target].hits["left arm"])
myvariablename:setTitle("SHAPE      [[[  "..shape.."   ]]]", "orange")