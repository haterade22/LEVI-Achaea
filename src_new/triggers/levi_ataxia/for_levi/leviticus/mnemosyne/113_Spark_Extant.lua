--[[mudlet
type: trigger
name: Mnemosyne Spark Extant
hierarchy:
- Levi_Ataxia
- Ataxia
- Mnemosyne
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
- pattern: ^Spark Extant\s+\d+\s+\w+
  type: 1
]]--

-- A row in the BOONS list (name / echoes / rarity) confirms Spark Extant is active: INCANTATION
-- hits every enemy denizen in the room and costs 33% less willpower. The dragon basher casts
-- it first at 2+ denizens, before tailsweep, trample and blast (ataxiaBasher_dragonSparkPick,
-- basher/002, v4.7.440). Cleared on Mnemosyne run start/end (mirrors the other boon flags).
dragonSparkExtant = true
