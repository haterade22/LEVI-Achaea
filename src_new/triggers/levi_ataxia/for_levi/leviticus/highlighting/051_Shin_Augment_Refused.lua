--[[mudlet
type: trigger
name: Shin Augment Refused
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
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
packageName: ''
patterns:
- pattern: ^You are already beginning the process of augmenting your body with shin energy\.$
  type: 1
]]--

-- THE REFUSAL, and the reason this trigger exists (captured live 2026-08-12). It arrived FIVE times
-- inside 0.45 seconds:
--
--     10:14:17:502  You are already beginning the process of augmenting your body with shin energy.
--     10:14:17:572  ... (x5, ~70-110ms apart)
--
-- Five rejected commands during one 4s activation. The Lua-side hold is armed at send time and
-- evidently did not hold -- and it cannot be relied on to, because `shin augment` costs no balance,
-- so it EXECUTES on every re-queue of the round rather than waiting like the swing does. The
-- basher rebuilds that round every prompt.
--
-- So the game's own refusal is treated as ground truth over our bookkeeping, exactly as the
-- Depthswalker distortion refusal is (v4.7.266) and the legend deck's "lacks the power to invoke"
-- is over ldm's charge count. It arms the hold from the REFUSAL, which is the one signal that
-- cannot be out of date.
--
-- Distinct from the COOLDOWN refusal ("Regardless of your skill, augmenting yourself with shin
-- energy so soon would be fatal", recorded in .claude/classes/blademaster.md and still uncaptured):
-- this one means "already channelling", that one means "too soon after the last one ended". Both
-- want us to stop asking, for different lengths of time.
if ataxiaBasher_bmAugmentRefused then ataxiaBasher_bmAugmentRefused() end

selectString(line, 1)
fg("indian_red")
deselect()
resetFormat()
