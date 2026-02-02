--[[mudlet
type: trigger
name: Petrify Cured
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Affs Post Queue - Gated
- Classes K-S
- Sentinel
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
- pattern: ^(\w+) sucks in a gasp of air and begins to move normally once more\.$
  type: 1
- pattern: ^You gaze into the eyes of (\w+)\, projecting your implacable will\.$
  type: 1
]]--

if isTargeted(matches[2]) then
	ataxia_boxEcho(target.." IS NOT PETRIFIED", "red")
  tAffs.petrified = false
  if removeAffV3 then removeAffV3("petrified") end
end

