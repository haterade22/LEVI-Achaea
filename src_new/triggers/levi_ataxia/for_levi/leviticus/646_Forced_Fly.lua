--[[mudlet
type: trigger
name: Forced Fly
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Misc Tracking
- Warnings
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
- pattern: A violent force suddenly takes hold of you and launches you high into the sky.
  type: 3
]]--

selectString(line,1)
fg("black") bg("blue")
resetFormat()
send("ql")
dir_left = "forcefly"
tAffs.paralysis = false

if tChaseTimer then
	killTimer(tostring(tChaseTimer))
end
tChaseTimer = tempTimer(2.0, [[tChaseTimer = nil]])
targetIshere = false
enableTimer("TargetOutOfRoom")