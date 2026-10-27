--[[mudlet
type: trigger
name: Strike Into Reflection
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- MONK 1
- Monk
- Shikudo Triggers
- Shikudo
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
- pattern: ^The attack harmlessly passes through one of (\w+)'s reflections\.$
  type: 1
]]--

-- A strike that hit an image (2026-10-27 log, 11:28:16, our combo at Akri). Another player's attack
-- prints the same words, so the [SK] line (shikudo/012) counts it only inside our own combo, at our
-- target (v4.7.456).
if shikudoEcho and shikudoEcho.onReflection then shikudoEcho.onReflection(matches[2]) end
