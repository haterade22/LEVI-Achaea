--[[mudlet
type: trigger
name: LDeck No Charges
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Basher
- Bashing
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
- pattern: ^A card depicting (.+) currently lacks the power to invoke its stored potential\.$
  type: 1
]]--

--[[
    The game's ground truth on charges -- and the ONLY reliable one.

    `ldm.initDeck()` seeds every card it has never seen at its MAX charge count, so a
    deck that has not been LDECK LISTed reports full charges for everything. Live
    2026-07-30: the Mnemosyne auto-draw layer read "Xylthus: 3" and drew into a wall
    twice, while Etch spent 25 rage on the stun it assumed had landed.

    So: zero the count here (the charge gate then holds until a real LDECK LIST or a
    recharge line updates it), and tell the auto-draw layer the draw FAILED so it drops
    its in-flight replay instead of re-sending, and stamps no affliction.
]]--

if not ldm or not ldm.matchFullName then return end

local cardKey = ldm.matchFullName(matches[2])
if not cardKey then return end

if ldm.deck[cardKey] then
    ldm.deck[cardKey].charges = 0
end

if ataxiaBasher_mnemLdeckRejected then
    ataxiaBasher_mnemLdeckRejected(cardKey)
end
