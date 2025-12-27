--[[mudlet
type: trigger
name: SHAPE BASE
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
- pattern: ^The rock plates covering your form rapidly thicken, sharp spikes of stone sprouting from them in an instant.$
  type: 1
]]--

shape = 1
deleteFull()
ak.prompt.scoreup()

myminiconsole:cecho("\n<orange>HEAD<white> "..lb[target].hits["head"])
myminiconsole:cecho("\n\n<orange>TORSO<white> "..lb[target].hits["torso"])
myminiconsole:cecho("\n\n<orange>LEFT LEG<white> "..lb[target].hits["left leg"])
myminiconsole:cecho("\n<orange>RIGHT LEG<white> "..lb[target].hits["right leg"])
myminiconsole:cecho("\n\n<orange>RIGHT ARM<white> "..lb[target].hits["right arm"])
myminiconsole:cecho("\n<orange>LEFT ARM<white> "..lb[target].hits["left arm"])
myvariablename:setTitle("SHAPE      [[[  "..shape.."   ]]]", "orange")