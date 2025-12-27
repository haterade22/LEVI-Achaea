--[[mudlet
type: trigger
name: DWB Torso - Affliction - Morningstars
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Runie
- DWB
- Dual Blunt
- Expend Afflictions
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
- pattern: ^(\w+) doubles over as the morningstar savagely crunches into \w+ ribcage\.$
  type: 1
]]--

if tAffs.mildtrauma or tAffs.serioustrauma then
  if ataxiaTemp.fractures.crackedribs == 0 or ataxiaTemp.fractures.crackedribs == nil then
    ataxiaTemp.fractures.crackedribs = 2
    twohanded_torsoHit()
  else
   
    ataxiaTemp.fractures.crackedribs = math.min(7, ataxiaTemp.fractures.crackedribs + 2)
    twohanded_torsoHit()
  end

elseif ataxiaTemp.fractures.crackedribs == 0 or ataxiaTemp.fractures.crackedribs == nil then
    ataxiaTemp.fractures.crackedribs = 1
    twohanded_torsoHit()
else
    ataxiaTemp.fractures.crackedribs = math.min(7, ataxiaTemp.fractures.crackedribs + 1)
    twohanded_torsoHit()
end
if partyrelay then send("pt "..target..": "..ataxiaTemp.fractures.crackedribs.. " crackedribs") end
