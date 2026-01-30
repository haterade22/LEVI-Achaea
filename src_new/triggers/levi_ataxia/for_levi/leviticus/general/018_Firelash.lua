--[[mudlet
type: trigger
name: Firelash
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
- pattern: ^You form a lash of fire, and send it to scorch the flesh of (\w+)\.$
  type: 1
]]--

if target == matches[2] then
selectCurrentLine() fg("red")
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
	    tburns= 5
    end
cecho(" <DimGrey>[<red>"..tburns.."/5<DimGrey>]")
end

tfirelash = true