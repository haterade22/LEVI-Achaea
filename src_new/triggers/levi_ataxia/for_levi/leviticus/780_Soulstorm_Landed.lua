--[[mudlet
type: trigger
name: Soulstorm Landed
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Basher
- Bashing
- Basher Lines
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
- pattern: ^You call forth an unholy tide of necromantic essence and release it, engulfing
  type: 1
]]--

-- The soul is profaned (live 2026-09-24). One storm per denizen is the whole rule -- the boon's
-- value is the DEBUFF sitting on that mob, not a hit we repeat -- so this marks the target we sent
-- for and the rider never picks it again. The line prints with or without Deathtempest, so it
-- proves nothing about the boon and does not latch it.
-- MATCHED EARLY, BECAUSE THE SERVER WRAPS (v4.7.351, deep review). This user's Achaea wraps
-- at 119-124 columns (measured from the break points in their pastes), and the full line is
-- longer than that. A pattern that runs past the break -- or a fragment that straddles it --
-- can never match, and this one did exactly that from the day it shipped.
--
-- Here the length depends on the MOB: "Duke Semiro" fits, "a bloated cabin boy" does not, and a
-- landing we never saw meant the storm was sent again -- which is where the user's "Necromantic
-- essence still profanes a bloated cabin boy's soul." came from. The mob's name is not needed:
-- the soul marked is the one we SENT for (ataxiaTemp.soulstormTarget).
if ataxiaBasher_soulstormLanded then ataxiaBasher_soulstormLanded() end
