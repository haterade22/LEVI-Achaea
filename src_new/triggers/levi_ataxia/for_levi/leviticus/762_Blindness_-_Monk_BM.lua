--[[mudlet
type: trigger
name: Blindness - Monk BM
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
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
- pattern: You close your eyes for a moment.
  type: 3
]]--

-- The game's own echo that a blind trance is in flight -- whoever started it. Stamping here is
-- what stops the keeper answering a MANUALLY typed BLIND with a duplicate; the keeper stamps
-- separately when it sends (see deffing/007_Sense_Keepers.lua).
--
-- It no longer writes `ataxia.defences.blindness = true`. That was OPTIMISM on an attempt line,
-- and an interrupted trance would have left us believing in a defence GMCP never confirmed and
-- so will never Remove -- a keeper silently off for the rest of the session (v4.7.280). GMCP
-- owns whether the defence is up; this line only proves an attempt exists.
if ataxia_senseAttemptSeen then ataxia_senseAttemptSeen("blindness") end
