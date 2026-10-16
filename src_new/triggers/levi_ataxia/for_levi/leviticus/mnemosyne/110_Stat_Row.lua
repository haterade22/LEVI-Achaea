--[[mudlet
type: trigger
name: Mnemosyne Stat Row
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
- pattern: ^\|.*\b(?:Strength|Intelligence|Dexterity|Constitution)\s*:\s*\d+
  type: 1
]]--

-- A row of the STAT box (v4.7.427, user 2026-10-16), e.g.
--   | Health  : 13215/13231 Willpower: 32495/32495 Strength : 16 Intelligence: 15 |
-- Two stats can share a row, so the whole line goes to ataxia.mnemosyne.onStatLine (011), which
-- reads every stat on it. The bonuses panel scales Brute Force, Mental Prowess, Deadly Finesse and
-- Trainwreck by these numbers. Not gagged: the user wants to see the box.
if ataxia.mnemosyne and ataxia.mnemosyne.onStatLine then ataxia.mnemosyne.onStatLine(line) end
