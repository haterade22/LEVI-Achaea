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

-- INACTIVE SCAFFOLD -- blocked on live capture, deliberately not guessed at.
--
-- The patterns above are literal placeholders, so this trigger can never fire (and `type: 3`
-- is EXACT WHOLE LINE, which is the wrong type for most fire lines anyway -- see AGENTS.md).
-- It is kept rather than deleted because it records exactly what still needs capturing.
--
-- WHAT TO CAPTURE, in game, while wearing the talon:
--   1. the SUCCESS line for SCRATCH MYSELF WITH TALON
--   2. the REFUSAL line when the talon is still on cooldown
-- Both are needed: every timer-free ability in this package wants a fire line to confirm
-- and a refusal line to cancel (AGENTS.md). The refusal line would also settle the real
-- cooldown, which `ataxia.vultureTalon.cooldownDuration` currently only GUESSES at 180s.
--
-- Example success handler:
--   erAff("shivering")
--   erAff("frozen")
--   erAff("nocaloric")
--   ataxiaTemp.vultureTalonAt = getEpoch()   -- restamp from the LANDED moment
--
-- Example cooldown/refusal handler:
--   ataxiaTemp.vultureTalonAt = getEpoch()   -- it did not fire; hold and retry after the gap
--
-- NOTE the stamp is `ataxiaTemp.vultureTalonAt`, a reload-safe TIMESTAMP -- NOT the old
-- `ataxia.vultureTalon.onCooldown` boolean, which was removed in v4.7.194 precisely because
-- `ataxia` is serialized and a tempTimer is not, so it reloaded stuck on forever.
