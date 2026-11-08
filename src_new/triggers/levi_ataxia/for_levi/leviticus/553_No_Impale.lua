--[[mudlet
type: trigger
name: No Impale
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes Other
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
- pattern: ^With a look of agony on \w+ face, (\w+) manages to writhe \w+ free of the weapon which impaled \w+.$
  type: 1
- pattern: ^With a vicious snarl you carve a merciless swathe through the steaming guts of (\w+), who gurgles and chokes as
    you withdraw your dripping blade, glistening with gore.$
  type: 1
]]--

-- Only the target. Both patterns capture whose impale ended, and anyone's writhe used to erase
-- our target's: kb/raw/logs/ours/2026-11-03_081532_Tabethys.log:1667-1668, Tabethys writhes free
-- (1668) while the target is Grulk (1502), and the tracker logs "-tar impaled" with it (1667).
-- 407_Writhed_Impale reads the same lines with the same check.
if not (matches[2] and isTargeted(matches[2])) then return end

erAff("impaled")
timpale = false