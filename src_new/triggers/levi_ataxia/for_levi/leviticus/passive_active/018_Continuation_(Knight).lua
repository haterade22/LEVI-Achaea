--[[mudlet
type: trigger
name: Continuation (Knight)
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Remove Afflictions
- Groups
- Passive/Active
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
- pattern: ^(\w+) gives a great shout of exertion\.$
  type: 1
]]--
-- CONTINUATION (Weaponmastery, the two-handed knight specialisation; ABADMIN 2061,
-- kb/raw/abadmin/weaponmastery_continuation_2061.txt): "You may use this ability to shrug off the
-- effects of paralysis." So the line proves that paralysis is gone.
-- Until 2026-11-13 this trigger acted only for a Monk and took weariness plus one random
-- affliction. No source said so, and no Monk ability prints this line. Agathon, a knight with a
-- bastard sword, shouted 3 times in kb/raw/logs/ours/2026-11-03_102138_Tabethys.log, each after
-- a curare paralysis (rows 4339-4345, 4871-4938, 7313-7407); after one he attacked in the same
-- batch (4939). The record also says it stops FITNESS "for a short time"; Agathon's FITNESS fired
-- 0.5 s after his first shout (4363), so that is not modelled.
local KNIGHTS = { Infernal = true, Paladin = true, Runewarden = true, Unnamable = true, Unknown = true }

local name = matches[2]
local class = (ataxiaNDB_getClass(name) or "Unknown")

if isTargeted(name) and KNIGHTS[class] then
  onClassCureV3({"paralysis"})
  if startPassiveCooldownV3 then startPassiveCooldownV3("passive_continuation") end
  selectString(line,1)
  fg("NavajoWhite")
  resetFormat()
  targetIshere = true
end
