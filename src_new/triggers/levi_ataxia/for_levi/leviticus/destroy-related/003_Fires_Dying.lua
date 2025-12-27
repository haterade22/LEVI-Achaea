--[[mudlet
type: trigger
name: Fires Dying
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes K-S
- Magi
- Destroy-related
attributes:
  isActive: 'no'
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
- pattern: ^The fires consuming (\w+) diminish somewhat.$
  type: 1
]]--

if isTargeted(matches[2]) then
	if tAffs.burns == 0 then 
     tAffs.burns = 0
  elseif tAffs.burns == 1 then
    tAffs.burns = 0
  elseif tAffs.burns == 2 then
    tAffs.burns = 1
  elseif tAffs.burns == 3 then
    tAffs.burns = 2
  elseif tAffs.burns == 4 then
    tAffs.burns = 3
  elseif tAffs.burns == 5 then
    tAffs.burn = 4
  end
    if ataxia_isClass("Magi") then
	   cecho(" <DimGrey>[<red>"..tAffs.burns.."/5<DimGrey>]")
    end
		magi_checkDestroy()
end