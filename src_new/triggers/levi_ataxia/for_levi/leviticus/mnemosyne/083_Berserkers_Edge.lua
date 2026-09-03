--[[mudlet
type: trigger
name: Mnemosyne Berserkers Edge
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
- pattern: ^Berserker's Edge\s+\d+\s+\w+
  type: 1
]]--

-- A row in the BOONS list confirms Berserker's Edge: "Your attacks deal 1% extra damage for each
-- point of battlerage you possess, up to a maximum of 100 rage." Latching it pins
-- `ataxiaBasher.rageFloor` at 100 (`ataxiaBasher_berserkersEdgeApply`, basher/001) -- every
-- rotation already gates through `ataxiaBasher_rageAfford`, so the hold lands on every class at
-- once with no per-class change. Cleared, and the floor reverted, on run start/end like every
-- other boon flag. Type BOONS to re-sync.
mnemBerserkersEdge = true
if ataxiaBasher_berserkersEdgeApply then ataxiaBasher_berserkersEdgeApply() end
