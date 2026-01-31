--[[mudlet
type: trigger
name: Contemplate
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Misc Tracking
- Warnings
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
- pattern: ^(\w+)'s mana stands at (\d+)\/(\d+).$
  type: 1
]]--

local cm, mm = tonumber(matches[3]), tonumber(matches[4])
 pm = math.floor((cm/mm)*100)
ataxiaTemp.contemplate = nil
if isTargeted(matches[2]) then
	if gmcp.Char.Status.class == "Depthswalker" then
		calculateDictate(pm)
	elseif pm > 80 then
		selectString(line,1)
		fg("blue")
		resetFormat()
	elseif pm > 50 then
		selectString(line, 1)
		fg("LightSkyBlue")
	elseif ataxia_isClass("priest") or ataxia_isClass("apostate") and pm <= 49 then
		selectString(line,1)
		fg("DarkSlateBlue")
		resetFormat()
		ataxia_boxEcho("LOW MANA! "..(ataxia_isClass("apostate") and "CATHARSIS " or "ABSOLVE ")..string.upper(target).." NOW!", "black:white")
	elseif ataxia_isClass("psion") and pm <= 30 then
		selectString(line, 1)
		fg("DodgerBlue")
		resetFormat()
		ataxia_boxEcho("LOW MANA! EXCISE THEM NOW!", "black:DodgerBlue")
  elseif ataxia_isClass("depthswalker") and pm <= 40 then
		selectString(line, 1)
		fg("DodgerBlue")
		resetFormat()
		ataxia_boxEcho("LOW MANA! DICTATE THEM NOW!", "black:DodgerBlue")
	end
end