--[[mudlet
type: trigger
name: Tarnel rebind
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Spiritlore System
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
- pattern: Even as your bond with Tarnel fades, a sudden surge of primal emotion floods your mind, and it snaps back into
    place.
  type: 0
]]--

if shaman.bindcount() < 5 then
	shaman.boundspirit("Tarnel")
end