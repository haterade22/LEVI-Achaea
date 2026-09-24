--[[mudlet
type: trigger
name: Belch Fouled
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
- pattern: ^You take in a deep breath in preparation for your belch, but cough and sputter as you inhale the noxious air that surrounds you\.$
  type: 1
]]--

-- The refusal (live 2026-09-24): the room is still full of the gas we just laid, so another belch
-- is refused. Remembered PER ROOM and cleared by moving -- the next room's air is clean, and a
-- flat cooldown would either waste the equilibrium there or keep retrying here.
if ataxiaBasher_belchFouled then ataxiaBasher_belchFouled() end
