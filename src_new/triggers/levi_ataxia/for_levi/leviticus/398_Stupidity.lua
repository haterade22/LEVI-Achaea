--[[mudlet
type: trigger
name: Stupidity
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Third Person
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
- pattern: ^(\w+) makes a strangled meowing noise and quickly shuts up, blushing\.$
  type: 1
- pattern: ^(\w+) picks (\w+) nose absently\.$
  type: 1
- pattern: ^(\w+) breaks down and sobs uncontrollably\.$
  type: 1
- pattern: ^(\w+) gets down on one knee and serenades the world\.$
  type: 1
- pattern: ^(\w+) falls to \w+ knees in worship\.$
  type: 1
- pattern: ^(\w+) hugs \w+ compassionately\.$
  type: 1
- pattern: ^(\w+) grunts a bit and then lets out a loud \"OINK\!\"$
  type: 1
- pattern: ^(\w+) waggles \w+ eyebrows comically\.$
  type: 1
- pattern: ^(\w+) wails like an old woman\.$
  type: 1
- pattern: ^(\w+) moans, holding his head\.$
  type: 1
- pattern: ^You cast a net of stupidity over (\w+)'s mind\.$
  type: 1
- pattern: ^(\w+) twitches spasmodically\.$
  type: 1
- pattern: ^With a gravity, \w+ sings the Passion of Imithia at (\w+).$
  type: 1
]]--

if isTargeted(matches[2]) then
	tarAffed("stupidity")
end