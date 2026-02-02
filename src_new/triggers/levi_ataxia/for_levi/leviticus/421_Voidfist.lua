--[[mudlet
type: trigger
name: Voidfist
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes A-J
- Blademaster
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
- pattern: ^Emptying your mind of conscious thought, you welcome the void as you strike (\w+) a hollow blow.$
  type: 1
]]--

if isTargeted(matches[2]) then
		tarAffed("voidfist")
		if applyAffV3 then applyAffV3("voidfist") end
		if bmFistTimer then killTimer(bmFistTimer) end
		bmFistTimer = tempTimer(18, [[tAffs.voidfist = nil; ataxia_Echo("Voidfist has faded from "..target..".")]])
end