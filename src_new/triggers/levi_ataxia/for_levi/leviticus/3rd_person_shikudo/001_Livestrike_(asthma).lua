--[[mudlet
type: trigger
name: Livestrike (asthma)
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Third Person
- 3rd Person Shikudo
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
- pattern: ^The breath of (\w+) leaves \w+ in an explosive gasp as the end of the staff smashes home.$
  type: 1
]]--
-- v4.7.419: one hit, one record. 576 records a damaged livestrike from its damage line and sets
-- ignoreThirdPerson, so this line, the same hit, skips once and clears the flag, as 004 does for
-- ruku to the torso. Before, a damaged livestrike recorded asthma twice. A livestrike with no
-- damage line, or as a later strike of a combo (a line no strike trigger owns), is still recorded
-- here: 587 clears the flag at every strike line.

if isTargeted(matches[2]) then
  if not ignoreThirdPerson then
    tarAffed("asthma")
  else
    ignoreThirdPerson = nil
  end
end