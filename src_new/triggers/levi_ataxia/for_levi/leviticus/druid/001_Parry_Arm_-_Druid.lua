--[[mudlet
type: trigger
name: Parry Arm - Druid
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Defence
- Druid
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
- pattern: ^In a furor of gnashing teeth and toxic bile, \w+ tears at your (left|right) (\w+) with two of \w+ serpentineheads\.$
  type: 1
]]--

if matches[3] == "arm" then
    if not ataxia.parrying then
	   ataxia_createParry()
    end
  ataxia.settings.use.parry = true
  if not ataxia.parry == "randomarm" then
    ataxia.parry = "randomarm"
  end
elseif matches[3] == "leg" then
  if not ataxia.parrying then
	 ataxia_createParry()
  end
    ataxia.settings.use.parry = true
  if not ataxia.parry == "randomleg" then
    ataxia.parry = "randomleg"
  end
end