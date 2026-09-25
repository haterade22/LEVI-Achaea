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
-- NO ROTATION CHANGE, and that is the finding rather than an omission. `psi shatter <target>`
-- already fires on every FULL transcendence, which is precisely when a psionics action costs no
-- equilibrium ("once at full harmony, you can perform a psionics action while off equilibrium
-- and for no incurred equilibrium cost"). The gate is about when shatter is FREE, not about
-- whether it is worth it -- so multiplying its damage does not move it.
--
-- The flag is still worth latching: the boon advisor scores what we hold, and if SHATTER turns
-- out to be usable BELOW full transcendence at an equilibrium price, this is the switch that
-- would decide to pay it. That needs the ability block captured first -- this tree does not
-- guess game syntax.
--
-- Cleared on Mnemosyne run start/end. Type BOONS to re-sync if needed.
-- Only inside the tower (v4.7.351, deep review) -- the same gate the generic row trigger
-- (mnemosyne/013) applies, so a list printed outside a run arms nothing.
if ataxiaBasher and ataxiaBasher.inMnemosyne then psionMindbreak = true end
