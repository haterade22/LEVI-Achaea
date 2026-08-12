--[[mudlet
type: trigger
name: Full Mettle Alchemist Proc
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
- pattern: ^The spirit of the Alchemist revitalises your body and mind\.$
  type: 1
]]--

-- FULL METTLE ALCHEMIST paying off (captured live 2026-08-12): "While attuned to Aspar,
-- critical strikes will restore 2% health and 2% mana." Same treatment as the Sharp Mind proc
-- (highlighting/040) at the user's request -- highlight only, no boon flag, nothing reads it.
--
-- `aquamarine` (127,255,212) rather than the Sharp Mind pale blue: this one restores HEALTH and
-- mana, so it belongs with the green/restorative family and must not read as the same effect as
-- a mind buff. Taken from 007_Custom_Colour_Table by inspection, never reached for by name --
-- this package WHOLESALE REPLACES Mudlet's colour table, so a plausible but absent name makes
-- fg() throw on EVERY matching line. Not the orange family (reserved for the user).
--
-- Type 1 anchored regex, never type 3 -- exact-match on anything but a whole invariant line is
-- what silently killed two triggers before v4.7.170. Note the game spells it "revitalises";
-- the anchors are cheap and the failure mode of guessing wrong is silence.
--
-- WORTH KNOWING, deliberately NOT wired: this line is the only ground truth that the boon's
-- ATTUNE GATE is satisfied. Full Mettle does nothing unless Aspar is attuned, and none of the
-- four spirit-gated boons currently check `shaman.spiritlore.attunements` -- so holding the boon
-- with the wrong loadout is silent. That belongs in the attune-gated boon layer, reading this
-- line as confirmation, rather than being inferred here from one proc. Guessing at a mechanic
-- from a single proc line is how dead config gets written (the 040 precedent).
selectString(line, 1)
setBold(true)
fg("aquamarine")
deselect()
resetFormat()
