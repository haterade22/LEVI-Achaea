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
- pattern: ^You parry the attack with a deft man(?:oe|eo)uvre\.
  type: 1
]]--

-- Live logs show "maneouvre" for this first-person line while the third-person PvP
-- lines use "manoeuvre" -- the pattern tolerates both spellings.
selectString(line,1)
setBold(true)
fg("spring_green")
deselect()
resetFormat()

-- v4.7.416: PvP prints "You parry the attack with a deft manoeuvre." with NO limb (Mystor's logs,
-- 2026-10-11), so in PvP the parry tracker was never fed. The limb is the one we are parrying,
-- which 757 records from "You will now attempt to parry attacks to your <limb>.".
local limb = matches[2] and matches[2]:lower()
	or (ataxia and ataxia.parrying and ataxia.parrying.limb)
if ataxia_parrySuccess and limb then
	ataxia_parrySuccess(limb)
end
