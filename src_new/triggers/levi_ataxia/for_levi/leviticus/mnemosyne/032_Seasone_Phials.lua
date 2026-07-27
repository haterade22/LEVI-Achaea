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
- pattern: reaches into her robes and withdraws a handful of fragile glass phials
  type: 3
]]--

-- Seasone the Industrious's venom-phial burst (live log 2026-07-27: kalmia, gecko,
-- slike "and more" -> IMP SLI AST ANO, soft+hard lock). The tree was RESERVED for
-- exactly this moment (curing tree off since her objective line) -- release it so
-- SSC spends the tattoo on the lock immediately.
if ataxia.mnemosyne and ataxia.mnemosyne.onSeasonePhials then
  ataxia.mnemosyne.onSeasonePhials()
end
