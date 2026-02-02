--[[mudlet
type: trigger
name: Staffstrike Untargeted
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes K-S
- Magi
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
- pattern: ^You call upon (\w+) and unleash a forceful blow towards (\w+) with your trusty staff.$
  type: 1
- pattern: '1'
  type: 5
- pattern: (.*)
  type: 1
]]--

local element = multimatches[1][2]
local person = multimatches[1][3]
local maybemiss = multimatches[3][1]
local water = {"nocaloric", "shivering", "frozen"}
local aff = false

if isTargeted(person) then
  targetIshere = true
	if maybemiss == person .. " dodges nimbly out of the way." 
		or maybemiss == person .. " quickly jumps back, avoiding the attack." 
		or maybemiss == "A reflection of " .. target .. " blinks out of existence." 
	then
		--Do nothing, because it didn't hit.
	elseif maybemiss == "The attack rebounds onto you!" then
		tAffs.rebounding = true
		if applyAffV3 then applyAffV3("rebounding") end
		selectString(line, 1)
		fg("yellow")
		resetFormat()
	else
		if element == "Sllshya" then
      for _, step in pairs(water) do
        if not haveAff(step) then
          aff = step
          break
        end
      end
      if not aff then aff = "frozen" end 
    elseif element == "Kkractle" then
      aff = "ablaze"    
    end
    
    if aff then
      moveCursor(0, getLineNumber()-1)
			tarAffed(aff)
			if applyAffV3 then applyAffV3(aff) end
			moveCursorEnd() 
    end
		tAffs.rebounding = false
		if removeAffV3 then removeAffV3("rebounding") end
		tAffs.shield = false
		if removeAffV3 then removeAffV3("shield") end
	end
  tempTimer(0.7, [[ if tempGarash then tempGarash = nil end ]])  
end