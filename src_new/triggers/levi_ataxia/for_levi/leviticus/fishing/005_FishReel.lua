--[[mudlet
type: trigger
name: FishReel
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
- pattern: Relaxing the tension on your line, you are able to reel again.
  type: 3
]]--

if ataxia.vitals.bal and ataxia.vitals.eq then
   send("reel line", false)
else
   enableTrigger("fishBalTrigger")
   fishBalType="reel line"
end
bashConsoleEcho("fishing", "Can reel fish.")