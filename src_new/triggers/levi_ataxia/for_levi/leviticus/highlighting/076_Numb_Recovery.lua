--[[mudlet
type: trigger
name: Numbness Recovery
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
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
- pattern: ^You have recovered enough to numb your body once again\.$
  type: 1
- pattern: ^You may not numb again so soon\.$
  type: 1
]]--

-- THE NUMB RECOVERY (v4.7.512).
--
--   You have recovered enough to numb your body once again.     2.05-2.74 s after the fade (n=14)
--   You may not numb again so soon.                             a NUMB sent before that line
--
-- Live 2026-11-23 (kb/defences/numbness.md). Before this trigger the Senseless Flurry keeper sent
-- NUMB with the first round after the fade, was refused, and its 5 s attempt-hold put the next
-- numb 5 s after the fade. `ataxia_numbCooling` (basher/016_Numb_Debt.lua) now holds the keeper
-- until the ready line.
if line:find("recovered enough", 1, true) then
  if ataxia_numbReady then ataxia_numbReady() end
elseif ataxia_numbRefused then
  ataxia_numbRefused()
end
