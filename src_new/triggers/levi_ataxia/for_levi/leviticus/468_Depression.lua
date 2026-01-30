--[[mudlet
type: trigger
name: Depression
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
- pattern: ^As the weapon strikes (\w+), it burns with a sickly yellow glow.$
  type: 1
]]--

if isTargeted(matches[2]) then
	Target_Instill = "depression"
	if not haveAff("depression") then
		tarAffed("depression")
    if partyrelay and tloop == false and tloop2 == false then send("pt "..target..": " ..envenomList[1].. " and depression") 
    elseif partyrelay and (tloop == true or tloop2 == true) then send("pt "..target..": timeloop and depression") end
	elseif not haveAff("nausea") then
		tarAffed("nausea")
    if partyrelay and tloop == false and tloop2 == false then send("pt "..target..": " ..envenomList[1].. " and nausea") 
    elseif partyrelay and (tloop == true or tloop2 == true) then send("pt "..target..": timeloop and nausea") end
	elseif not haveAff("hypochondria") then
		tarAffed("hypochondria")
    if partyrelay and tloop == false and tloop2 == false then send("pt "..target..": " ..envenomList[1].. " and hypochondria") elseif
	   partyrelay and (tloop == true or tloop2 == true) then send("pt "..target..": timeloop and hypochondria") end
  else
		tarAffed("depression", "anorexia", "masochism")
    if partyrelay and tloop == false and tloop2 == false then send("pt "..target..": " ..envenomList[1].. " and depression and anoreixa and masochism")
    elseif partyrelay and (tloop == true or tloop2 == true) then send("pt "..target..": timeloop and depression and anorexia and masochism") end
     end
    
	end


 
      