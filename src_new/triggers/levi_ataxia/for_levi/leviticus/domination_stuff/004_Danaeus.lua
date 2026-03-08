--[[mudlet
type: trigger
name: Danaeus
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
- pattern: ^You command your chaos storm to bring down the curse of vertigo upon (\w+)\.$
  type: 1
- pattern: A chaos storm disregards your order.
  type: 3
]]--

if matches[1]:find("disregards") then
  tarAffed("vertigo")
elseif isTargeted(matches[2]) then
	tarAffed("vertigo")
  
  predictBal("class", 1.7)	
end