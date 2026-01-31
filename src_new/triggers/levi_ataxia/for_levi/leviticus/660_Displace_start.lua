--[[mudlet
type: trigger
name: Displace start
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
- pattern: You feel a sudden jerk, and the air immediately surrounding you comes alight with pale, etheric fire as a strange
    hissing noise fills the air.
  type: 3
]]--

ataxia_setWarning("getting displaced", 2.5)
local currentroom = gmcp.Room.Info.name

ataxiaTemp.displacerooms = ataxiaTemp.displacerooms or {}
ataxiaTemp.displacerooms[#ataxiaTemp.displacerooms+1] = currentroom

tempTimer(9+1, function()
  local i = table.index_of(ataxiaTemp.displacerooms, currentroom)
  if i then
    table.remove(ataxiaTemp.displacerooms, i)
    ataxia_Echo(currentroom.." should be safe to move back into now.")
  end
end)