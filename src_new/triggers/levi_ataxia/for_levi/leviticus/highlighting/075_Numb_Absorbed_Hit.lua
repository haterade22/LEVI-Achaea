--[[mudlet
type: trigger
name: Numbness Absorbed Hit
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
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ^You smile as the blow falls painlessly on you\.$
  type: 1
]]--

-- A HIT THAT NUMBNESS ABSORBED (v4.7.512).
--
--   You smile as the blow falls painlessly on you.
--
-- One line for each hit a denizen lands while numbness is up (158 lines in 28 cycles, live
-- 2026-11-23, kb/defences/numbness.md). The game prints no figure and no "Health lost:" line: the
-- hit is owed, and it is collected when numbness fades (highlighting/074). This line is the only
-- sign that the debt grows, so it is counted: `ataxia_numbAbsorbed` (basher/016_Numb_Debt.lua)
-- adds one estimated hit to the debt and gives it to the damage-rate watchdog.
--
-- No highlight: it prints several times a round.
if ataxia_numbAbsorbed then ataxia_numbAbsorbed() end
