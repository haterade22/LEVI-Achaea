--[[mudlet
type: trigger
name: Madness
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
- pattern: ^As the weapon strikes (\w+), \w+ face grows vacant and \w+ begins to tremble.$
  type: 1
]]--

if isTargeted(matches[2]) then
    Target_Instill = "madness"
    -- Guard: get venom name safely (may be nil when using timeloop)
    local venomName = (envenomList and envenomList[1]) or "unknown"

    if not haveAff("shadowmadness") then
        tarAffed("shadowmadness")
        if applyAffV3 then applyAffV3("shadowmadness") end
        if partyrelay and tloop == false and tloop2 == false then send("pt "..target..": " ..venomName.. " and shadowmadness") end
        if partyrelay and (tloop == true or tloop2 == true) then send("pt "..target..": timeloop and shadowmadness") end
    elseif not haveAff("vertigo") then
        tarAffed("vertigo")
        if applyAffV3 then applyAffV3("vertigo") end
        if partyrelay and tloop == false and tloop2 == false then send("pt "..target..": " ..venomName.. " and vertigo") end
        if partyrelay and (tloop == true or tloop2 == true) then send("pt "..target..": timeloop and vertigo") end
    else
        tarAffed("hallucinations")
        if applyAffV3 then applyAffV3("hallucinations") end
        if partyrelay and tloop == false and tloop2 == false then send("pt "..target..": " ..venomName.. " and hallucinations") end
        if partyrelay and (tloop == true or tloop2 == true) then send("pt "..target..": timeloop and hallucinations") end
    end
end

