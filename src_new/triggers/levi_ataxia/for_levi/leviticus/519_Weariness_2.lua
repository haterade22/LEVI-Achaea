--[[mudlet
type: trigger
name: Weariness
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes K-S
- Psion
attributes:
  isActive: 'yes'
  isFolder: 'no'
  isTempTrigger: 'no'
  isMultiline: 'yes'
  isPerlSlashGOption: 'no'
  isColorizerTrigger: 'no'
  isFilterTrigger: 'no'
  isSoundTrigger: 'no'
  isColorTrigger: 'no'
  isColorTriggerFg: 'no'
  isColorTriggerBg: 'no'
triggerType: 0
conditonLineDelta: 1
mStayOpen: 0
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ^With a lightning-fast jab of your blade you puncture the cluster of nerves just below the (\w+) shoulder of (\w+).$
  type: 1
- pattern: '1'
  type: 5
- pattern: ^.*$
  type: 1
]]--

local person = multimatches[1][3]
if isTargeted(person) then
	if multimatches[3][1] ~= "Your blow strikes "..person.." but is robbed of much of its impact by your faulty technique." then
		moveCursor(0, getLineNumber()-1)
		tarAffed("weariness")
		psion_hitLimb(multimatches[1][2].." arm")
		
		moveCursorEnd()
		psion_bleedAdd("35")		
	end
end

send("pt " ..target.. ": weariness")
