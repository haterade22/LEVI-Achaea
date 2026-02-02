--[[mudlet
type: trigger
name: Gouge
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Affs Post Queue - Gated
- Classes K-S
- Sentinel
- Skirmishing
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
- pattern: ^You savagely gouge (\w+) with (.+).$
  type: 1
- pattern: '1'
  type: 5
- pattern: (.*)
  type: 1
]]--

local person = multimatches[1][2]
if isTargeted(person) then
	if multimatches[3][1] == "The attack rebounds back onto you!"
		or multimatches[3][1] == person .. " dodges nimbly out of the way." 
		or multimatches[3][1] == person .. " quickly jumps back, avoiding the attack." 
		or multimatches[3][1] == "A reflection of " .. person .. " blinks out of existence." 
		or multimatches[3][1] == person .. " moves into your attack, knocking your blow aside before viciously countering with a strike to your head." 
		or multimatches[3][1] == person .. " fumbles his parry, clumsily redirecting your attack." 
		or multimatches[3][1] == person .. " fumbles her parry, clumsily redirecting your attack."
		or multimatches[3][1]:find("You lash out at ")
		or multimatches[3][1] == person .. " twists his body out of harm's way."
		or multimatches[3][1] == person .. " twists her body out of harm's way."
	then
		if multimatches[3][1] == "The attack rebounds back onto you!" then
			tAffs.rebounding = true
			if applyAffV3 then applyAffV3("rebounding") end
		end
	else
		if next(envenomList) then
			moveCursor(0, getLineNumber()-1)
			tarAffed(envenomList[1], "weariness")
			if applyAffV3 then applyAffV3(envenomList[1], "weariness") end
			table.remove(envenomList, 1)
			moveCursorEnd()
		end
	end
end