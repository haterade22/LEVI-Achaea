--[[mudlet
type: trigger
name: dealt limb damage
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- limb.1.2
- Limb
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
- pattern: ^As your blow lands with a crunch, you perceive that you have dealt (?<amount>.+)% damage to (?<name>\w+)'s (?<limb>.+)\.$
  type: 1
- pattern: ^As you carve into (?<name>\w+), you perceive that you have dealt (?<amount>.+)% damage to (\w+) (?<limb>.+)\.$
  type: 1
]]--

lb.addHit(matches.name, matches.limb, tonumber(matches.amount))
if partyrelay and not ataxia.afflictions.aeon then
send("pt Hit " ..matches.name.." "..matches.limb.. " for "..matches.amount.."%")
end

if gmcp.Char.Status.class == "Runewarden" and gmcp.Char.Vitals.charstats[3] == "Spec: Dual Cutting" then
ataxiaTables.limbData.dwcSlash = tonumber(matches.amount)
end

if gmcp.Char.Status.class == "Runewarden" and gmcp.Char.Vitals.charstats[3] == "Spec: Sword and Shield" then
ataxiaTables.limbData.snbSlice = tonumber(matches.amount)
end

if gmcp.Char.Status.class == "Infernal" and gmcp.Char.Vitals.charstats[4] == "Spec: Dual Cutting" then
ataxiaTables.limbData.dwcSlash = tonumber(matches.amount)
end


if gmcp.Char.Status.class == "Infernal" and gmcp.Char.Vitals.charstats[4] == "Spec: Sword and Shield" then
ataxiaTables.limbData.snbSlice = tonumber(matches.amount)
end



if gmcp.Char.Status.class == "Blue Dragon" or gmcp.Char.Status.class == "Red Dragon" or gmcp.Char.Status.class == "Green Dragon" or gmcp.Char.Status.class == "Black Dragon" or gmcp.Char.Status.class == "Golden Dragon" or gmcp.Char.Status.class == "Silver Dragon" then
ataxiaTables.limbData.dragonRend = tonumber(matches.amount)
end

if gmcp.Char.Status.class == "Priest" then
ataxiaTables.limbData.priestSmite = tonumber(matches.amount)
end
if gmcp.Char.Status.class == "Bard" then
ataxiaTables.limbData.bardRapier = tonumber(matches.amount)
end

if gmcp.Char.Status.class == "Psion" then
ataxiaTables.limbData.psionweaves = tonumber(matches.amount)
end
