--[[mudlet
type: trigger
name: Untargeted Rend
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Affs Post Queue - Gated
- Classes A-J
- Dragon
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
- pattern: ^Lunging forward with long, flashing claws extended, you tear into (\w+) ruthlessly.$
  type: 1
]]--

if isTargeted(matches[2]) then
	tarAffed(envenomList[1])
   local affstruck = envenomList[1]

	table.remove(envenomList, 1)
  if partyrelay then send("pt "..target..": "..affstruck)
  end
end