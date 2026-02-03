--[[mudlet
type: trigger
name: Degeneration
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
- pattern: ^As the weapon strikes (\w+), the contact area begins to rot before your eyes.$
  type: 1
]]--

if isTargeted(matches[2]) then
    Target_Instill = "degeneration"
    -- Guard: get venom name safely (may be nil when using timeloop)
    local venomName = (envenomList and envenomList[1]) or "unknown"

    if not haveAff("clumsiness") then
        tarAffed("clumsiness")
        if applyAffV3 then applyAffV3("clumsiness") end
        if partyrelay and tloop == false and tloop2 == false then send("pt "..target..": " ..venomName.. " and clumsiness") end
        if partyrelay and (tloop == true or tloop2 == true) then send("pt "..target..": timeloop and clumsiness") end
    elseif tAffs.clumsiness and not tAffs.weariness then
        tarAffed("weariness")
        if applyAffV3 then applyAffV3("weariness") end
        if partyrelay and tloop == false and tloop2 == false then send("pt "..target..": " ..venomName.. " and weariness") end
        if partyrelay and (tloop == true or tloop2 == true) then send("pt "..target..": timeloop and weariness") end
    elseif tAffs.clumsiness and tAffs.weariness and not tAffs.paralysis then
        tarAffed("paralysis")
        if applyAffV3 then applyAffV3("paralysis") end
    end
end
