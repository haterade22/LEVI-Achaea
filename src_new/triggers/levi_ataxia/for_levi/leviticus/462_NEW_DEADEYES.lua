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
	if applyAffV3 then applyAffV3(matches[2]) end
  cecho("working")
elseif matches[2] == "clumsy" then
tarAffed("clumsiness")
if applyAffV3 then applyAffV3("clumsiness") end
elseif matches[2] == "stupid" then
tarAffed("stupidity")
if applyAffV3 then applyAffV3("stupidity") end
elseif matches[2] == "confusion" then
tarAffed("confusion")
if applyAffV3 then applyAffV3("confusion") end
elseif matches[2] == "sensitivity" and not tAffs.deafness then
tarAffed("sensitivity")
if applyAffV3 then applyAffV3("sensitivity") end
elseif matches[2] == "sensitivity" and tAffs.deafness then
tAffs.deafness = false
if removeAffV3 then removeAffV3("deafness") end
elseif matches[2] == "dizzy" then
tarAffed("dizziness")
if applyAffV3 then applyAffV3("dizziness") end
elseif matches[2] == "plague" then
tarAffed("voyria")
if applyAffV3 then applyAffV3("voyria") end
elseif matches[2] == "sicken" and not tAffs.manaleech  then
tarAffed("manaleech")
if applyAffV3 then applyAffV3("manaleech") end
elseif matches[2] == "sicken" and tAffs.manaleech then
tarAffed("slickness")
if applyAffV3 then applyAffV3("slickness") end
elseif matches[2] == "vomiting"  then
tarAffed("nausea")
if applyAffV3 then applyAffV3("nausea") end
elseif matches[2] == "reckless"  then
tarAffed("recklessness")
if applyAffV3 then applyAffV3("recklessness") end
elseif matches[2] == "paralysis" then
tarAffed("paralysis")
if applyAffV3 then applyAffV3("paralysis") end
elseif matches[2] == "sleep" then
tarAffed("hypersomnia")
if applyAffV3 then applyAffV3("hypersomnia") end
elseif matches[2] == "bleed" then
tarAffed("haemophilia")
if applyAffV3 then applyAffV3("haemophilia") end
end
tAffs.curseward = false
if removeAffV3 then removeAffV3("curseward") end

if matches[2] == "sleep" and tAffs.hypersomnia and tarInsomnia == true then tarInsomnia = tempTimer(10, [[tarInsomnia = true; tarInsomnia = false]]) end


  if partyrelay then
    deadeye_buffer = deadeye_buffer or {}
    table.insert(deadeye_buffer, matches[2] == "sicken" and "manaleech" or matches[2])
    if deadeye_timer then killTimer(deadeye_timer) end
    deadeye_timer = tempTimer(0, function()
      if deadeye_buffer and #deadeye_buffer > 0 then
        send("pt " .. target .. ": " .. table.concat(deadeye_buffer, ", "))
        deadeye_buffer = {}
      end
      deadeye_timer = nil
    end)
  end

