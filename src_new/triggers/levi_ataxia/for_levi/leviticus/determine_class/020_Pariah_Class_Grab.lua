--[[mudlet
type: trigger
name: Pariah Class Grab
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
- pattern: ^(\w+) unleashes a swarm of pestilent insects upon you
  type: 1
- pattern: ^(\w+) calls upon the power of memorium
  type: 1
- pattern: ^(\w+) drives .+ charnel weapon into your
  type: 1
- pattern: ^(\w+) sweeps .+ knife in a circle above \w+ head
  type: 1
- pattern: ^(\w+) traces a logograph depicting
  type: 1
- pattern: ^(\w+) raises \w+ right hand, and snaps \w+ fingers
  type: 1
]]--

classDetect.setAttackerClass(matches[2], "Pariah")
