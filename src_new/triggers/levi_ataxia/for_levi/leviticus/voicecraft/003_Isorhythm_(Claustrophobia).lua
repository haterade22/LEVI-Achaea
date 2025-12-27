--[[mudlet
type: trigger
name: Isorhythm (Claustrophobia)
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
- pattern: ^In droning song you subject (\w+) to a lengthy isorhythm\.$
  type: 1
- pattern: ^The songbird upon your shoulder launches into a droning song\, subjecting (\w+) to a lengthy isorhythm\.$
  type: 1
]]--

if matches[2] == target then
	tarAffed("Claustrophobia")
  
   end

send("pt " ..target.. ": claustrophobia")

