--[[mudlet
type: trigger
name: Inferno
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
- pattern: The firestorm roars all about you, searing your flesh.
  type: 3
]]--

if targetIshere then
  if tAffs.burns == 0 then 
	 tAffs.burns = 1
  elseif tAffs.burns == 1 then
    tAffs.burns = 2
  elseif tAffs.burns == 2 then
    tAffs.burns = 3
  elseif tAffs.burns == 3 then
    tAffs.burns = 4
  elseif tAffs.burns == 4 then
    tAffs.burns = 5
  elseif tAffs.burns == 5 then
    tAffs.burn = 5
  end
end