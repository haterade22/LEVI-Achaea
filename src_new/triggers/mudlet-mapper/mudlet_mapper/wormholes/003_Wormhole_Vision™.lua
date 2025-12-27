--[[mudlet
type: trigger
name: Wormhole Vision™
hierarchy:
- mudlet-mapper
- Mudlet Mapper
- Wormholes
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
- pattern: You see exits
  type: 2
- pattern: You see a single exit
  type: 2
- pattern: There are no obvious exits.
  type: 3
]]--

--if not getSpecialExitsSwap or mmp.settings.lockwormholes then return end
if not getSpecialExitsSwap then return end

local exits = getSpecialExitsSwap(mmp.currentroom)
if exits and exits["worm warp"] then
  cecho(string.format("\n<DarkSlateGrey>A wormhole is here, leading to: <orange_red>%s (#%d)<DarkSlateGrey> in %s.\n", getRoomName(exits["worm warp"]), exits["worm warp"], mmp.cleanAreaName(mmp.getAreaName(exits["worm warp"]))))
end