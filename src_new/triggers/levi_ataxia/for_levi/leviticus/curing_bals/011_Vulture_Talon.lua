--[[mudlet
type: trigger
name: Vulture Talon
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Curing Stuff
- Curing Bals
attributes:
  isActive: 'no'
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
- pattern: TODO_REPLACE_WITH_TALON_SUCCESS_TEXT
  type: 3
- pattern: TODO_REPLACE_WITH_TALON_COOLDOWN_TEXT
  type: 3
]]--

-- TODO: Replace patterns above with actual game text after in-game testing.
-- Success pattern: confirm cooldown started, erase shivering/frozen.
-- Cooldown pattern: talon on cooldown, keep flag set.
--
-- Example success handler:
--   erAff("shivering")
--   erAff("frozen")
--   erAff("nocaloric")
--
-- Example cooldown handler:
--   ataxia.vultureTalon.onCooldown = true
