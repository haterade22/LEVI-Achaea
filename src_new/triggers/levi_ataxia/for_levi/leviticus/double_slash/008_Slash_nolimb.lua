--[[mudlet
type: trigger
name: Slash nolimb
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes K-S
- Double Slash
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
- pattern: ^You slash into (\w+) with .+\.$
  type: 1
]]--

local person = matches[2]
selectString(line,1)
setBold(true)
fg("royal_blue")
deselect()
resetFormat()

ataxiaTemp.hitCount = ataxiaTemp.hitCount + 1

if ataxiaTemp.class == "Bard" then return end

if isTargeted(person) then
targetIshere = true
tAffs.shield = false
ataxiaTemp.ignoreShield = false
lastLimbAttack = "dwcSlash"

if ataxiaTemp.hitCount == 1 then
  if not affs_to_colour then populate_aff_colours() end
  if envenomList[1] == "exploit" then
    tarAffed("weariness")
    tarAffed("paranoia")
    aff1 = "weariness"
    aff3 = "paranoia"
    if partyrelay and not ataxia.afflictions.aeon then
      send("pt " ..target..": " ..aff1.. " " ..aff3)
    end
  elseif envenomList[1] == "torment" then
    tarAffed("healthleech")
    aff1 = "healthleech"
    aff3 = nil
    if partyrelay and not ataxia.afflictions.aeon then
      send("pt " ..target..": " ..aff1)
    end
  elseif envenomList[1] == "torture" then
    tarAffed("haemophilia")
    aff1 = "haemophilia"
    aff3 = nil
    if partyrelay and not ataxia.afflictions.aeon then
      send("pt " ..target..": " ..aff1)
    end
  elseif envenomList[1] == "punishment" then
    aff1 = "punishment"
    aff3 = nil
    if partyrelay and not ataxia.afflictions.aeon then
      send("pt " ..target..": " ..aff1)
    end
  else
     aff1 = venom_to_aff(envenomList[1])
     if aff1 then
       tarAffed(aff1)
       if partyrelay and not ataxia.afflictions.aeon then
        send("pt " ..target..": " ..aff1)
       end
     end
  end
table.remove(envenomList,1)
aff1 = false
elseif ataxiaTemp.hitCount == 2 then
 if envenomListTwo[1] == "exploit" then
    tarAffed("weariness")
    tarAffed("paranoia")
    aff2 = "weariness"
    aff3 = "paranoia"
    if partyrelay and not ataxia.afflictions.aeon then
      send("pt " ..target..": " ..aff2.. " " ..aff3)
    end
  elseif envenomListTwo[1] == "torment" then
    tarAffed("healthleech")
    aff2 = "healthleech"
    aff3 = nil
    if partyrelay and not ataxia.afflictions.aeon then
      send("pt " ..target..": " ..aff2)
    end

  elseif envenomListTwo[1] == "torture" then
    tarAffed("haemophilia")
    aff2 = "haemophilia"
    aff3 = nil
    if partyrelay and not ataxia.afflictions.aeon then
      send("pt " ..target..": " ..aff2)
    end
  elseif envenomListTwo[1] == "punishment" then
    aff2 = "punishment"
    aff3 = nil
    if partyrelay and not ataxia.afflictions.aeon then
      send("pt " ..target..": " ..aff2)
    end
  else
     aff2 = venom_to_aff(envenomListTwo[1])
     if aff2 then
       tarAffed(aff2)
       if partyrelay and not ataxia.afflictions.aeon then
        send("pt " ..target..": " ..aff2)
       end
     end
  end
table.remove(envenomListTwo,1)
aff2 = false
end

end

