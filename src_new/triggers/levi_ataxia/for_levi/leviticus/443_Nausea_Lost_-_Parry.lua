--[[mudlet
type: trigger
name: Nausea Lost - Parry
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Third Person
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
- pattern: ^(\w+) parries the attack with a deft manoeuvre\.$
  type: 1
]]--

-- Only the target's own parry. The pattern was unanchored and the body did not check the name, so
-- anyone's parry erased our target's nausea: kb/raw/logs/ours/2026-11-03_102138_Tabethys.log:338-339,
-- Havyn parries a handaxe while the target is Grulk, and the tracker logs "-tar nausea" with it.
-- limb_hits_unorganised/002_Parried reads the same line with the same check.
-- Open: whether even the target's own parry proves nausea gone. 002_Parried erases it only for a
-- knight attacker; kb/raw/logs/2026-08-19_leviticus_blademaster-vs-sentinel_loss_Sentinel.txt:870-883
-- shows a parry of a Sentinel's spear while our own board held nausea.
if matches[2] and isTargeted(matches[2]) then
  erAff("nausea")
end