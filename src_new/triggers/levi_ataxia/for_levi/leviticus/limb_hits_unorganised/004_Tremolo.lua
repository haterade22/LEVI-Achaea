--[[mudlet
type: trigger
name: Tremolo
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Affs Post Queue - Gated
- Limb Got Hit
- Limb Hits Unorganised
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
- pattern: ^Using a heavy tremolo you brutally punish (\w+)'s already shattered (\w+) leg.$
  type: 1
]]--

if isTargeted(matches[2]) then
	-- bard_tremvib removed: 3c312975 deleted it and the tLimbs counter it added to, and the call
	-- threw before the flag below was set.
  ataxiaTemp.tvBal = true
end