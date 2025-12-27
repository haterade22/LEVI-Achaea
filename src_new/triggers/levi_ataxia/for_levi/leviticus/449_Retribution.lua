--[[mudlet
type: trigger
name: Retribution
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes A-J
- Depthwalker
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
- pattern: ^As the weapon strikes (\w+), it blazes with incandescent white flame.$
  type: 1
]]--

if isTargeted(matches[2]) then
	Target_Instill = "retribution"
	if not haveAff("justice") then
		tarAffed("justice")
    if partyrelay and tloop == false and tloop2 == false then send("pt "..target..": " ..envenomList[1].. " and justice") end
    if partyrelay and (tloop == true or tloop2 == true) then send("pt "..target..": timeloop and justice") end
	else
		tarAffed("retribution")
    if partyrelay and tloop == false and tloop2 == false then send("pt "..target..": " ..envenomList[1].. " and retribution") end
    if partyrelay and (tloop == true or tloop2 == true) then send("pt "..target..": timeloop and retribution") end
	end
end
