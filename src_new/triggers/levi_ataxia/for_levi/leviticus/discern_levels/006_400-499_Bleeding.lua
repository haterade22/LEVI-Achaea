--[[mudlet
type: trigger
name: 400-499 Bleeding
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
- pattern: ^You observe free-flowing blood streaming from (\w+)'s wounds.$
  type: 1
]]--

if not tAffs.bleed or (tAffs.bleed and tAffs.bleed < 450) then tAffs.bleed = 450 end

if tAffs.bleed > 500 and not ataxiaTemp.coagulateAff then
	tAffs.bleed = 480
	tAffs.haemophilia = false
	if removeAffV3 then removeAffV3("haemophilia") end
end
cecho(" <white>[<red>"..tAffs.bleed.."<white>]")

tAffs.haemophilia = true
if applyAffV3 then applyAffV3("haemophilia") end
ataxiaTemp.coagulateAff = nil