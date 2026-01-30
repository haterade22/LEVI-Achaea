--[[mudlet
type: trigger
name: Ruku
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- MONK 1
- Monk
- Start Shikudo
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
mStayOpen: 2
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ^You spin a full rotation, bringing a warped black iron staff coated with rust at \w+ in a controlled arc, bringing
    its length to crack against \w+ (.*).$
  type: 1
- pattern: ^You whip a warped black iron staff coated with rust at \w+ in a controlled arc, bringing its length to crack against
    \w+ (.*).$
  type: 1
- pattern: ^You spin a full rotation, bringing a warped black iron staff coated with rust around in a blur of motion to smash
    into the (.*) of (\w+).$
  type: 1
]]--

monk.shikudo.limb_hit(matches[2], "ruku")