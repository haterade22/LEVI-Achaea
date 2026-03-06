--[[mudlet
type: trigger
name: Serpent Class Grab
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Curing Stuff
- Priority Management
- Determine Class
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
- pattern: ^(\w+) quickly pricks you with \w+ dirk\.$
  type: 1
- pattern: ^Striking like a snake, (\w+) follows the first attack with another\.$
  type: 1
- pattern: ^(\w+) sinks \w+ fangs into you, injecting .+ venom\.$
  type: 1
- pattern: ^(\w+) delivers a quick, stinging bite to your body\.$
  type: 1
- pattern: ^(\w+) whips \w+ whip at you, ripping away your .+\.$
  type: 1
- pattern: ^(\w+) fixes you with an entrancing stare
  type: 1
]]--

classDetect.setAttackerClass(matches[2], "Serpent")
