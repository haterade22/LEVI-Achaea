--[[mudlet
type: trigger
name: Unweaved
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Psion
- Unweave
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
- pattern: ^You lash at (\w+) with a translucent lash, directing the fundamental weave of (\w+) (mind|body|spirit) to begin
    unwinding\.$
  type: 1
]]--

if tAffs.unweavingbody and not (tAffs.unweavingmind or not tAffs.unweavingspirit) then
--
elseif tAffs.unweavingmind and (not tAffs.unweavingbody or not tAffs.unweavingspirit) then
--
elseif tAffs.unweavingspirit and (not tAffs.unweavingmind or not tAffs.unweavingbody) then
--
elseif tAffs.unweavingspirit and (matches[4] == "body" or matches[4] == "mind") then
tarAffed("prone")
elseif tAffs.unweavingbody and (matches[4] == "mind" or matches[4] == "spirit") then
tarAffed("prone")
elseif tAffs.unweavingmind and (matches[4] == "body" or matches[4] == "spirit") then
tarAffed("prone")
end


if pprepare == "disruption" and matches[4] == "mind" then
if ataxia_partyCallAllowed(target) then send("pt " ..target..": Unweavemind Paralysis") end
elseif  pprepare == "laceration" and matches[4] == "mind" then
if ataxia_partyCallAllowed(target) then send("pt " ..target..": Unweavemind Haemophilia") end
elseif  pprepare == "dazzle" and matches[4] == "mind" then
if ataxia_partyCallAllowed(target) then send("pt " ..target..": Unweavemind Clumsiness") end
elseif  pprepare == "rattle" and matches[4] == "mind" then
if ataxia_partyCallAllowed(target) then send("pt " ..target..": Unweavemind Epilepsy") end
elseif  pprepare == "vapours" and matches[4] == "mind" then
if ataxia_partyCallAllowed(target) then send("pt " ..target..": Unweavemind Asthma") end
end

if  pprepare == "disruption" and matches[4] == "spirit" then
if ataxia_partyCallAllowed(target) then send("pt " ..target..": Unweavespirit Paralysis") end
elseif  pprepare == "laceration" and matches[4] == "spirit" then
if ataxia_partyCallAllowed(target) then send("pt " ..target..": Unweavespirit Haemophilia") end
elseif  pprepare == "dazzle" and matches[4] == "spirit" then
if ataxia_partyCallAllowed(target) then send("pt " ..target..": Unweavespirit Clumsiness") end
elseif  pprepare == "rattle" and matches[4] == "spirit" then
if ataxia_partyCallAllowed(target) then send("pt " ..target..": Unweavespirit Epilepsy") end
elseif  pprepare == "vapours" and matches[4] == "spirit" then
if ataxia_partyCallAllowed(target) then send("pt " ..target..": Unweavespirit Asthma") end
end

if  pprepare == "disruption" and matches[4] == "body" then
if ataxia_partyCallAllowed(target) then send("pt " ..target..": Unweavebody Paralysis") end
elseif  pprepare == "laceration" and matches[4] == "body" then
if ataxia_partyCallAllowed(target) then send("pt " ..target..": Unweavebody Haemophilia") end
elseif  pprepare == "dazzle" and matches[4] == "body" then
if ataxia_partyCallAllowed(target) then send("pt " ..target..": Unweavebody Clumsiness") end
elseif  pprepare == "rattle" and matches[4] == "body" then
if ataxia_partyCallAllowed(target) then send("pt " ..target..": Unweavebody Epilepsy") end
elseif  pprepare == "vapours" and matches[4] == "body" then
if ataxia_partyCallAllowed(target) then send("pt " ..target..": Unweavebody Asthma") end
end





