--[[mudlet
type: trigger
name: Doublestab
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes K-S
- Serpent
attributes:
  isActive: 'yes'
  isFolder: 'no'
  isTempTrigger: 'no'
  isMultiline: 'yes'
  isPerlSlashGOption: 'no'
  isColorizerTrigger: 'no'
  isFilterTrigger: 'no'
  isSoundTrigger: 'no'
  isColorTrigger: 'no'
  isColorTriggerFg: 'no'
  isColorTriggerBg: 'no'
triggerType: 0
conditonLineDelta: 1
mStayOpen: 0
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ^You quickly prick (\w+) with your dirk.$
  type: 1
- pattern: '1'
  type: 5
- pattern: ^.*$
  type: 1
]]--

--deleteLine()
--deleteLine()
--cecho("\n<red>[<white>Levi<red>]: DOUBLESTABBED "..string.upper(multimatches[1][2]).." <white>[<orange>"..string.title(svenom1).." <white>+ <orange>"..string.title(svenom2).."<white>]")

local person = multimatches[1][2]
if isTargeted(person) then
	if multimatches[3][1] == "The attack rebounds back onto you!" then
  tAffs.rebounding = true
  table.remove(envenomList, 1)
	 table.remove(envenomListTwo, 1)
	elseif  multimatches[3][1] == "A reflection of " .. person .. " blinks out of existence." then
	 table.remove(envenomList, 1)
   table.remove(envenomListTwo, 1)
	else
    if not affs_to_colour then populate_aff_colours() end
    aff1 = envenomList[1] and venom_to_aff(envenomList[1]) or nil
    aff2 = envenomListTwo[1] and venom_to_aff(envenomListTwo[1]) or nil
    if aff1 then tarAffed(aff1) end
    if aff2 then tarAffed(aff2) end
    --table.remove(envenomList,1)
    --table.remove(envenomListTwo,1)
    if snapscenarioone == true and snapscenariotwo == false then
      if tAffs.hypnoseal == true and tAffs.asthma and tAffs.snapped == false and not tAffs.rebounding then
        tempTimer(0.6,[[send("snap " ..target)]])
      end
    elseif snapscenariotwo == true then
      if tAffs.hypnoseal == true and tAffs.asthma and tAffs.snapped == false and tAffs.clumsiness or tAffs.weariness and tAffs.darkshade and not tAffs.rebounding and tBals.plant == false  then
        tempTimer(0.6,[[send("snap " ..target)]])
      end
    end
    if partyrelay and not ataxia.afflictions.aeon then
      local ptMsg = target..":"
      if aff1 then ptMsg = ptMsg .. " " .. aff1 end
      if aff2 then ptMsg = ptMsg .. " " .. aff2 end
      send("pt " .. ptMsg)
    end
	end
end

