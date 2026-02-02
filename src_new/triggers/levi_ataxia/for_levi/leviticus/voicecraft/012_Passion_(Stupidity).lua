--[[mudlet
type: trigger
name: Passion (Stupidity)
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
- pattern: ^With a gravity born of respect\, you sing of the saintly Imithia of legend, bringing a certain dull look to (\w+)\'s
    face\.$
  type: 1
]]--

if matches[2] == target then
	tarAffed("Stupidity")
	if applyAffV3 then applyAffV3("Stupidity") end
  
   end

   send("pt " ..target.. ": stupidity")
