--[[mudlet
type: trigger
name: Splinter Needs Warhammer
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
- pattern: ^You must be wielding a warhammer to splinter an opponent's defences\.$
  type: 1
]]--

-- The refusal (user, 2026-10-26): SPLINTER needs a warhammer, and we hold something else -- a
-- bastard sword, whose shield break is CARVE. Learn that and re-send the round
-- (basher/015_Two_Hand_Raze.lua), so the refused raze is replaced at once.
if ataxiaBasher_splinterRefused then ataxiaBasher_splinterRefused() end
