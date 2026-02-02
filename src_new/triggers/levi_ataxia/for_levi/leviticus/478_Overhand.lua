--[[mudlet
type: trigger
name: Overhand
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
- pattern: ^You bring a translucent mace around in a savage overhand strike, smashing it into the face of (\w+).$
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
		if tLimbs.H >= 75 or lb[target].hits["head"] >= 75 then
			tarAffed("impatience", "stupidity", "prone")
			if applyAffV3 then applyAffV3("impatience"); applyAffV3("stupidity"); applyAffV3("prone") end
    elseif haveAff("prone") then
      tarAffed("impatience")
      if applyAffV3 then applyAffV3("impatience") end
		else
			tarAffed("stupidity", "prone")
			if applyAffV3 then applyAffV3("stupidity"); applyAffV3("prone") end
		end
		psion_hitLimb("head")
	
		send("contemplate "..target,false)		
		moveCursorEnd()	
		
		psion_bleedAdd("20")
		
	end
end

if tAffs.prone then
send("pt " ..target.. ": impatience")
else 
send("pt " ..target.. ": prone and stupidity")
end

