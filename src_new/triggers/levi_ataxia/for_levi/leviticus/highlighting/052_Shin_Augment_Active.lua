--[[mudlet
type: trigger
name: Shin Augment Active
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
- pattern: ^You channel your accumulated shin energy into enhancing your defensive bladework\.$
  type: 1
]]--

-- COVER STARTS HERE (captured live 2026-08-12). This is the end of the 4s activation and the
-- beginning of the 20% damage reduction -- the moment the duration clock starts.
--
-- It is what makes the augment probe honest. The duration is measured from THIS line to the
-- defence dropping, rather than from the send (which is 4s early) or from the first prompt that
-- happened to notice the defence (which is up to a prompt late). Since the ability's cooldown is
-- equal to the duration it was up for, an accurate start is also an accurate cooldown -- and that
-- is what stops the basher re-sending a refused augment for up to a minute and a half.
if ataxiaBasher_bmAugmentActive then ataxiaBasher_bmAugmentActive() end

selectString(line, 1)
setBold(true)
fg("spring_green")
deselect()
resetFormat()
