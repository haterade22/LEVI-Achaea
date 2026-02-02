--[[mudlet
type: trigger
name: Water Bonds
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes Other
- Water Lord
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
- pattern: ^Tendrils of water lash out from you, latching themselves to (\w+) and hindering \w+ attempts to flee.$
  type: 1
]]--

if isTargeted(matches[2]) then
	tarAffed("bonds")
	if applyAffV3 then applyAffV3("bonds") end
	
	if ataxiaTemp.bondsTimer then killTimer(ataxiaTemp.bondsTimer); ataxiaTemp.bondsTimer = nil end
	ataxiaTemp.bondsTimer = tempTimer(32, [[
		if haveAff("bonds") then
			erAff("bonds")
			if removeAffV3 then removeAffV3("bonds") end
			ataxia_boxEcho("Water bonds has faded from "..target, "purple")
		end
	]])
end