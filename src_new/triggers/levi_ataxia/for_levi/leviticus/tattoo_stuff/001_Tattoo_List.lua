--[[mudlet
type: trigger
name: Tattoo List
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Misc Triggers
- Tattoo Stuff
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
mStayOpen: 99
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: 'Looking over yourself, you see the following tattoos:'
  type: 3
]]--

tattoosOnMe = {
	["Head"] = {{}, {} },
	["Torso"] = {{}, {} },
	["Left arm"] = {{}, {} },
	["Right arm"] = {{}, {} },
	["Left leg"] = {{}, {} },
	["Right leg"] = {{}, {} },
	["Back"] = {{}, {} },	
}

crucialTattoos = {
	"Boar", "Cloak", "Mindseye", "Moon", "Moss", "Tree",
}