--[[mudlet
type: trigger
name: No wormhole
hierarchy:
- mudlet-mapper
- Mudlet Mapper
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
- pattern: There is no wormhole here.
  type: 3
]]--

if mmp.speedWalkDir and mmp.speedWalkDir[mmp.speedWalkCounter] and mmp.speedWalkDir[mmp.speedWalkCounter]=="worm warp" then
  mmp.echo("Missing wormhole detected, locking wormhole and trying new path...")

  lockSpecialExit(mmp.currentroom, mmp.speedWalkPath[mmp.speedWalkCounter], "worm warp", true)

  local destination = mmp.speedWalkPath[#mmp.speedWalkPath]

  mmp.stop()

  mmp.clearpathcache() -- clear cache so mmp.getPath accounts for the new way

  if not mmp.getPath(mmp.currentroom, destination) then
    mmp.echo(string.format("Don't know how to get to %d (%s) anymore :( Move into a room we know of to continue", destination, getRoomName(destination)))
  else
    mmp.gotoRoom(destination)
  end
end