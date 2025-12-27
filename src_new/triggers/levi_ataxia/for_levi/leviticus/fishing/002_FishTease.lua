--[[mudlet
type: trigger
name: FishTease
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
- pattern: You feel a fish make a small strike at your bait.
  type: 3
- pattern: You feel a fish nibbling on your hook.
  type: 3
- pattern: You quickly jerk back your fishing pole, but the hook pulls free of the fish.
  type: 3
]]--

if fishTimer then killTimer(fishTimer) end
fishTimer = tempTimer(1.9,  [[if ataxia.vitals.bal and ataxia.vitals.eq then
                   send("tease line",false)
                 else
                   enableTrigger("fishBalTrigger")
                   fishBalType="tease line"
                 end ]])
bashConsoleEcho("fishing", "Hook attempt <able>")