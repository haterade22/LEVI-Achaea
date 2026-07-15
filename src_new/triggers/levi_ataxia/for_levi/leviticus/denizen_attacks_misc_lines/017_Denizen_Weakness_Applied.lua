--[[mudlet
type: trigger
name: Denizen Weakness Applied
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Basher
- Bashing
- Basher Lines
- Denizen Attacks / Misc Lines
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
- pattern: ^You lightly stab (.+) in several key locations with your blade, causing \w+ to slump weakly\.$
  type: 1
]]--

-- Our Nerveslash landed -> the current denizen has Weakness (deals 66% damage, 7s). Record it,
-- and stamp Nerveslash's cooldown from the REAL fire (more accurate than the rotation's optimistic
-- estimate). Denizen + basher only.
if type(target) == "number" and ataxiaBasher and ataxiaBasher.enabled then
  if ataxiaBasher_dsSetAff then ataxiaBasher_dsSetAff(target, "weakness") end
  ataxiaTemp = ataxiaTemp or {}
  ataxiaTemp.bmNerveslashReadyAt = getEpoch() + 31
  if ataxiaBasher_dsAlert then
    ataxiaBasher_dsAlert("WEAKNESS on " .. tostring(target) .. " -- mob deals 66% damage", "green")
  end
end
