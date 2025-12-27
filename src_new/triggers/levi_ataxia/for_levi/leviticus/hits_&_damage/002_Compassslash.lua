--[[mudlet
type: trigger
name: Compassslash
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- BM
- Hits & Damage
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
conditonLineDelta: 1
mStayOpen: 0
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ^As you carve into \w+, you perceive that you have dealt ([\d.]+)% damage to \w+ right arm.
  type: 1
- pattern: '1'
  type: 5
- pattern: ^You flourish your blade as it slices through \w+ skin, sending blood arcing through the air\.$
  type: 1
]]--

if gmcp.Char.Status.class == "Blademaster" then
ataxiaTables.limbData.bmBaseCompass = tonumber(multimatches[1][2])
ataxiaTables.limbData.bmCompass = tonumber(multimatches[1][2])



bmcslash = tonumber(multimatches[1][2])
end