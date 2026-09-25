--[[mudlet
type: trigger
name: Mindbreak
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Mnemosyne
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
- pattern: ^Mindbreak\s+\d+\s+\w+
  type: 1
]]--

-- A row in the BOONS list confirms Mindbreak is active (v4.7.349):
--
--   "Your psionics shatter ability deals 500% increased damage."
--
-- It changes no ROTATION, and since v4.7.352 that is for a better reason. v4.7.349 sent shatter
-- only at full transcendence and noted that if it turned out usable below that at an equilibrium
-- price, this flag would be the switch. The user then pasted the AB block (3.10s of
-- equilibrium, works on denizens) and the answer was not a switch: shatter is the main
-- equilibrium tool WITH OR WITHOUT this boon -- it out-damages a deathblow on a channel the weaves
-- leave idle. Mindbreak multiplies what is already on every idle equilibrium.
--
-- The flag is still worth latching: the boon advisor scores what we hold.
--
-- Cleared on Mnemosyne run start/end. Type BOONS to re-sync if needed.
-- Only inside the tower (v4.7.351, deep review) -- the same gate the generic row trigger
-- (mnemosyne/013) applies, so a list printed outside a run arms nothing.
if ataxiaBasher and ataxiaBasher.inMnemosyne then psionMindbreak = true end
