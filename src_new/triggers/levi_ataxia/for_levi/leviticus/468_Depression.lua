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
    -- Guard: get venom name safely (may be nil when using timeloop)
    local venomName = (envenomList and envenomList[1]) or "unknown"

    if not haveAff("depression") then
        tarAffed("depression")
        if applyAffV3 then applyAffV3("depression") end
        if partyrelay and tloop == false and tloop2 == false then send("pt "..target..": " ..venomName.. " and depression")
        elseif partyrelay and (tloop == true or tloop2 == true) then send("pt "..target..": timeloop and depression") end
    elseif not haveAff("nausea") then
        tarAffed("nausea")
        if applyAffV3 then applyAffV3("nausea") end
        if partyrelay and tloop == false and tloop2 == false then send("pt "..target..": " ..venomName.. " and nausea")
        elseif partyrelay and (tloop == true or tloop2 == true) then send("pt "..target..": timeloop and nausea") end
    elseif not haveAff("hypochondria") then
        tarAffed("hypochondria")
        if applyAffV3 then applyAffV3("hypochondria") end
        if partyrelay and tloop == false and tloop2 == false then send("pt "..target..": " ..venomName.. " and hypochondria")
        elseif partyrelay and (tloop == true or tloop2 == true) then send("pt "..target..": timeloop and hypochondria") end
    else
        tarAffed("depression", "anorexia", "masochism")
        if applyAffV3 then applyAffV3("depression"); applyAffV3("anorexia"); applyAffV3("masochism") end
        if partyrelay and tloop == false and tloop2 == false then send("pt "..target..": " ..venomName.. " and depression and anorexia and masochism")
        elseif partyrelay and (tloop == true or tloop2 == true) then send("pt "..target..": timeloop and depression and anorexia and masochism") end
    end
end


 
      