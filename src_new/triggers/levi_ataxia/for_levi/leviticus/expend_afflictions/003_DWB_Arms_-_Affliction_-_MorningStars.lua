--[[mudlet
type: trigger
name: DWB Arms - Affliction - MorningStars
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Runie
- DWB
- Dual Blunt
- Expend Afflictions
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
- pattern: ^You feel the satisfying crunch of bone as your attack connects with the (\w+) arm of (\w+)\.$
  type: 1
]]--

if target == matches[3] then
  if wieldweapons == "morningstars" then
    if matches[2] == "right" then
      if not tAffs.weariness then
        tarAffed("weariness")
        if applyAffV3 then applyAffV3("weariness") end
      if partyrelay then send("pt "..target..": weariness") end
   
      elseif tAffs.weariness then
       
        if ataxiaTemp.fractures.wristfractures == 0 or ataxiaTemp.fractures.wristfractures == nil then
        ataxiaTemp.fractures.wristfractures = 1
        tarAffed("wristfractures")
        if applyAffV3 then applyAffV3("wristfractures") end
        twohanded_armsHit()
        else
         ataxiaTemp.fractures.wristfractures =  ataxiaTemp.fractures.wristfractures + 1
         twohanded_armsHit()
        end
      if partyrelay then send("pt "..target..": weariness and " ..ataxiaTemp.fractures.wristfractures.. " wristfractures") end
      end
    elseif matches[2] == "left" then
      if not tAffs.clumsiness then
        tarAffed("clumsiness")
        if applyAffV3 then applyAffV3("clumsiness") end
      if partyrelay then send("pt "..target..": clumsiness") end
       
      elseif tAffs.clumsiness then
    
        if ataxiaTemp.fractures.wristfractures == 0 or  ataxiaTemp.fractures.wristfractures == nil then
          ataxiaTemp.fractures.wristfractures = 1
          twohanded_armsHit()
        else
          ataxiaTemp.fractures.wristfractures =  ataxiaTemp.fractures.wristfractures + 1
          twohanded_armsHit()
        end
          if partyrelay then send("pt "..target..": clumsiness and " ..ataxiaTemp.fractures.wristfractures.. " wristfractures") end
      end 
    end
  end
end
    
  

  


  
  
