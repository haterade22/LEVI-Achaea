--[[mudlet
type: trigger
name: Mounted
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- BM
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
- pattern: ^Being mounted, your opponent has little use for their legs\.$
  type: 1
]]--

tmounted = true

-- Whose mount this is (v4.7.420). The line names nobody ("your opponent"), so it is the target we
-- were attacking. tmounted stays one global for the readers that read it as one (Blademaster's
-- KNEES dismount in blademaster/005, the Shikudo dispatch), but no target change resets it, so TK6
-- reads the owner as well: a flag recorded for someone else is not this target's mount
-- (tekura6.isMounted, tekura/002). ataxiaTemp is never saved.
ataxiaTemp = ataxiaTemp or {}
ataxiaTemp.mountedWho = target