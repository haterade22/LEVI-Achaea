--[[mudlet
type: trigger
name: Latency
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
- pattern: ^(\w+) looks suddenly nauseous, a ghostly pallor suffusing \w+ features.$
  type: 1
]]--

if isTargeted(matches[2]) then
  tAffs.burrow = true
  if applyAffV3 then applyAffV3("burrow") end

  if pariah.latency then killTimer(pariah.latency) end
  pariah.latency = tempTimer(12, [[ pariah.latency = nil ]])

  if haveAff("voyria") then
    ataxia_boxEcho("TARGET PRIMED FOR DEATH", "DimGrey")
  end
end

ataxia_boxEcho("TARGET HAS LATENCY", "DimGrey")