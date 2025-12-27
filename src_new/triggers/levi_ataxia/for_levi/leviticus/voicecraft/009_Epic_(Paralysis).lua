--[[mudlet
type: trigger
name: Epic (Paralysis)
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
- pattern: ^You begin reciting an epic tale of the heroism of Nicator to (\w+)\, holding (him|her) spellbound\.$
  type: 1
- pattern: ^The songbird upon your shoulder begins to perfectly mimic the recitation of an epic tale of the heroism of Nicator
    to (\w+)\, holding (him|her) spellbound\.$
  type: 1
]]--

if matches[2] == target then
	tarAffed("Paralysis")
  
   end

   send("pt " ..target.. ": paralysis")
