--[[mudlet
type: trigger
name: Bashing Delete
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Basher
- Bashing
- Basher Lines
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
- pattern: You cannot perform the
  type: 2
- pattern: You must specify a list of attacks to combine.
  type: 3
- pattern: ^(.+) is not a Shikudo attack that you have studied\.$
  type: 1
- pattern: You have not summoned your breath weapon.
  type: 3
- pattern: You are already summoning forth your breath, wyrm.
  type: 3
- pattern: You feel the subtle power of Shindo flowing within you.
  type: 3
- pattern: You do not have enough Shin power stored to do that.
  type: 3
- pattern: You tap into your reserves of Shin, channeling it into your blade.
  type: 3
- pattern: Your scabbard grows hot against your hip.
  type: 3
- pattern: Your blade is already empowered with that infusion.
  type: 3
- pattern: You are breathing lightly.
  type: 3
- pattern: You are panting softly.
  type: 3
- pattern: Your gear enhances your strike with additional (.+) damage.
  type: 1
]]--

if ataxiaBasher.paused == false then deleteFull() end