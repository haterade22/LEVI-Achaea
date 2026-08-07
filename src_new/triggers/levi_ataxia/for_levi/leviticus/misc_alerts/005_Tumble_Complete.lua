--[[mudlet
type: trigger
name: Tumble Complete
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Misc Alerts
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
- pattern: ^You tumble out of the room\.$
  type: 1
]]--

-- THE TUMBLE ACTUALLY COMPLETED (v4.7.234, user-supplied). The matching START line is
-- "You begin to tumble agilely to the <dir>." and the gap between them is FOUR SECONDS
-- (timed: 11:52:29.160 -> 11:52:33.178).
--
-- v4.7.233 inferred completion from the ROOM CHANGING with a 2s window, which was wrong twice
-- over: the window was shorter than the action, so it re-sent mid-tumble; and a room number is
-- a proxy for the thing rather than the thing. This line IS the thing. The timer stays as the
-- fallback for when it never arrives -- the paralysis case that started all this.
if ataxia and ataxia.mnemosyne and ataxia.mnemosyne.swarm
   and ataxia.mnemosyne.swarm.onTumbleDone then
  ataxia.mnemosyne.swarm.onTumbleDone()
end
