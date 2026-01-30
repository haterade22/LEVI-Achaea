--[[mudlet
type: trigger
name: Displace finish
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Misc Tracking
- Warnings
- Warnings
attributes:
  isActive: 'yes'
  isFolder: 'no'
  isTempTrigger: 'no'
  isMultiline: 'yes'
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
- pattern: You feel a strong tug in the pit of your stomach.
  type: 2
- pattern: ^You feel a strong tug in the pit of your stomach\. Your surroundings dissolve into the featureless swirl of the
    ether, resolving once more into a recognisable landscape as you land before (\w+)\.$
  type: 1
]]--

ataxia_setWarning(multimatches[2][2].. " displaced you (4/4)", 1)
