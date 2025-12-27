--[[mudlet
type: trigger
name: Bubonis
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes K-S
- Occultist
- Domination Stuff
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
- pattern: ^A bubonis reaches out and strokes the side of (\w+)'s face, and boils form and rupture in an instant as \w+ begins
    hacking up black fluid.$
  type: 1
]]--

if not isTargeted(matches[2]) then return end

if not haveAff("asthma") then
  tarAffed("asthma")
else
  tarAffed("slickness")
end

predictBal("class", 1.8)	