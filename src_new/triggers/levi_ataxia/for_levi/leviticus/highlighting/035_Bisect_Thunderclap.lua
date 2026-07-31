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
-- CHARTREUSE BOLD: this is an ATTACK LANDING, and that is what the colour has to say.
--
-- v4.7.181 shipped it deep_sky_blue, reasoning from the ability (lightning damage) rather
-- than from the palette. That was wrong: in this package BLUE means a defence or a proc --
-- DodgerBlue is "our defence is up" (shield, paragon, transcendence, tree), deep_sky_blue
-- is the crit-proc atrophy DoT -- so bisect read as something that happened TO us rather
-- than the room-clearing swing we just threw. Corrected 2026-07-31 on the user's point that
-- it should look like the other attacks.
--
-- chartreuse BOLD is the established "damage actually happening" colour, used for the
-- hyena maul and falcon rake landings (367 / 370). Bisect is our own swing rather than a
-- pet's, but it is the same category of event and the same thing worth spotting mid-scroll.
--
-- NOT the orange_red used by the other AoE nukes (culling blade 018, rampage 033): that
-- family is grandfathered only, since the user reserves orange for their own use.
selectString(line, 1)
setBold(true)
fg("chartreuse")
deselect()
resetFormat()
