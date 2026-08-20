--[[mudlet
type: trigger
name: Wave Progress
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
- pattern: Wave progress:\s*(\d+)
  type: 1
]]--
-- WADE STATUS: `Wave progress:  <n>` -- how far through clearing this ripple we are.
--
-- Found by reviewing MediaRes' standalone Mnemosyne tracker (2026-08-20), which reads this
-- and `Remaining lives` out of the same block we were already parsing for affixes. We had
-- been throwing both away.
--
-- NOT ANCHORED, on purpose: these fields sit inside an indented status block, so `^` would
-- depend on how the game pads them -- and CLAUDE.md's own trigger guidance is to avoid `^`/`$`
-- unless they are earning their place. The phrase is distinctive enough on its own.
if ataxia and ataxia.mnemosyne and ataxia.mnemosyne.onWaveProgress then
	ataxia.mnemosyne.onWaveProgress(matches[2])
end
