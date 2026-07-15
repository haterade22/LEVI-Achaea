--[[mudlet
type: trigger
name: Denizen Weakness Ended
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
- pattern: ^(.+) stands up straight, having overcome the weakness that afflicted \w+\.$
  type: 1
]]--

-- Weakness (Nerveslash) wore off the named denizen (pronoun him/her/it varies -> \w+).
if ataxiaBasher and ataxiaBasher.enabled and ataxiaBasher_dsResolveNameToId then
  local id = ataxiaBasher_dsResolveNameToId(matches[2], nil, "weakness")
  if id then ataxiaBasher_dsClearAff(id, "weakness") end
end
