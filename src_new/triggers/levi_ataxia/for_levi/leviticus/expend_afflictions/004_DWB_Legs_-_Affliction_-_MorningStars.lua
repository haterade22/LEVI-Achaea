--[[mudlet
type: trigger
name: DWB Legs - Affliction - MorningStars
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
- pattern: ^The power of your blow sweeps the legs out from under (\w+)\.$
  type: 1
]]--

if target == matches[2] then
  if wieldweapons == "morningstars" then
      if not tAffs.lethargic then
        tarAffed("lethargy")
        if applyAffV3 then applyAffV3("lethargy") end
       if partyrelay then send("pt "..target..": prone and lethargy") end
   
      end
      tarAffed("prone")
      if applyAffV3 then applyAffV3("prone") end
  end
end