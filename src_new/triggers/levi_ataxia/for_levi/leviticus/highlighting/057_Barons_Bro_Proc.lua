--[[mudlet
type: trigger
name: Barons Bro Proc
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
- pattern: a squad of ogre goons rushes forward
  type: 0
- pattern: bruise the fool that would bring you harm
  type: 0
]]--
-- BARON'S BRO (Mnemosyne boon, RARE) -- the summon proc, captured 2026-08-20.
--
--   "When you critically strike, there is a low chance that your attack will invoke Baron
--    Balam Agab, summoning a squad of ogre goons to lay waste to your enemies. This may only
--    occur once every 20 seconds."
--
-- The boon has been in the seed catalogue (`mnemosyne/010_Boon_Seed.lua`) all along; only the
-- line it PRINTS was never captured, so a rare proc scrolled past unmarked in a busy log.
--
-- TWO PATTERNS BECAUSE THE LINE WRAPS. Achaea wraps server-side at the player's WIDTH, so
-- Mudlet is handed two physical lines:
--
--   A distant rumble sets the ground to quaking as, bursting in from without, a squad of ogre
--   goons rushes forward, their
--   bellowing cries of "THAT HIM!" shaking the earth as each brandish fists and clubs and
--   mauls of all kinds to batter and  bruise the fool that would bring you harm.
--
-- A pattern spanning that break can never match. So one fragment is taken from near the START
-- of the sentence and one from the very END, and the body colours whichever line it landed on
-- -- both get marked wherever the wrap happens to fall. If a different WIDTH moves the break,
-- the worst case is a middle row left uncoloured, never a missed proc.
--
-- Substring patterns (type 0) rather than anchored regex for exactly that reason: the fragment
-- is mid-line by construction, so `^`/`$` could not be used even if we wanted them. Both are
-- distinctive enough that a false positive is not credible.
--
-- `plum` is the lightest true purple in `007_Custom_Colour_Table` and is otherwise unused in
-- this folder, so it carries no competing meaning. NOTE that table WHOLESALE REPLACES Mudlet's
-- own, so a plausible-but-absent colour name makes fg() throw -- every name here is verified
-- present in it.
selectString(line, 1)
fg("plum")
deselect()
resetFormat()
