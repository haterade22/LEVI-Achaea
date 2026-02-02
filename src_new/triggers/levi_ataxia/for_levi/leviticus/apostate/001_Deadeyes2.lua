--[[mudlet
type: trigger
name: Deadeyes2
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes A-J
- Apostate
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
- pattern: ^You stare at (\w+), giving \w+ the evil eye.$
  type: 1
]]--

tarInsomnia = tarInsomnia or true
deadaff = matches[2]

if isTargeted(matches[3])


and matches[2] ~= "clumsy" and matches[2] ~= "stupid" and matches[2] ~= "sicken" and matches[2] ~= "dizzy" and matches[2] ~= "vomiting" 
and matches[2] ~= "reckless" and matches[2] ~= "plague" and matches[2] ~= "bleed" and matches[2] ~= "breach" and matches[2] ~= "sleep" and matches[2] ~= "paralysis" then
	tarAffed(matches[2])
	if applyAffV3 then applyAffV3(matches[2]) end
  
  cecho("working")
elseif matches[2] == "clumsy" then
tarAffed("clumsiness")
if applyAffV3 then applyAffV3("clumsiness") end
elseif matches[2] == "sensitivity" and not tAffs.deafness then
tarAffed("sensitivity")
if applyAffV3 then applyAffV3("sensitivity") end
elseif matches[2] == "sensitivity" and tAffs.deafness then
tAffs.deafness = false
if removeAffV3 then removeAffV3("deafness") end
elseif matches[2] == "stupid" then
tarAffed("stupidity")
if applyAffV3 then applyAffV3("stupidity") end
elseif matches[2] == "dizzy" then
tarAffed("dizziness")
if applyAffV3 then applyAffV3("dizziness") end
elseif matches[2] == "plague" then
tarAffed("voyria")
if applyAffV3 then applyAffV3("voyria") end
elseif matches[2] == "sicken"  then
tarAffed("manaleech")
if applyAffV3 then applyAffV3("manaleech") end
elseif matches[2] == "vomiting"  then
tarAffed("nausea")
if applyAffV3 then applyAffV3("nausea") end
elseif matches[2] == "reckless"  then
tarAffed("recklessness")
if applyAffV3 then applyAffV3("recklessness") end
elseif matches[2] == "confusion" then
tarAffed("confusion")
if applyAffV3 then applyAffV3("confusion") end
end
tAffs.curseward = false
if removeAffV3 then removeAffV3("curseward") end

if matches[2] == "sleep" and tAffs.hypersomnia and tarInsomnia == true then tarInsomnia = tempTimer(10, [[tarInsomnia = true; tarInsomnia = false]]) end


if partyrelay and not ataxia.afflictions.aeon and matches[2] ~= "sicken" then send("pt "..target..": "..matches[2]) elseif partyrelay and not ataxia.afflictions.aeon and matches[2] == "sicken" then send("pt "..target..": manaleech")
      end