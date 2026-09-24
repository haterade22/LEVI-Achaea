--[[mudlet
type: trigger
name: Belch Landed
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
- pattern: ^You belch a cloud of stinking gas out of your lungs and into your surroundings\.$
  type: 1
- pattern: ^Your rotten breath befouls the air, plaguing all who stand before you with choking filth\.$
  type: 1
]]--

-- BELCH went out (live 2026-09-24). The second line is the DEAD BREATH boon's own -- it cannot
-- print without the boon -- so it latches the flag as well as stamping the send, the same
-- self-proving shape as the Kai Unleashed burst.
if ataxiaBasher_belchLanded then
  ataxiaBasher_belchLanded(line and line:find("rotten breath", 1, true) ~= nil)
end
