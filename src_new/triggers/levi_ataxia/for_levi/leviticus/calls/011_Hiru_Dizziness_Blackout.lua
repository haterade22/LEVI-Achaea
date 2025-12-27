--[[mudlet
type: trigger
name: Hiru Dizziness Blackout
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
- pattern: ^The staff connects to the side of (\w+)'s head with a resounding crack\.$
  type: 1
]]--

selectCurrentLine() fg("a_yellow") bg("black") 
replace("" ..matches[2].. " [Hiru: Dizziness | Blackout]")
 
if not tAffs.prone then
  		send("pt " ..matches[2].. ": dizziness")
			tarAffed("dizziness")
			
elseif tAffs.prone then
				send("pt " ..matches[2].. ": dizziness blackout")
			tarAffed("dizziness")

end
