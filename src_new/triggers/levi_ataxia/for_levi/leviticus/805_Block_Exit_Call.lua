--[[mudlet
type: trigger
name: Block Exit Call
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
- pattern: ^You move over to block the (\w+) exit\.$
  type: 1
]]--

-- "You move over to block the northeast exit." (the maintainer's paste, 2026-11-24): tell the party
-- which exit we hold, "Blocking Northeast". Always in PvP; while the basher runs it is a PvE call
-- and follows the `pvecalls` switch (ataxia_partyCallAllowed with no target tests the basher alone).
local dir = matches[2]:sub(1, 1):upper() .. matches[2]:sub(2)
if ataxia_partyCallAllowed and not ataxia_partyCallAllowed(nil) then return end
send("pt Blocking " .. dir, false)
