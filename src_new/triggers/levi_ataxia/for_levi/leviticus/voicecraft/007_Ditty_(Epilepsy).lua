--[[mudlet
type: trigger
name: Ditty (Epilepsy)
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
- pattern: ^You sing an irritating\, mind\-numbing ditty at (\w+)\.$
  type: 1
- pattern: ^The songbird upon your shoulder twitters an irritating\, mind\-numbing ditty at (\w+)\.$
  type: 1
]]--

if matches[2] == target then
	tarAffed("Epilepsy")
	if applyAffV3 then applyAffV3("Epilepsy") end
  
   end

   send("pt " ..target.. ": epilepsy")

