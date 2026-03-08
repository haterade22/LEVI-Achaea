--[[mudlet
type: trigger
name: Kuro Weariness Lethargy
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
- pattern: ^The staff cracks across the (left|right) thigh of (\w+)\.$
  type: 1
]]--

selectCurrentLine() fg("a_yellow") bg("black") 
replace("" ..matches[3].. " [KURO: Weariness | Lethargic]")
 
if tAffs.weariness then
        	send("pt " ..matches[3].. ": lethargy")
			tarAffed("lethargy")
elseif not tAffs.weariness then
  			send("pt " ..matches[3].. ": weariness")
			tarAffed("weariness")
end
