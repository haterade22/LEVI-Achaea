--[[mudlet
type: trigger
name: Party Targeting
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- PARTY TARGETTING
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
- pattern: '^\(Party\): (\w+) says, "Target: (\w+)."$'
  type: 1
- pattern: '^\(Party\): (\w+) says, "Target (\w+)."$'
  type: 1
- pattern: '^\(Party\): (\w+) says, "TARGET: (\w+)."$'
  type: 1
- pattern: '^\(Party\): (\w+) says, "Target changed to (\w+)."$'
  type: 1
]]--

-- A leader repeats a call often. In the 2026-11-03 group fight, 18 of 49 calls named the target we
-- already held, and each one ran the whole switch: it wiped the tracker for that target, and also
-- shield and rebounding. A typed `t NAME` still resets, because that is a choice.
if partyleader and partyleader == matches[2] then
if type(target) == "string" and target:lower() == matches[3]:lower() then return end
partyrelay = false
expandAlias("t "..matches[3])
end