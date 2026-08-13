--[[mudlet
type: trigger
name: Distortion Refused
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Mnemosyne
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
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
packageName: ''
patterns:
- pattern: ^You have already distorted time in this location\.$
  type: 1
]]--

-- THE GAME'S REFUSAL OUTRANKS OUR ROOM KEY (captured live 2026-08-12 -- it arrived TWICE, which
-- is exactly what a room-keyed guard looks like when the key is a lie, and in the tower dementia
-- mints a new room id on every look). Same rule as the legend deck, where the game's "lacks the
-- power to invoke" rejection is ground truth over ldm's own charge count.
--
-- Marks the location AND arms a short global hold, because when the room key is wrong this line
-- is the only evidence available. Note it also fires for ANOTHER Aeonics practitioner's
-- distortion -- which is still a correct reason not to spend 300 age here.
if ataxiaBasher_dwDistortMark then ataxiaBasher_dwDistortMark(true) end
