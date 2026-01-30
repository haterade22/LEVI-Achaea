--[[mudlet
type: trigger
name: Party Afflictions
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
- pattern: '^\(Party\)\: (\w+) says\, "(\w+) hit with (\w+)."$'
  type: 1
- pattern: '^\(Party\)\: (\w+) says, "(\w+) has (\w+)."$'
  type: 1
- pattern: '^\(Party\)\: (\w+) says, "(\w+) has been hit with (\w+)."$'
  type: 1
- pattern: '^\(Party\)\: (\w+) says, "Rended (\w+)''s .+ with (\w+)."$'
  type: 1
- pattern: '^\(Party\): (\w+) says, "(\w+) wracked: (\w+)."$'
  type: 1
- pattern: '^\(Party\): (\w+) says, "Afflicted (\w+): (\w+)."$'
  type: 1
- pattern: '^\(Party\)\: Serin says, "(\w+) has (\w+)."$'
  type: 1
- pattern: '^\(Party\): (\w+) says, "(\w+): (\w+) (\w+)."$'
  type: 1
- pattern: '^\(Party\): (\w+) says, "(\w+): (\w+) (\w+) (\w+) (\w+)."$'
  type: 1
]]--

if isTargeted(matches[3]) then
	paAff(matches[4])
  tarAffed(matches[4])
  confirmAffV2(matches[4])
elseif isTargeted(matches[4]) then
  paAff(matches[3])
  tarAffed(matches[3])
  tarAffed(matches[5])
  confirmAffV2(matches[3])
  confirmAffV2(matches[5])
end

if isTargeted(matches[2]) then
tarAffed(matches[3])
tarAffed(matches[4])
confirmAffV2(matches[3])
confirmAffV2(matches[4])
end

if isTargeted(matches[2]) then
tarAffed(matches[3])
tarAffed(matches[4])
confirmAffV2(matches[3])
confirmAffV2(matches[4])
end

if isTargeted(matches[3]) then
tarAffed(matches[4])
tarAffed(matches[5])
tarAffed(matches[6])
tarAffed(matches[7])
confirmAffV2(matches[4])
confirmAffV2(matches[5])
confirmAffV2(matches[6])
confirmAffV2(matches[7])
end


if isTargeted(matches[3]) then
tarAffed(matches[4])
tarAffed(matches[5])
tarAffed(matches[6])
tarAffed(matches[7])
confirmAffV2(matches[4])
confirmAffV2(matches[5])
confirmAffV2(matches[6])
confirmAffV2(matches[7])
end
