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
-- It changes no ROTATION. Shatter goes out once per full transcendence, free, at the front of the
-- round -- and only then (v4.7.356, user: "we should only use PSI Shatter when at 100
-- transcendence!"; v4.7.352-355 also spent idle equilibrium on it, which held the weaves back).
-- Mindbreak multiplies that one shatter.
--
-- The flag is still worth latching: the boon advisor scores what we hold.
--
-- Cleared on Mnemosyne run start/end. Type BOONS to re-sync if needed.
-- Only inside the tower (v4.7.351, deep review) -- the same gate the generic row trigger
-- (mnemosyne/013) applies, so a list printed outside a run arms nothing.
if ataxiaBasher and ataxiaBasher.inMnemosyne then psionMindbreak = true end
