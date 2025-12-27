--[[mudlet
type: trigger
name: FishJerk
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
- pattern: You stagger as a fish makes a large strike at your bait.
  type: 3
- pattern: You see the water ripple as a fish makes a medium strike at your bait.
  type: 3
]]--

if fishTimer then killTimer(fishTimer) end
fishTimer = tempTimer(1.6,  [[if ataxia.vitals.bal and ataxia.vitals.eq then
                   send("jerk line",false)
                 else
                   enableTrigger("fishBalTrigger")
                   fishBalType="jerk line"
                 end ]])
bashConsoleEcho("fishing", "Hook attempt <jerk>")