--[[mudlet
type: trigger
name: Mizik Destroying Mushrooms
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Highlighting
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
- pattern: ^Mizik gently affixes a mushroom sigil to a monolith sigil, and upon contact, both are destroyed in a magical explosion
    that leaves Mizik bleeding and hurt\.$
  type: 1
- pattern: ^Dunn gently affixes a mushroom sigil to a monolith sigil, and upon contact, both are destroyed in a magical explosion
    that leaves Dunn bleeding and hurt\.$
  type: 1
- pattern: ^Grandue gently affixes a mushroom sigil to a monolith sigil, and upon contact, both are destroyed in a magical
    explosion that leaves Grandue bleeding and hurt\.$
  type: 1
- pattern: ^Archaeon gently affixes a mushroom sigil to a monolith sigil, and upon contact, both are destroyed in a magical
    explosion that leaves Archaeon bleeding and hurt\.$
  type: 1
]]--

send("pt Ashtan destroyed monolith. Dropping Monolith;get 50 monolith from pack;drop monolith")