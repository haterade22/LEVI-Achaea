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
- pattern: ^(.+) abruptly begins to move at normal speed again\.$
  type: 1
]]--

-- Aeon wore off the named denizen. The second pattern is the Depthswalker CHRONO CURSE
-- wear-off, captured live 2026-07-29 -- and it MEASURED the duration: curse landed at
-- 12:15:14.0 and expired at 12:15:19.7, i.e. ~5.6s of aeon against a 35s cooldown (~16%
-- uptime). That is why the DW rotation does NOT bank rage for curse: starving the cheap
-- filler to hold 24 rage for a 5-second mitigation window loses more damage than it saves.
if ataxiaBasher and ataxiaBasher.enabled and ataxiaBasher_dsResolveNameToId then
  local id = ataxiaBasher_dsResolveNameToId(matches[2], nil, "aeon")
  if id then ataxiaBasher_dsClearAff(id, "aeon") end
end
