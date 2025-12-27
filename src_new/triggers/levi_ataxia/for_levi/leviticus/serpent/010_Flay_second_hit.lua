--[[mudlet
type: trigger
name: Flay second hit
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes K-S
- Serpent
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
- pattern: ^With your victim exposed, you crack .+ back for a second assault.$
  type: 1
]]--


if tAffs.rebounding == false then
send("pt " ..target..": Rebounding Down")
end
if tAffs.shield == false then
send("pt " ..target..": Shield Down")
end


local aff2 = venom_to_aff(envenomListTwo[1])
tarAffed(aff2)
table.remove(envenomListTwo,1)

if partyrelay and not ataxia.afflictions.aeon then
      send("pt "..target..": "..aff2)
    end