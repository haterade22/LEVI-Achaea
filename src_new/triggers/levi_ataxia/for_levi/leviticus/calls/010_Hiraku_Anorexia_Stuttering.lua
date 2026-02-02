--[[mudlet
type: trigger
name: Hiraku Anorexia Stuttering
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- MONK 1
- Monk
- Shikudo Triggers
- Shikudo
- Calls
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
- pattern: ^The staff smashes into the face of (\w+) with a sickening crunch\.$
  type: 1
]]--

selectCurrentLine() fg("a_yellow") bg("black") 
replace("" ..matches[2].. " [Hiraku: Anorexia | Stuttering]")

if not tAffs.prone then
send("pt " ..matches[2].. ": anorexia stuttering")
tarAffed("anorexia")
tarAffed("stuttering")
if applyAffV3 then applyAffV3("anorexia"); applyAffV3("stuttering") end
end

if tAffs.prone then
				send("pt " ..matches[2].. ": Anorexia Stuttering Stunned")
			tarAffed("anorexia")
			tarAffed("stuttering")
			if applyAffV3 then applyAffV3("anorexia"); applyAffV3("stuttering") end
      
      
end