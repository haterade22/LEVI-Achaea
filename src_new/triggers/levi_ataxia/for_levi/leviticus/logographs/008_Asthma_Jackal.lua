--[[mudlet
type: trigger
name: Asthma/Jackal
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes K-S
- Pariah
- Logographs
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
- pattern: ^As the logograph becomes fully formed it leaps for (.+)\, ephemeral fangs closing about \w+ throat.$
  type: 1
- pattern: ^(.+) coughs, \w+ face starting to turn blue.$
  type: 1
]]--

if type(target) == "string" and isTargeted(matches[2]) then
	tarAffed("asthma")
	if applyAffV3 then applyAffV3("asthma") end
end

if ataxiaBasher.enabled then
  if not ataxiaBasher.manual then
    deleteFull()
  end
end