--[[mudlet
type: trigger
name: Prompt Trigger
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
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
- pattern: ''
  type: 7
]]--

ataxia_promptCommands()

if haveDef("speed") == true then
jestercheese = false
end

if gmcp.Char.Status.class == "Blademaster" or gmcp.Char.Status.class == "Monk" then

if ataxia.defences.deafness == nil and incomingdeafness == false then
send("deaf")
end
if ataxia.afflictions.blindness == nil and incommingblindness == false then
send("blind")
end
end
if gmcp.Char.Status.class == "Magi" then
get_resonance()
cecho("Target: Burns " ..tburns)
end

mylimbattackpercentage = tonumber(ataxiaTables.limbData.dwcSlash)


lpreapply()

if ataxiaBasher.enabled then
profile = ataxia.settings.defences.current
  if ataxia.settings.defences.defup[profile].rebounding ~= nil and ataxia.settings.defences.keepup[profile].rebounding ~= nil then
    ataxia.settings.defences.defup[profile].rebounding = nil
    ataxia.settings.defences.keepup[profile].rebounding = nil
    send("curing priority defence rebounding reset", false)
  end
end

if not ataxiaBasher.enabled then
if ataxiaNDB_getClass(target) == "Apostate" or ataxiaNDB_getClass(target) == "Pariah" or ataxiaNDB_getClass(target) == "Occultist" or ataxiaNDB_getClass(target) == "Sentinel" or ataxiaNDB_getClass(target) == "Psion" or ataxiaNDB_getClass(target) == "Shaman" or ataxiaNDB_getClass(target) == "Depthswalker" or ataxiaNDB_getClass(target) == "Jester" or ataxiaNDB_getClass(target) == "Alchemist" or ataxiaNDB_getClass(target) == "Magi" or ataxiaNDB_getClass(target) == "Sylvan" then
  if myrebounding == true then
    profile = ataxia.settings.defences.current
    if ataxia.settings.defences.defup[profile].rebounding ~= nil and ataxia.settings.defences.keepup[profile].rebounding ~= nil then
    ataxia.settings.defences.defup[profile].rebounding = nil
    ataxia.settings.defences.keepup[profile].rebounding = nil
    send("curing priority defence rebounding reset", false)
    end
  end
elseif myrebounding == false then
  send("curing priority defence rebounding 25")
  addToKeepup("rebounding")
  
end

end

if lb[target] then
if lb[target].hits["torso"] >= 100 and lb[target].hits["torso"] < 200 and not tAffs.mildtrauma then
  tarAffed("mildtrauma")
end
end

ataxiaTemp.ignoreCrits = false
ignoreThirdPerson = false

if sylvan_overcharge then sylvan_overcharge = nil end
if dslAff then dslAff = nil end

if ataxiaTemp.randomCure and ataxiaTemp.randomCure > 0 then 
  if ataxiaTemp.randomCure == 1 then
    tSingleRandom()
  else
    tMultipleRandom(ataxiaTemp.randomCure)
  end
  ataxiaTemp.randomCure = nil
end 



disableTrigger("Affs Post Queue - Gated")
disableTrigger("3rd Person Shikudo")

if isActive("Alertness (Achaea+Imperian)", "trigger") then
  disableTrigger("Alertness (Achaea+Imperian)")
end
if string.find(gmcp.Room.Info.name,"Flying above") then 
ataxia_Echo("YOU ARE FLYING ")
end
