--[[mudlet
type: trigger
name: Whirl Damage
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Runie
- DWB
- Dual Blunt
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
- pattern: ^As your blow lands with a crunch, you perceive that you have dealt ([\d.]+)% damage to (\w+)'s (left leg|right
    leg|left arm|right arm|head|torso)\.$
  type: 1
]]--

DWBWhirlDamage = tonumber(matches[2])
ataxiaTables.limbData.dwbWhirl = tonumber(matches[2])

if wieldweapons == "morningstars" then
MDWBWhirlDamage = tonumber(matches[2])
end

if wieldweapons == "flails" then
FDWBWhirlDamage = tonumber(matches[2])
end