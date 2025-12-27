--[[mudlet
type: trigger
name: FishPull
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Fishing
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
- pattern: ^Dodging back and forth furiously, your fish draws out (\d+) f(?:oo|ee)t of line\.$
  type: 1
- pattern: ^Leaping from the water in a frenzy to escape, .+ runs out (\d+) f(?:oo|ee)t of your line\.$
  type: 1
- pattern: ^The fish on your line shows its power by running out (\d+) f(?:oo|ee)t of line\.$
  type: 1
- pattern: ^The fish tries to swim with the hook, drawing (\d+) f(?:oo|ee)t of line\.$
  type: 1
- pattern: ^The fish you've hooked struggles against the line and runs it out (\d+) f(?:oo|ee)t\.$
  type: 1
- pattern: ^Tugging powerfully, your fish draws out (\d+) f(?:oo|ee)t of line\.$
  type: 1
- pattern: ^With a power born of the Seagod, an? .+ leaps from the water explosively, running the line out (\d+) f(?:oo|ee)t\.$
  type: 1
- pattern: ^With a pull that threatens to rip the pole from your hand, the fish you've hooked runs out (\d+) f(?:oo|ee)t of
    line\.$
  type: 1
- pattern: ^With an arm-wrenching burst of power, the fish you've hooked runs out (\d+) f(?:oo|ee)t of fishing line\.$
  type: 1
- pattern: ^You feel the fish tugging on your line, drawing it out about (\d+) f(?:oo|ee)t\.$
  type: 1
- pattern: ^Your fish struggles and swims firmly away from you, drawing out (\d+) f(?:oo|ee)t of fishing line.$
  type: 1
- pattern: ^Your rod bends slightly as your fish tries to escape its barbed tether, running out (\d+) f(?:oo|ee)t of line\.$
  type: 1
]]--

linelength = linelength + tonumber(matches[2])
bashConsoleEcho("fishing", "Fish pulled to "..linelength.."ft.")