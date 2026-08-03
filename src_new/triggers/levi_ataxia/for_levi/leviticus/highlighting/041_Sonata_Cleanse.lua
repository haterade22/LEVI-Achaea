--[[mudlet
type: trigger
name: Sonata Cleanse
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
- pattern: ^The blessed sonata cleanses you of your burdens\.$
  type: 1
]]--

-- The SONATA refrain curing us -- a cure we did not pay a balance for, which is exactly the
-- kind of thing worth seeing land in a scroll running hundreds of lines a minute.
--
-- `medium_sea_green` (60,179,113) is NOT an arbitrary green: it is the colour the DAGAZ passive
-- heal already uses (passive_active/027). Both are "our passive cured/healed us for free", so
-- they should read as the same class of event -- picking a different green would imply a
-- distinction that does not exist. Deliberately not `spring_green`, which already means
-- parry-success (HL/027, HL/015), and not the orange family (reserved).
--
-- Colour taken FROM 007_Custom_Colour_Table, not reached for by name: this package wholesale
-- replaces Mudlet's table, so a plausible-but-absent name makes fg() throw on every match.
--
-- Highlight only, per the user's scope. Nothing reads it: our own affliction state is
-- authoritative-from-GMCP and self-correcting (004_Aff_gains_losses `lostAff` already nils the
-- entry and raises "aff cured"), so a "sonata cured one" signal would add nothing to
-- bookkeeping -- the same reasoning that kept the dagaz work to a highlight.
--
-- Type 1 anchored regex, never type 3.
selectString(line, 1)
setBold(true)
fg("medium_sea_green")
deselect()
resetFormat()
