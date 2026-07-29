--[[mudlet
type: trigger
name: Mnemosyne Indiscriminate
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
- pattern: ^Indiscriminate\s+\d+\s+\w+
  type: 1
]]--

-- A row in the BOONS list confirms Indiscriminate is active: "Your Arc is now effective
-- against denizens." ARC normally reads "Works on: Adventurers and room", so it is dead
-- weight in PvE; with this boon the untargeted room form (4.75s of balance) becomes a
-- genuine AoE. The Infernal basher swings it INSTEAD of the single-target attack at 2+
-- denizens (ataxiaBasher_infArc, basher/002 -- tune with ataxiaBasher.infArcAt).
-- Cleared on Mnemosyne run start/end. Type BOONS to re-sync if needed.
infIndiscriminate = true
