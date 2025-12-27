--[[mudlet
type: trigger
name: Blackout
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
- pattern: You slash a translucent dagger across the eyes of (\w+), viciously robbing \w+ of sight.
  type: 1
- pattern: '1'
  type: 5
- pattern: ^.*$
  type: 1
]]--

local person = multimatches[1][2]
if isTargeted(person) then
	if multimatches[3][1] ~= "Your blow strikes "..person.." but is robbed of much of its impact by your faulty technique." then
		if haveAff("prone") then
			moveCursor(0, getLineNumber()-1)
			tarAffed("blackout")
			tempTimer(3.5, [[erAff("blackout")]])
		end
		psion_hitLimb("head")
		send("contemplate "..target,false)		
		moveCursorEnd()	
	end
end
if partyrelay and not ataxia.afflictions.aeon then
send("pt " ..target.. ": blackout")
end
