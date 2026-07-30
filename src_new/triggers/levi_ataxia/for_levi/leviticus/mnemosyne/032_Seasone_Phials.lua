--[[mudlet
type: trigger
name: Mnemosyne Seasone Phials
hierarchy:
- Levi_Ataxia
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
# type 0 = substring ANYWHERE. The game line opens with her name ("Seasone, the
# Industrious reaches into her robes..."), so this fragment is mid-line and the
# type 3 (EXACT MATCH) it shipped with could never fire -- the truelock counter
# has been dead since v4.7.123. Found by an exact-match/fragment audit, v4.7.170.
- pattern: reaches into her robes and withdraws a handful of fragile glass phials
  type: 0
]]--

-- Seasone the Industrious's venom-phial burst (live log 2026-07-27: kalmia, gecko,
-- slike "and more" -> IMP SLI AST ANO, soft+hard lock). The tree was RESERVED for
-- exactly this moment (curing tree off since her objective line) -- release it so
-- SSC spends the tattoo on the lock immediately.
if ataxia.mnemosyne and ataxia.mnemosyne.onSeasonePhials then
  ataxia.mnemosyne.onSeasonePhials()
end
