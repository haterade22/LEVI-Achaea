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
    -- Guard: get venom name safely (may be nil when using timeloop)
    local venomName = (envenomList and envenomList[1]) or "unknown"

    if not haveAff("parasite") then
        tarAffed("parasite")
        if applyAffV3 then applyAffV3("parasite") end
        if partyrelay and tloop == false and tloop2 == false then send("pt "..target..": " ..venomName.. " and parasite") end
        if partyrelay and (tloop == true or tloop2 == true) then send("pt "..target..": timeloop and parasite") end
    elseif not haveAff("healthleech") then
        tarAffed("healthleech")
        if applyAffV3 then applyAffV3("healthleech") end
        if partyrelay and tloop == false and tloop2 == false then send("pt "..target..": " ..venomName.. " and healthleech") end
        if partyrelay and (tloop == true or tloop2 == true) then send("pt "..target..": timeloop and healthleech") end
    elseif not haveAff("manaleech") then
        tarAffed("manaleech")
        if applyAffV3 then applyAffV3("manaleech") end
        if partyrelay and tloop == false and tloop2 == false then send("pt "..target..": " ..venomName.. " and manaleech") end
        if partyrelay and (tloop == true or tloop2 == true) then send("pt "..target..": timeloop and manaleech") end
    else
        tarAffed("parasite", "healthleech", "manaleech")
        if applyAffV3 then applyAffV3("parasite"); applyAffV3("healthleech"); applyAffV3("manaleech") end
    end
end