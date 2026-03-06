--[[mudlet
type: trigger
name: Magi Class Grab
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
- pattern: ^(\w+) weaves .+ in a complex pattern and
  type: 1
- pattern: ^(\w+) lifts .+ to point at you and unleashes
  type: 1
- pattern: ^The air thrums about (\w+) as \w+ weaves Elemental
  type: 1
- pattern: ^(\w+) weaves .+ and a torrent of
  type: 1
- pattern: ^(\w+) forms a lash of fire
  type: 1
- pattern: ^(\w+) touches a crystal pylon, and a loud vibration rings out
  type: 1
- pattern: ^A crystal pylon vibrates at the command of (\w+)
  type: 1
- pattern: ^(\w+) hurls a bolt of .+ at you
  type: 1
]]--

classDetect.setAttackerClass(matches[2], "Magi")
