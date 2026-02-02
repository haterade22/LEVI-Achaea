--[[mudlet
type: trigger
name: Limerick (Impatience)
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
- pattern: ^Composing a few clever lines in your head\, you quickly sing a jaunty limerick at (\w+)\.$
  type: 1
- pattern: ^The songbird upon your shoulder quickly sings a jaunty limerick at (\w+)\.$
  type: 1
]]--

if matches[2] == target then
--   if affstrack.score.impatience < 100 then 
  tarAffed("Impatience") 
  if applyAffV3 then applyAffV3("Impatience") end

   end

   send("pt " ..target.. ": impatience")

--end