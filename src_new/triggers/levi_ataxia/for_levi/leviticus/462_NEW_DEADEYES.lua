--[[mudlet
type: trigger
name: NEW DEADEYES
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes A-J
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
conditonLineDelta: 2
mStayOpen: 1
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ^Summoning up the curse of (\w+), you stare at (\w+), giving \w+ the evil eye\.$
  type: 1
]]--

tarInsomnia = tarInsomnia or true
deadaff = matches[2]



if isTargeted(matches[3])


and matches[2] ~= "clumsy" and matches[2] ~= "stupid" and matches[2] ~= "sicken" and matches[2] ~= "dizzy" and matches[2] ~= "vomiting" 
and matches[2] ~= "reckless" and matches[2] ~= "plague" and matches[2] ~= "bleed" and matches[2] ~= "breach" and matches[2] ~= "sleep" and matches[2] ~= "paralysis" then
	tarAffed(matches[2])
  
  cecho("working")
elseif matches[2] == "clumsy" then
tarAffed("clumsiness")
elseif matches[2] == "stupid" then
tarAffed("stupidity")
elseif matches[2] == "confusion" then
tarAffed("confusion")
elseif matches[2] == "sensitivity" and not tAffs.deafness then
tarAffed("sensitivity")
elseif matches[2] == "sensitivity" and tAffs.deafness then
tAffs.deafness = false
elseif matches[2] == "dizzy" then
tarAffed("dizziness")
elseif matches[2] == "plague" then
tarAffed("voyria")
elseif matches[2] == "sicken" and not tAffs.manaleech  then
tarAffed("manaleech")
elseif matches[2] == "sicken" and tAffs.manaleech then
tarAffed("slickness")
elseif matches[2] == "vomiting"  then
tarAffed("nausea")
elseif matches[2] == "reckless"  then
tarAffed("recklessness")
elseif matches[2] == "paralysis" then
tarAffed("paralysis")
elseif matches[2] == "sleep" then
tarAffed("hypersomnia")
elseif matches[2] == "bleed" then
tarAffed("haemophilia")
end
tAffs.curseward = false

if matches[2] == "sleep" and tAffs.hypersomnia and tarInsomnia == true then tarInsomnia = tempTimer(10, [[tarInsomnia = true; tarInsomnia = false]]) end


  if partyrelay then send("pt "..target..": "..matches[2])
      end

