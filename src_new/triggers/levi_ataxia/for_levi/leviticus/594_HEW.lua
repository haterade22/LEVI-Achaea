--[[mudlet
type: trigger
name: HEW
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Affs Post Queue - Gated
- Classes K-S
- Knight
- Two-hander
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
- pattern: ^Taking hold of (.+) with a firm two-handed grip, you hew savagely at (\w+)'s (.+)\.$
  type: 1
- pattern: '1'
  type: 5
- pattern: ^.*$
  type: 1
]]--

ataxiaTemp.lastLimbHit = multimatches[1][4]
local person = multimatches[1][3]
if isTargeted(person) then
	if multimatches[3][1] == "The attack rebounds back onto you!"
		or multimatches[3][1] == person .. " dodges nimbly out of the way." 
		or multimatches[3][1] == person .. " parries the attack with a deft manoeuvre." 
		or multimatches[3][1] == person .. " steps into the attack, grabs your arm, and throws you violently to the ground." 
		or multimatches[3][1] == person .. " quickly jumps back, avoiding the attack."  
		or multimatches[3][1] == "A reflection of " .. person .. " blinks out of existence." 
		or multimatches[3][1] == person .. " moves into your attack, knocking your blow aside before viciously countering with a strike to your head." 
		or multimatches[3][1] == "You lash out at " .. person .. " with " .. multimatches[1][4] .. ", but miss."
		or multimatches[3][1] == person .. " twists his body out of harm's way."
		or multimatches[3][1] == person .. " twists her body out of harm's way."
    or multimatches[3][1] == person .. " twists fae body out of harm's way."
	then
    if multimatches[3][1] == person .. " parries the attack with a deft manoeuvre." then
      ataxiaTemp.parriedLimb = ataxiaTemp.lastLimbHit
      cecho("<green> -> "..ataxiaTemp.parriedLimb)
    end   
      if multimatches[3][1] == person .. " steps into the attack, grabs your arm, and throws you violently to the ground." then
      ataxiaTemp.parriedLimb = ataxiaTemp.lastLimbHit
      cecho("<green> -> "..ataxiaTemp.parriedLimb)
    end    
  	if multimatches[3][1] == "The attack rebounds back onto you!" then
    ataxiaTemp.ignoreShield = true
			tarAffed("rebounding")
			if applyAffV3 then applyAffV3("rebounding") end
      tAffs.prone = false
      if removeAffV3 then removeAffV3("prone") end
      	else
		ataxiaTemp.ignoreShield = false
		end
    	if multimatches[3][1] == "You lash out at " .. person .. " with " .. multimatches[1][4] .. ", but miss." then
			send("curing predict clumsiness")
		end
    



	end
end