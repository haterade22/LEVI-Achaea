--[[mudlet
type: trigger
name: Ensorcell Faded
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes K-S
- Pariah
- Misc
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
- pattern: ^You sense that your ensorcelment of (\w+) has broken.$
  type: 1
]]--

-- "Your ensorcelment of X has broken" is definitive. The old guard (`if not ensorcellTimer`) skipped
-- it whenever a timer handle existed, and the handle was never cleared, so after the first cast
-- this line did nothing (v4.7.405).
if pariah.state.ensorcellTimer then killTimer(pariah.state.ensorcellTimer) end
pariah.state.ensorcellTimer = nil
erAff("ensorcelled")