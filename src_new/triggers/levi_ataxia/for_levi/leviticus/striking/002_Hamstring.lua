--[[mudlet
type: trigger
name: Hamstring
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes A-J
- Blademaster
- Striking
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
- pattern: ^Ducking behind \w+, you strike at (\w+)'s hamstring with a rigid, practised grip.$
  type: 1
- pattern: ^Ducking behind \w+\, \w+ strikes at (\w+)'s hamstring with a rigid, practised grip.$
  type: 1
]]--

if isTargeted(matches[2]) then
		tarAffed("hamstring")
		if applyAffV3 then applyAffV3("hamstring") end
		if hamstringTimer then killTimer(hamstringTimer) end
		hamstringTimer = tempTimer(10, [[tAffs.hamstring = nil]])

		-- Update BM dispatch timestamp for hamstring tracking
		if blademaster and blademaster.onHamstringApplied then
			blademaster.onHamstringApplied()
		end

if not ataxia.afflictions.aeon and partyrelay then
  send("pt " ..target..": Hamstring")
end
end