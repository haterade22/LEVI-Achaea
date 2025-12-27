--[[mudlet
type: trigger
name: More Clean-up
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Basher
- Bashing
- Basher Lines
- Denizen Attacks / Misc Lines
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
- pattern: ^The blood ceases flowing from the wounds of (.+).$
  type: 1
- pattern: ^You weave (.+) into being, its ethereal form firming to corporeality in your hands.$
  type: 1
- pattern: ^(.+) limbs convulse uncontrollably.$
  type: 1
- pattern: ^(.+) limbs are no longer convulsing.$
  type: 1
- pattern: ^(.+) is burned by a strike of holy lightning from the heavens.$
  type: 1
- pattern: ^(.+) is wracked with pain as the flames of dragonbreath wreathe over \w+ skin.$
  type: 1
]]--

	if ataxiaBasher.enabled and not ataxiaBasher.manual then
		deleteFull()
	end


ataxiaTemp.ignoreCrits = true