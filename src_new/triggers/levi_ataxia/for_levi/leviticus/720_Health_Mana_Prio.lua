--[[mudlet
type: trigger
name: Health/Mana Prio
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Curing Stuff
- Priority Management
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
- pattern: ^Curing will now prioritise (health|mana) over (health|mana).$
  type: 1
]]--

if matches[2] == "health" then
	ataxia.settings.priohealth = true
	deleteLine()
	ataxiaEcho("Will now prioritise <firebrick>health <NavajoWhite>over <LightSkyBlue>mana <NavajoWhite>for sipping.")
else
	ataxia.settings.priohealth = false
	deleteLine()
	ataxiaEcho("Will now prioritise <LightSkyBlue>mana <NavajoWhite>over <firebrick>health <NavajoWhite>for sipping.")
end