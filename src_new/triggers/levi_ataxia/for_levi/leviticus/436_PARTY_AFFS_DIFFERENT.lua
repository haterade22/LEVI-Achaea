--[[mudlet
type: trigger
name: PARTY AFFS DIFFERENT
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
- pattern: '^\(Party\): (\w+) says, " (\w+) on (\w+)."$'
  type: 1
]]--

-- paAff turns a venom into its affliction and adds it with tarAffed (V3 and tAffs). The
-- confirmAffV2 call that followed passed the RAW word to applyAffV3, which put a venom name
-- ("curare") into V3 as an affliction of its own (2026-11-08 deep review, H2).
if isTargeted(matches[4]) then
	paAff(matches[3])
end