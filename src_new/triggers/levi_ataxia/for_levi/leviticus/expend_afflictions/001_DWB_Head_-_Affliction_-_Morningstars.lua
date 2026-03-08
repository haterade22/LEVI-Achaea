--[[mudlet
type: trigger
name: DWB Head - Affliction - Morningstars
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
- pattern: Matsuhama's morningstar crunches home with stunning force.
  type: 3
]]--

if target == matches[2] then
  if wieldweapons == "morningstars" then
      if not tAffs.unblind then
        tarAffed("unblind")
        if partyrelay then send("pt "..target..": unblind") end
      end
      if tAffs.prone then
       tarAffed("unblind")
        if ataxiaTemp.fractures.skullfractures == 0 or ataxiaTemp.fractures.skullfractures == nil then
          ataxiaTemp.fractures.skullfractures = 1
          twohanded_headHit()
        else
         ataxiaTemp.fractures.skullfractures = ataxiaTemp.fractures.skullfractures + 1
        ataxiaTemp.fractures.skullfractures = math.min(7, ataxiaTemp.fractures.skullfractures + 1)
         twohanded_headHit()
        end
         if partyrelay and not ataxia.afflictions.aeon  then send("pt "..target..": prone") end
         if partyrelay and not ataxia.afflictions.aeon  then send("pt "..target..": unblind and " ..ataxiaTemp.fractures.skullfractures.. " skullfractures") end
      end
  end
end