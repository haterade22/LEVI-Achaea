--[[mudlet
type: trigger
name: Toxicologist Relapse
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
- pattern: screams out in agony, struck by the effects of a vicious venom.
  type: 0
- pattern: screams out in agony, struck
  type: 0
- pattern: '^.{0,60}struck by the effects of a vicious venom\.$'
  type: 1
- pattern: '^.{0,30}effects of a vicious venom\.$'
  type: 1
]]--

-- TOXICOLOGIST'S RELAPSE (v4.7.384, user: "Also this, is the relapse ... from that toxic boon"):
--
--   An enormous two-headed ettin screams out in agony, struck by the effects of a vicious venom.
--
-- "Your venoms now relapse against denizens, dealing damage again after a delay." The denizen's name
-- opens the line, so the patterns are substrings and anchored tails: one for the whole line, one for
-- a first row that wraps after "struck", and two for the tail row of a wrapped line.
--
-- `yellow` bold -- bright, and distinct from the bite's chartreuse, so the relapse (the boon working)
-- is told apart from the bite itself at a glance.
--
-- The line prints only with the boon, so it is the boon's own proof: it re-latches
-- `mnemToxicologist` (in the tower only, the rule every boon line follows since v4.7.351), which
-- keeps the camus bite on after a reimport even before BOONS is typed.
selectString(line, 1)
fg("yellow")
setBold(true)
deselect()
resetFormat()
if ataxiaBasher and ataxiaBasher.inMnemosyne then mnemToxicologist = true end
