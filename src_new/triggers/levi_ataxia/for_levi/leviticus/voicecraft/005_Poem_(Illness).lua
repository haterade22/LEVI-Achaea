--[[mudlet
type: trigger
name: Poem (Illness)
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
- pattern: ^Your poem of gluttony and decay makes (\w+) green in the cheeks\.$
  type: 1
- pattern: ^The songbird upon your shoulder sings out a poem of gluttony and decay that makes (\w+) green in the cheeks\.$
  type: 1
]]--

if matches[2] == target then
	tarAffed("Illness")
	if applyAffV3 then applyAffV3("Illness") end
  
   end

send("pt " ..target.. ": illness")
