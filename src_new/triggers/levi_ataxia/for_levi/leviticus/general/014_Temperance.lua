--[[mudlet
type: trigger
name: Temperance
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Mage
- General
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
- pattern: ^You direct your will against the temperance elixir which protects (\w+) and it burns away\.$
  type: 1
]]--

-- Minor fire resonance strips temperance (Elementalism.wiki:62). Only our target's (v4.7.429): the
-- line names who lost it, and a strip on another enemy in a group fight was recorded on ours.
if type(target) ~= "string" or matches[2]:lower() ~= target:lower() then return end
if magi and magi.offense and magi.offense.resoEcho then magi.offense.resoEcho("Fire", "Temperance stripped", matches[2]) end
targetlostfrost = true
tempTimer(17, [[targetlostfrost = false; erAff("notemperance")]])
tarAffed("notemperance")