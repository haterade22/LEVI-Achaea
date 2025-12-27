--[[mudlet
type: trigger
name: SnB slice no limb - Levi
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- INFERNAL
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
- pattern: ^You slice into (\w+) with Valafar, a crimson-tinged hellforged longsword\.$
  type: 1
]]--

if gmcp.Char.Status.class == "Infernal" then
    if saffliction ~= "none" then
  
		tarAffed(saffliction)
    if partyrelay then send("pt "..target..": "..saffliction) 
    end
		  
	  end

end
 

