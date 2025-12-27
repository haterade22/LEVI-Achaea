--[[mudlet
type: trigger
name: 1-99 Bleeding
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Misc Tracking
- Discern Levels
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
- pattern: ^You observe a small amount of blood trickling from minor wounds on (\w+)'s body.$
  type: 1
]]--

if tAffs.bleed == nil or tAffs.bleed == 0 then tAffs.bleed = 80 end

if tAffs.bleed > 100 and not ataxiaTemp.coagulateAff then
	tAffs.bleed = 80
	tAffs.haemophilia = false
end
cecho(" <white>[<red>"..tAffs.bleed.."<white>]")

if not tAffs.haemophilia then
	tAffs.bleed = 0
end

ataxiaTemp.coagulateAff = nil