--[[mudlet
type: trigger
name: Denizen Charm Ended
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Basher
- Bashing
- Basher Lines
- Denizen Attacks / Misc Lines
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
- pattern: ^With a snarl, (.+) forces clarity back into their mind and turns their wrath upon you once more\.$
  type: 1
]]--

-- Charm ended on the named denizen -- it turns its wrath back on us. Clear the flag
-- so the basher stops treating it as a temporary ally and (Stage 3) switches back to
-- finish it. The line names the mob, so resolve name -> id (preferring a charmed one
-- when several share a name). Denizen + basher only.
if ataxiaBasher and ataxiaBasher.enabled and ataxiaBasher_dsResolveNameToId then
  local id = ataxiaBasher_dsResolveNameToId(matches[2], nil, "charm")
  if id then
    ataxiaBasher_dsClearAff(id, "charm")
    if bashConsoleEcho then
      bashConsoleEcho("denizen", "Charm ended on " .. tostring(matches[2]) .. ".")
    end
  end
end
