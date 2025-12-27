--[[mudlet
type: trigger
name: Burrowed
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes K-S
- Pariah
- Misc
attributes:
  isActive: 'yes'
  isFolder: 'no'
  isTempTrigger: 'no'
  isMultiline: 'yes'
  isPerlSlashGOption: 'no'
  isColorizerTrigger: 'no'
  isFilterTrigger: 'no'
  isSoundTrigger: 'no'
  isColorTrigger: 'no'
  isColorTriggerFg: 'no'
  isColorTriggerBg: 'no'
triggerType: 0
conditonLineDelta: 15
mStayOpen: 0
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: '^\[System\]\: Running queued \w+ command: (.+)'
  type: 1
- pattern: ^You direct your swarm to burrow into (\w+).$
  type: 1
]]--

--tAffs.burrow = true

local burrowed, tar = string.match(multimatches[1][2]:lower(), "swarm burrow ([!@#$%^&*-=_+~]?[a-z0-9]+)")

if isTargeted(multimatches[2][2]) then
  tAffs.burrow = true
  pariah.burrow = string.trim(burrowed)

  selectString(line,1)
  fg("green")
  deselect()
  resetFormat()

  cecho("   <DimGrey>>><NavajoWhite>"..string.trim(burrowed).."<DimGrey><<")
end

