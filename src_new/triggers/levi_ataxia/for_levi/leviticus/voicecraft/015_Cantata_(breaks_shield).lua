--[[mudlet
type: trigger
name: Cantata (breaks shield)
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Bard
- Bard
- voicecraft
- Voicecraft
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
- pattern: ^Your cantata shatters the defences surrounding (\w+)\.$
  type: 1
- pattern: ^Your cantata shatters the magical shield surrounding (.+)\.$
  type: 1
]]--

selectCurrentLine() fg("GreenYellow") deselect() resetFormat()

if matches[2] == target then

	tAffs.rebounding = false
	if removeAffV3 then removeAffV3("rebounding") end
  tAffs.shield = false
  if removeAffV3 then removeAffV3("shield") end
end