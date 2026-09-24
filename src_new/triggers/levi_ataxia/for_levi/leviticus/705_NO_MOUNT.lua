--[[mudlet
type: trigger
name: NO MOUNT
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
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
- pattern: You have no mount on which to jump.
  type: 3
- pattern: You must be mounted to trample.
  type: 3
- pattern: You need to be riding a proper mount to gallop.
  type: 3
]]--

-- THE GAME SAYS WE ARE NOT MOUNTED (v4.7.345). All three lines are refusals of something that
-- needs a mount -- MOUNTJUMP, TRAMPLE, GALLOP -- so each is authoritative in the direction a
-- stale belief is most expensive: it stops us re-sending mountjumps that can never land.
if ataxiaBasher_mountedSet then ataxiaBasher_mountedSet(false, "the game says we have no mount") end

--expandAlias("mi")