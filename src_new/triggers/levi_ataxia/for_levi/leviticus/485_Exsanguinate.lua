--[[mudlet
type: trigger
name: Exsanguinate
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
- pattern: ^Stepping forward, you brutally drive a translucent sword into (\w+)'s guts, ripping it free in a spray of crimson.$
  type: 1
- pattern: '1'
  type: 5
- pattern: ^.*$
  type: 1
]]--

local person = multimatches[1][2]
if isTargeted(person) then
	if multimatches[3][1] ~= "Your blow strikes "..person.." but is robbed of much of its impact by your faulty technique." then
		moveCursor(0, getLineNumber()-1)
		if haveAff("bloodfire") then
			tarAffed("nausea", "anorexia")
			if applyAffV3 then applyAffV3("nausea"); applyAffV3("anorexia") end
		else
			tarAffed("nausea")
			if applyAffV3 then applyAffV3("nausea") end
		end
		psion_hitLimb("torso")
	
		send("contemplate "..target,false)		
		moveCursorEnd()
		psion_bleedAdd("30")	
	end
end

