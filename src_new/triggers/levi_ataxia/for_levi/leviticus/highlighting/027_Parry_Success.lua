--[[mudlet
type: trigger
name: Parry Success
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Highlighting
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
- pattern: ^You parry the assault to your (head|torso|left arm|right arm|left leg|right leg) with a deft man(?:oe|eo)uvre\.$
  type: 1
]]--

-- Live logs show "maneouvre" for this first-person line while the third-person PvP
-- lines use "manoeuvre" -- the pattern tolerates both spellings.
selectString(line,1)
setBold(true)
fg("spring_green")
deselect()
resetFormat()

if ataxia_parrySuccess then
	ataxia_parrySuccess(matches[2]:lower())
end
