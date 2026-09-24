--[[mudlet
type: trigger
name: Soulstorm Already
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
- pattern: Necromantic essence still profanes
  type: 0
]]--

-- ALREADY PROFANED (live 2026-09-24): "Necromantic essence still profanes a bloated cabin boy's
-- soul." -- the storm we just sent found the work already done.
--
-- Same conclusion as the landing line, and the only way to reach it when the confirmation never
-- arrived (a reload between send and reply, a line lost in a burst): mark the soul and stop
-- picking it. Without this the six-second retry would spend equilibrium on that mob for as long
-- as it lived.
--
-- A SUBSTRING, not an anchored line: the denizen's name sits in the middle of it, is of arbitrary
-- length, and Achaea wraps server-side -- the same rule the landing line and the Kai Choke
-- confirmation follow.
if ataxiaBasher_soulstormAlready then ataxiaBasher_soulstormAlready() end
