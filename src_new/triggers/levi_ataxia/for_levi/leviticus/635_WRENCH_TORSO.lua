--[[mudlet
type: trigger
name: WRENCH TORSO
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
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
- pattern: ^You step inside the wide open guard of (\w+), .+ brutal strike to \w+ floating ribs before casting \w+ ruthlessly to the ground\.$
  type: 1
]]--


if isTargeted(matches[2]) then
	bruisedribs = true
	tempTimer(30, [[bruisedribs = false]])
	tarAffed("prone")
	confirmAffV2("prone")

	if partyrelay then send("pt "..target..": bruisedribs")
	end
end
