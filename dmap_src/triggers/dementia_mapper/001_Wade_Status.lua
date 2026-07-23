--[[mudlet
type: trigger
name: dmap Wade Status
hierarchy:
- Dementia_Mapper
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
- pattern: ^You wade (\d+) ripples? deep into the tides of memory
  type: 1
]]--

-- Authoritative "we are in ripple N" signal. Assert active + reset the map for the new ripple.
-- (The wade lifecycle -- not gmcp -- is the truth: Creville's Legacy fakes gmcp.Room wholesale.)
if dmap and dmap.onRipple then dmap.onRipple(tonumber(matches[2])) end
