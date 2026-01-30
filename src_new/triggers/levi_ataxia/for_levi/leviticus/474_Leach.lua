--[[mudlet
type: trigger
name: Leach
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
- pattern: ^As the weapon strikes (\w+), \w+ seems greatly diminished.$
  type: 1
]]--

if isTargeted(matches[2]) then
	Target_Instill = "leach"
	if not haveAff("parasite") then
		tarAffed("parasite")
    if partyrelay and tloop == false and tloop2 == false then send("pt "..target..": " ..envenomList[1].. " and parasite") end
    if partyrelay and (tloop == true or tloop2 == true) then send("pt "..target..": timeloop and parasite") end
	elseif not haveAff("healthleech") then
		tarAffed("healthleech")
    if partyrelay and tloop == false and tloop2 == false then send("pt "..target..": " ..envenomList[1].. " and healthleech") end
    if partyrelay and (tloop == true or tloop2 == true) then send("pt "..target..": timeloop and healthleech") end
	elseif not haveAff("manaleech") then
		tarAffed("manaleech")
    if partyrelay and tloop == false and tloop2 == false then send("pt "..target..": " ..envenomList[1].. " and manaleech") end
    if partyrelay and (tloop == true or tloop2 == true) then send("pt "..target..": timeloop and manaleech") end
	else
		tarAffed("parasite", "healthleech", "manaleech")
	end
end