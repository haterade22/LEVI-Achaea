--[[mudlet
type: trigger
name: Sharp Mind Proc
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
- pattern: ^Your mind is bolstered as your enemies break\.$
  type: 1
]]--

-- The SHARP MIND boon paying off (captured live 2026-08-03). Highlight only -- the user's
-- scope, explicitly: "we can just highlight that as a pale blue". No boon flag, no mechanics,
-- nothing reads it. If it later turns out to be worth gating something on, the flag can be
-- added then; guessing at a mechanic from one proc line is how dead config gets written.
--
-- `light_blue` (173,216,230) is the pale blue. Chosen from 007_Custom_Colour_Table rather than
-- reached for by name: this package WHOLESALE REPLACES Mudlet's colour table, so a plausible
-- but absent name (`crimson`, `ansi_cyan`) makes fg() throw on EVERY matching line. Distinct
-- from the `light_cyan` used for the clumsy proc, so the two do not read as the same effect.
-- Not the orange family (reserved).
--
-- Type 1 anchored regex, never type 3 -- exact-match on anything but a whole, invariant line is
-- what silently killed two triggers before v4.7.170. This line looks invariant, but the anchors
-- cost nothing and the failure mode of guessing wrong is silence.
selectString(line, 1)
setBold(true)
fg("light_blue")
deselect()
resetFormat()
