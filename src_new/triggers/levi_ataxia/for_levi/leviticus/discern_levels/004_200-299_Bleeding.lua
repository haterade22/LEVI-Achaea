--[[mudlet
type: trigger
name: 200-299 Bleeding
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
- pattern: ^You observe thin red rivulets of blood dripping from (\w+)'s wounds.$
  type: 1
]]--

if not tAffs.bleed or (tAffs.bleed and tAffs.bleed < 280) then tAffs.bleed = 280 end

if tAffs.bleed > 300 and not ataxiaTemp.coagulateAff then
	tAffs.bleed = 280
	tAffs.haemophilia = false
	if removeAffV3 then removeAffV3("haemophilia") end
end
cecho(" <white>[<red>"..tAffs.bleed.."<white>]")

ataxiaTemp.coagulateAff = nil