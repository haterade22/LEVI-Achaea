--[[mudlet
type: trigger
name: Haiku (Confusion)
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
- pattern: ^You recite an obscure Kamleikan haiku to (\w+)\.$
  type: 1
- pattern: ^The songbird upon your shoulder perfectly mimics the recitation of an obscure Kamleikan haiku to (\w+)\.$
  type: 1
]]--

if matches[2] == target then
	tarAffed("Confusion")
	if applyAffV3 then applyAffV3("Confusion") end
  
   end

send("pt " ..target.. ": confusion")
