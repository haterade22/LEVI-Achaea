--[[mudlet
type: trigger
name: Identify Uses
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- LegendDeck Cards
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
- pattern: ^A card depicting (.+) may be used (\d+) more times before its potential will need to be restored\.$
  type: 1
]]--

--[[
    Generic handler: match full card name -> ldm.deck key, store charge count.
    Fixes bugs in original:
      - Stores matches[3] (charge number), not matches[2] (name string)
      - Uses ldm.matchFullName() for generic lookup instead of hardcoded elseif chain
      - Handles all cards including Covenant/Bakios correctly
]]--

if not ldm or not ldm.matchFullName then return end

local fullName = matches[2]
local charges  = tonumber(matches[3]) or 0
local cardKey  = ldm.matchFullName(fullName)

if cardKey and ldm.deck[cardKey] then
    ldm.deck[cardKey].charges = charges
end
