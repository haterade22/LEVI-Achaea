--[[mudlet
type: trigger
name: Writhed Impale
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Remove Afflictions
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
- pattern: ^With a look of agony on [\w'\-]+ face\, ([\w'\-]+) manages to writhe (herself|himself) free of the weapon which
    impaled [\w'\-]+\.$
  type: 1
- pattern: ^With a vicious snarl you carve a merciless swathe through the steaming guts of ([\w'\-]+)\, who gurgles and chokes
    as you withdraw your dripping blade\, glistening with gore\.$
  type: 1
- pattern: ^With a vicious snarl [\w'\-]+ carves a merciless swathe through the steaming guts of ([\w'\-]+)\, who gurgles
    and chokes as [\w'\-]+ withdraws [\w'\-]+ dripping blade\, glistening with gore\.$
  type: 1
- pattern: ^With a snarl of contempt\, you allow ([\w'\-]+) to slide free of your weapon\.$
  type: 1
- pattern: You have no victim impaled to be able to perform a disembowelment.
  type: 3
- pattern: ^As ([\w'\-]+) wrenches away from you\, your blade rips through his innards in a violent fashion\, leaving a pool
    of viscera where your foe once lay\.$
  type: 1
- pattern: ^([\w'\-]+) tumbles out to the .*\.$
  type: 1
]]--

if line:find("disembowelment") then
  erAff("impaled")
tAffs.impaled = false
timpale = false
else
  if isTargeted(matches[2]) then
  	erAff("impaled")
  	selectString(line,1)
  	setBold(true)
  	fg("magenta")
  	resetFormat()
tAffs.impaled = false
timpale = false
  end 
end
