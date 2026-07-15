--[[mudlet
type: trigger
name: Denizen Aeon Ended
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Basher
- Bashing
- Basher Lines
- Denizen Attacks / Misc Lines
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
- pattern: ^(.+) returns to normal speed\.$
  type: 1
]]--

-- Aeon wore off the named denizen.
if ataxiaBasher and ataxiaBasher.enabled and ataxiaBasher_dsResolveNameToId then
  local id = ataxiaBasher_dsResolveNameToId(matches[2], nil, "aeon")
  if id then ataxiaBasher_dsClearAff(id, "aeon") end
end
