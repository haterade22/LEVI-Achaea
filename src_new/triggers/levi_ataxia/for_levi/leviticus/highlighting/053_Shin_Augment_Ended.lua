--[[mudlet
type: trigger
name: Shin Augment Ended
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
- pattern: ^The shin energy enhancing your body dissipates\.$
  type: 1
]]--
-- COVER ENDS (captured live 2026-08-12). The precise DOWN edge, and with the cover-starts line
-- (052) it brackets the duration exactly -- which is the sample `bash shinprobe` wants, since the
-- duration curve is undocumented and explicitly not one shin per second.
--
-- It also starts the cooldown, because the cooldown is equal to the duration that just ended. We no
-- longer have to COMPUTE when it expires, though -- the game says so, see 054 -- so the arithmetic
-- survives only as a backstop for a missed line.
--
-- Previously this edge was inferred from the GMCP `bodyaugment` defence going away on the next
-- prompt, which is up to a prompt late and made every measured duration read slightly short.
if ataxiaBasher_bmAugmentEnded then ataxiaBasher_bmAugmentEnded() end

selectString(line, 1)
fg("light_slate_blue")
deselect()
resetFormat()
