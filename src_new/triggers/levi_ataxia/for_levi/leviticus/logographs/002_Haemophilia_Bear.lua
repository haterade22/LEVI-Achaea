--[[mudlet
type: trigger
name: Haemophilia/Bear
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
- pattern: ^Even as the logograph becomes fully formed it leaps from the air to (.+)\, ephemeral claws plunging into \w+ chest.$
  type: 1
- pattern: ^Ephemeral claws suddenly thrust from the chest of (.+)\, their ghostly edges slicing and rending.$
  type: 1
]]--

if type(target) == "string" and isTargeted(matches[2]) then
	tarAffed("haemophilia")
	if applyAffV3 then applyAffV3("haemophilia") end
  
end

if not tAffs.haemophilia then
tarAffed("haemophilia") 
if applyAffV3 then applyAffV3("haemophilia") end
tAffs.bleed = tAffs.bleed + 50
end
if tAffs.haemophilia then
tAffs.bleed = tAffs.bleed + 100
end

if ataxiaBasher.enabled then
  if not ataxiaBasher.manual then
    deleteFull()
  end
end