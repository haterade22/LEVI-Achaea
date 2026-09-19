--[[mudlet
type: trigger
name: Boon Callouts
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
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ^Combo Boon\?:\s+(\w+)
  type: 1
- pattern: ^Can echo:\s+(\w+)
  type: 1
- pattern: ^Maximum echoes:\s+(\d+)
  type: 1
- pattern: ^Rarity:\s+
  type: 1
- pattern: ^-{3,}
  type: 1
]]--

-- BOON CONTEMPLATE's combo and echo lines (v4.7.326, user: "should called out if the boon can combo
-- and echo"):
--   Combo Boon?:        Yes
--   Can echo:           No
--   Maximum echoes:     3
-- Classified by M.onCalloutLine, which highlights a "Yes" (and the echo count) in place and adds it
-- to the block's one summary line. The `Rarity:` line (a block opening) and a dashed divider (a
-- block closing) are the boundaries that print that line under the right boon; with nothing
-- gathered they do nothing. Ungated: a contemplate typed by hand deserves it too.
local M = ataxia and ataxia.mnemosyne
if M and M.onCalloutLine then M.onCalloutLine(line) end
