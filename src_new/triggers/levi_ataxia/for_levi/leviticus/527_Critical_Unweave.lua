--[[mudlet
type: trigger
name: Critical Unweave
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes K-S
- Psion
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
- pattern: ^You detect fluctuations in the essence of (\w+) as \w+ (\w+) becomes critically close to unweaving utterly.$
  type: 1
]]--

if not isTargeted(matches[2]) then return end
selectString(line,1)
fg("black")
if matches[3] == "mind" and haveAff("unweavingmind") then
	tAffs.criticalmind = true
	if applyAffV3 then applyAffV3("criticalmind") end
  mindinvert = true
	bg("LightSkyBlue")
elseif matches[3] == "body" and haveAff("unweavingbody") then
	tAffs.criticalbody = true
	if applyAffV3 then applyAffV3("criticalbody") end
  bodyinvert = true
  bg("chocolate")
else
  tAffs.criticalspirit = true
  if applyAffV3 then applyAffV3("criticalspirit") end
  spiritinvert = true
  bg("NavajoWhite")
end
deselect()