--[[mudlet
type: trigger
name: Deathstrike
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Misc Tracking
- Warnings
- Warnings
- Instakills
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
conditonLineDelta: 99
mStayOpen: 0
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ^Fists clenched, ([A-Z][a-z]+) focuses on you with a deadly look in (\w+) eyes\.$
  type: 1
- pattern: ^Leaping forwards with lightning speed, ([A-Z][a-z]+) strikes you in the chest with a single, powerful blow\. Its
    rhythm interrupted by (\w+) precise attack, your heartbeat begins to fluctuate erratically, a painful pressure building
    in your arteries\.$
  type: 1
]]--

cecho("\n<yellow:red>DEATHSTRIKE COMING FROM <blue:red>" .. matches[2] .. "!\n<yellow:red>DEATHSTRIKE COMING FROM <blue:red>" .. matches[2] .. "!\n<yellow:red>DEATHSTRIKE COMING FROM <blue:red>" .. matches[2] .. "!")
ataxia_setWarning("deathstrike incoming",  2.5)	