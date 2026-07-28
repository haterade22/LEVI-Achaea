--[[mudlet
type: trigger
name: Mnemosyne Deluge
hierarchy:
- Levi_Ataxia
- Ataxia
- Mnemosyne
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
- pattern: ^Deluge:\s+All rooms are underwater\.
  type: 1
]]--

-- Deluge affix status row: every room is underwater, so FLY is impossible -- the
-- swarm module's escape ladder and fly-kite must take their grounded branches
-- (S._canFly gate, 009_Swarm_Tactics). Telemetry-independent, the Haemophiliac
-- shape; reset on run start, cleared on the confirmed run end.
if ataxia and ataxia.mnemosyne and ataxia.mnemosyne.onDelugeSeen then
	ataxia.mnemosyne.onDelugeSeen()
end
