--[[mudlet
type: trigger
name: Bloodlet
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes K-S
- Shaman
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
- pattern: ^With grim resolve, you gesture sharply at (\w+).$
  type: 1
]]--

if tAffs.haemophilia then 
	tAffs.bleed = tAffs.bleed or 0
	tAffs.bleed = tAffs.bleed + 250 
end

ataxiaTemp.bloodlet = true
tarAffed("haemophilia")
if partyrelay then  send("pt "..target..": haemophilia") end

cecho(" <white>[<red>"..(tAffs.bleed or 0).."<white>]")