--[[mudlet
type: trigger
name: Bisect Thunderclap
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
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
- pattern: ^Lightning follows the path of .+ as you sweep it at .+, a clap of thunder heralding your strike\.$
  type: 1
]]--

-- BISECT's fire line, captured live 2026-07-31:
--   "Lightning follows the path of Valafar, a crimson-tinged hellforged longsword as you
--    sweep it at the Imp Lord, a clap of thunder heralding your strike."
--
-- Both the weapon and the target vary, hence the two `.+` captures rather than a fixed
-- string. Anchored regex (type 1) on purpose -- an exact-match type 3 on a partial line is
-- what silently killed two triggers before v4.7.170.
--
-- Coloured for the boon it belongs to: bisect is a LIGHTNING-then-cutting strike, and under
-- Thunderclap its third hit sprays electric damage across the room. deep_sky_blue is the
-- established "our proc landed" blue here and is not the health/damage orange-red family.
selectString(line, 1)
setBold(true)
fg("deep_sky_blue")
deselect()
resetFormat()
