--[[mudlet
type: trigger
name: First
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Mage
- RESONANCE
- Earth
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
- pattern: ^A loud crack emanates from the (.+) of (\w+)\.$
  type: 1
]]--

if target == matches[2] then
	if matches[2] == "left arm" then
  tarAffed("brokenleftarm")
  elseif matches[2] == "right arm" then
  tarAffed("brokenrightarm")
  elseif matches[2] == "left leg" then
  tarAffed("brokenleftleg")
  elseif matches[2] == "right leg" then
  tarAffed("brokenrightleg")
  end
  
end
   
   