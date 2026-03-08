--[[mudlet
type: trigger
name: Attunement
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes A-J
- Depthwalker
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
- pattern: ^You determine that (\w+) is suffering from (\w+).$
  type: 1
- pattern: ^You sense that (\w+) has been struck down with the (\w+) madness.$
  type: 1
- pattern: ^You determine that the insanity of (\w+) has struck down (\w+).$
  type: 1
]]--

if isTargeted(matches[2]) then
	tarAffed(matches[3])
  if partyrelay then send("pt "..target..": "..matches[3]) end
elseif isTargeted(matches[3]) then
	tarAffed(matches[2])
  if partyrelay then send("pt "..target..": "..matches[2]) end
end
