--[[mudlet
type: trigger
name: Dehydrate
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Mage
- General
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
- pattern: ^The skin of (\w+) begins to dry and crack as (.+) grows pale\.$
  type: 1
]]--

if target == matches[2] then

  if tAffs.weariness and tAffs.nausea then
      if tburns == 0 or nil then 
       tburns = 1
      elseif tburns == 1 then
       tburns = 2
      elseif tburns == 2 then
       tburns = 3
      elseif tburns == 3 then
       tburns = 4
      elseif tburns == 4 then
       tburns = 5
      elseif tburns == 5 then
	     tburns = 5
      cecho(" <DimGrey>[<red>"..tburns.."/5<DimGrey>]")
      end
    
  end

  if not tAffs.weariness and not tAffs.nausea then
   tarAffed("weariness")
   tarAffed("nausea")
   if applyAffV3 then applyAffV3("weariness"); applyAffV3("nausea") end
  end

  if not tAffs.weariness and tAffs.nausea and not tAffs.shivering and tAffs.nocaloric then
    tarAffed("weariness")
    tarAffed("shivering")
    if applyAffV3 then applyAffV3("weariness"); applyAffV3("shivering") end
  elseif not tAffs.weariness and tAffs.nausea and not tAffs.nocaloric then
    tarAffed("weariness")
    tarAffed("nocaloric")
    if applyAffV3 then applyAffV3("weariness"); applyAffV3("nocaloric") end
  elseif not tAffs.weariness and tAffs.nausea and tAffs.shivering and tAffs.nocaloric and not tAffs.frozen then
    tarAffed("frozen")
    tarAffed("weariness")
    if applyAffV3 then applyAffV3("frozen"); applyAffV3("weariness") end
  end

  if not tAffs.nausea and tAffs.weariness then
    if tburns == 0 then 
      tburns = 1
    elseif tburns == 1 then
      tburns = 2
    elseif tburns == 2 then
     tburns = 3
    elseif tburns == 3 then
      tburns = 4
    elseif tburns == 4 then
      tburns = 5
    elseif tburns == 5 then
	    tburns = 5
    end
    tarAffed("frozen")
    tarAffed("nausea")
    if applyAffV3 then applyAffV3("frozen"); applyAffV3("nausea") end
    haveAff("weariness")
    cecho(" <DimGrey>[<red>"..tburns.."/5<DimGrey>]")
  end
  if partyrelay and not ataxia.afflictions.aeon then send("pt " ..target.. ": weariness and nausea") end
end



   
   
