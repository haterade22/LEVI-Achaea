--[[mudlet
type: trigger
name: Mount Row
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Basher
- Bashing
- Basher Lines
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
- pattern: ^(.+?)(\d+) is at your (?:fingertips|feet|side)\.$
  type: 1
]]--

-- One row of the mounts listing (live 2026-09-24):
--   A black Dardanic stallion22638 is at your fingertips.
--   A lean grizzly bear135599 is at your feet.
-- The digits are the item id GMCP reports for that creature, which is what the basher skips on --
-- never the name, because the species ("a massive dire wolf") is a real denizen too. Only read
-- while the header has us armed, so a lookalike line elsewhere cannot poison the list.
if ataxiaBasher_onMountRow then ataxiaBasher_onMountRow(matches[2], matches[3]) end
