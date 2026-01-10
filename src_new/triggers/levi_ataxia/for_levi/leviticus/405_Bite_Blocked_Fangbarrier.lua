--[[mudlet
type: trigger
name: Bite Blocked Fangbarrier
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
- pattern: ^You try to bite (\w+), but your fangs are stopped by an odd metallic coating.$
  type: 1
]]--

-- Bite blocked = target definitely has fangbarrier
if isTargeted(matches[2]) then
	tAffs.fangbarrier = true
	tAffs.sileris = true
	Algedonic.Echo("<red>BITE BLOCKED<white> - target has fangbarrier! Strip with gecko/flay.")
end
