--[[mudlet
type: trigger
name: Raze Two
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes A-J
- Bard
- Bard Rework
- Blade Dance
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
- pattern: ^Your blade's song punctuates every jab as your movements become a flurry of blows aimed at \w+.$
  type: 1
]]--

if tAffs.shield and tAffs.rebounding then
erAff("rebounding")
if removeAffV3 then removeAffV3("rebounding") end
elseif tAffs.rebounding then
erAff("rebounding")
if removeAffV3 then removeAffV3("rebounding") end
elseif tAffs.shield and not tAffs.rebounding then
erAff("shield")
if removeAffV3 then removeAffV3("shield") end
end


bardtemposequence = bardtemposequence + 1

