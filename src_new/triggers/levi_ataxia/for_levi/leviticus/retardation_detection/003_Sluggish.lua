--[[mudlet
type: trigger
name: Sluggish
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Misc Tracking
- Warnings
- Retardation Detection
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
- pattern: You move sluggishly into action.
  type: 3
]]--

if ataxiaTemp.focusVibes or ataxiaTemp.retardVibeHit then
  ataxiaTemp.focusVibes = nil
  ataxiaTemp.retardVibeHit = nil
  retardationOn()
  
elseif not affed("aeon") and not affed("blackout") and not ataxia.retardation then
  retardationOn()
  
elseif ataxiaTemp.checkingForRetardation and not ataxia.retardation then
  retardationOn()
  ataxiaTemp.checkingForRetardation = nil
  
elseif ataxiaTemp.checkingForRetardation and ataxia.retardation then
  --ignore
end

if ataxia.retardation then retardationDownCheck() end
