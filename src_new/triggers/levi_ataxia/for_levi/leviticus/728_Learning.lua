--[[mudlet
type: trigger
name: Learning
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Misc Triggers
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
- pattern: ^The next (ability|abilities) you will learn
  type: 1
- pattern: Ezekial the Scholar bows to you, the lesson in Runelore ended.
  type: 3
- pattern: The next abilit
  type: 2
- pattern: ^(.+) bows to you - the lesson in \w+ is over.$
  type: 1
- pattern: ^(.+)\, ending \w+ lesson in \w+.$
  type: 1
- pattern: An Ashtani sergeant bows to you and d
  type: 2
]]--

if ataxiaTemp.learning and not sentLearn then
	send("learn 20 "..ataxiaTemp.learning.." from "..ataxiaTemp.learnFrom,false)
	sentLearn = tempTimer(0.5, [[sentLearn = nil]])
end
