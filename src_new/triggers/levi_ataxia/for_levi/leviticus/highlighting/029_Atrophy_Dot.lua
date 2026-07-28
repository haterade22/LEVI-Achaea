--[[mudlet
type: trigger
name: Atrophy Dot
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Highlighting
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
- pattern: ^(.+)'s form begins to atrophy as your attack kindles ethereal mist to consign \w+ to only memory\.$
  type: 1
- pattern: ^Time wreaks ruin upon (.+), deteriorating before your eyes\.$
  type: 1
]]--

-- Crit-proc atrophy DoT (live capture 2026-07-28, source unconfirmed -- boon/affix/
-- gear?): a critical strike kindles the mist ("consign to only memory", pattern 1),
-- then "Time wreaks ruin..." ticks the decay (pattern 2). Highlight both so the
-- proc and its ticks read at a glance. deep_sky_blue (spectral-mist blue) -- the
-- user reserves orange for something else (v4.7.136).
selectString(line,1)
setBold(true)
fg("deep_sky_blue")
deselect()
resetFormat()
