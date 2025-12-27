--[[mudlet
type: trigger
name: Inkmilling done
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Harvesting
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
- pattern: With a satisfying rattle, you note that the milling is complete as the fruit of your labours drops into the opening
    at the base of the mill.
  type: 3
]]--

send("g group ink from mill",false)
if ataxiaTemp.inkMaking then
	selectString(line,1)
	fg(ataxiaTemp.inkColour)
	deselect()
	
	if ataxiaTemp.inkAmount == 0 then
		ataxia_Echo("Finished creating all of the inks.")
		ataxiaTemp.inkColour = nil
		ataxiaTemp.inkAmount = nil
		ataxiaTemp.inkMaking = nil
	else
		ataxia_Echo(ataxiaTemp.inkAmount.." inks left to make.")
		inkmilling_createInks()
	end
end
