--[[mudlet
type: trigger
name: Recklessness Cured
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
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
- pattern: Prudence rules your psyche once again.
  type: 3
]]--

-- "Prudence rules your psyche once again." -- the game's cure line for recklessness
-- (kb/afflictions/afflictions.json, recklessness, cured_msg).
--
-- 2026-11-20, manifested nightmare death: recklessness hid our health (prompt and GMCP read full)
-- until FITNESS cured it at 13:08:43; the next reading was 17%, and the swarm refused to leave
-- because the one ground retreat was already spent. The health we decided on before this line was
-- not real, so the swarm may spend one more ground retreat in the few seconds after it
-- (mnemosyne/009, S._recklessReveal). Session state only: ataxiaTemp.
ataxiaTemp = ataxiaTemp or {}
ataxiaTemp.recklessCuredAt = getEpoch()
